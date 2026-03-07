shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float exposicion         : hint_range(0.0, 2.0)  = 1.0;
uniform float aberracion_crom    : hint_range(0.0, 0.008) = 0.0018;
uniform float intensidad_vigneta : hint_range(0.0, 2.0)  = 0.8;
uniform float fatiga_ocular      : hint_range(0.0, 1.0)  = 0.0;

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hash13(vec3 p) {
    p  = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p.zxy, p.yxz + 19.19);
    return fract(p.x * p.y * p.z);
}

// =====================================================
// ABERRACION CROMATICA LONGITUDINAL
// =====================================================
vec3 aberracion_ocular(sampler2D tex, vec2 uv, float fuerza) {
    vec2  centro = uv - vec2(0.5);
    float dist   = length(centro);
    vec2  dir    = centro / (dist + 0.0001);

    float mag_r =  dist * dist * fuerza * 1.0;
    float mag_g =  dist * dist * fuerza * 0.3;
    float mag_b = -dist * dist * fuerza * 0.8;

    float r = texture(tex, uv + dir * mag_r).r;
    float g = texture(tex, uv + dir * mag_g).g;
    float b = texture(tex, uv + dir * mag_b).b;
    return vec3(r, g, b);
}

// =====================================================
// VIGNETA OCULAR
// =====================================================
float vigneta_ocular(vec2 uv, float intensidad) {
    vec2  centro = uv - vec2(0.5);
    centro.x    *= 0.78;
    centro.y    *= 0.92;
    float dist   = length(centro);
    float gauss  = exp(-dist * dist * 2.8 * intensidad);
    float sc     = 1.0 - smoothstep(0.35, 0.75, dist) * 0.35;
    return gauss * sc;
}

// =====================================================
// CURVA PERCEPTUAL — VERSION CORREGIDA
// Sin amplificacion — solo redistribuye tonos
// =====================================================
vec3 curva_perceptual(vec3 col) {
    // Compresion suave en altas luces (evita el blanco saturado)
    // Usando funcion que nunca supera 1.0
    vec3 c = col / (col + vec3(0.5)); // Reinhard por canal
    c      = c * 1.5;                 // reescalar para que medios tonos queden bien
    // Mezclar suavemente — no reemplazar completamente
    // Solo afecta zonas brillantes
    float l = luma(col);
    float mask_altas = smoothstep(0.5, 1.0, l);
    return mix(col, c, mask_altas * 0.55);
}

// =====================================================
// ADAPTACION DE PURKINJE (shift azul en oscuridad)
// =====================================================
vec3 adaptacion_purkinje(vec3 col, float lum_escena) {
    float oscuridad      = smoothstep(0.3, 0.0, lum_escena);
    vec3  tinte_purkinje = vec3(0.88, 0.96, 1.10);
    return mix(col, col * tinte_purkinje, oscuridad * 0.4);
}

// =====================================================
// GLARE DEL CRISTALINO
// Solo en zonas muy brillantes, muy sutil
// =====================================================
vec3 glare_cristalino(sampler2D tex, vec2 uv, vec2 px) {
    vec3  glare = vec3(0.0);
    float total = 0.0;

    for (int i = 1; i <= 3; i++) {
        float r = float(i) * 2.5;
        float w = 1.0 / float(i * i);
        glare  += texture(tex, uv + vec2(px.x * r, 0.0)).rgb * w;
        glare  += texture(tex, uv - vec2(px.x * r, 0.0)).rgb * w;
        glare  += texture(tex, uv + vec2(0.0, px.y * r)).rgb * w;
        glare  += texture(tex, uv - vec2(0.0, px.y * r)).rgb * w;
        total  += w * 4.0;
    }
    glare /= total;

    float lum_orig = luma(texture(tex, uv).rgb);
    // Umbral mas alto — solo en zonas realmente brillantes
    float mask     = smoothstep(0.85, 1.0, lum_orig);
    vec3  tinte    = vec3(0.88, 0.92, 1.08);
    return glare * tinte * mask * 0.10; // intensidad reducida
}

// =====================================================
// MICRO-SACCADE
// =====================================================
vec2 micro_saccade(float t) {
    float amp = 0.0003;
    return vec2(
        sin(t * 73.0 + 1.3) * amp,
        cos(t * 97.0 + 0.7) * amp * 0.6
    );
}

// =====================================================
// RUIDO NEURAL
// =====================================================
float ruido_neural(vec2 uv, float lum_val, float t) {
    float frame = floor(t * 60.0);
    float n1    = hash13(vec3(uv * 380.0, frame));
    float n2    = hash13(vec3(uv * 190.0 + 7.3, frame * 0.5));
    float n     = n1 * 0.65 + n2 * 0.35;
    float mask  = smoothstep(0.5, 0.0, lum_val) * 0.8
                + smoothstep(0.0, 0.15, lum_val) * 0.2;
    return (n - 0.5) * mask;
}

// =====================================================
// FATIGA OCULAR
// =====================================================
vec3 aplicar_fatiga(vec3 col, float fatiga, float lum_val) {
    if (fatiga < 0.001) return col;
    float lum_c         = luma(col);
    col                 = mix(col, vec3(lum_c) * 0.85 + vec3(0.06), fatiga * 0.35);
    vec3  tinte_fatiga  = vec3(1.04, 1.01, 0.92);
    col                *= mix(vec3(1.0), tinte_fatiga, fatiga * 0.4);
    col                 = mix(col, vec3(lum_c), fatiga * 0.20);
    return col;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 px = vec2(1.0) / vec2(textureSize(SCREEN_TEXTURE, 0));

    // Micro-saccade
    vec2 uv_sac = uv + micro_saccade(TIME);

    // Aberracion cromatica
    vec3 color = aberracion_ocular(SCREEN_TEXTURE, uv_sac, aberracion_crom);

    float lum_escena = luma(color);

    // Exposicion
    color *= exposicion;

    // Glare (muy sutil, solo altas luces)
    color += glare_cristalino(SCREEN_TEXTURE, uv, px);

    // Curva perceptual CORREGIDA (no satura blancos)
    color = curva_perceptual(color);

    // Purkinje
    color = adaptacion_purkinje(color, lum_escena);

    // Fatiga
    color = aplicar_fatiga(color, fatiga_ocular, lum_escena);

    // Vigneta
    float vig = vigneta_ocular(uv, intensidad_vigneta);
    color    *= vig;

    // Ruido neural
    float lum_final = luma(color);
    color          += ruido_neural(uv, lum_final, TIME) * 0.012;

    // Clamp final — garantiza que el blanco no se sature
    COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}