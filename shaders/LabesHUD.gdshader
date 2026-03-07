shader_type canvas_item;

uniform float progreso : hint_range(0.0, 1.0) = 0.0;
uniform float tiempo_juego : hint_range(0.0, 1000.0) = 0.0;
uniform vec3 color_texto : source_color = vec3(1.0, 1.0, 1.0);

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 uv) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        v += noise(uv) * a;
        uv = uv * 2.1 + vec2(1.7, 9.2);
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float tiene_texto = step(0.01, tex.a);

    // =====================================================
    // 1. ENTRADA ESTAMPADO + SALIDA
    // =====================================================
    float entrada = smoothstep(0.0, 0.18, progreso);
    float salida  = smoothstep(1.0, 0.72, progreso);
    float alpha_base = entrada * salida * tiene_texto;

    // =====================================================
    // 2. EROSION EN BORDES (entrada/salida)
    // =====================================================
    float erosion_noise   = fbm(UV * 18.0 + vec2(tiempo_juego * 0.3, 0.0));
    float umbral_entrada  = mix(0.85, 0.25, smoothstep(0.0, 0.35, progreso));
    float umbral_salida   = mix(0.25, 0.90, smoothstep(0.72, 1.0, progreso));
    float erosion_entrada = step(umbral_entrada, erosion_noise + tex.a);
    float erosion_salida  = step(umbral_salida,  erosion_noise + tex.a);
    float erosion         = erosion_entrada * erosion_salida;

    // =====================================================
    // 3. GRANO MATE (muy sutil para no tapar el texto)
    // =====================================================
    float grano = hash(UV * 400.0 + vec2(tiempo_juego * 11.0, tiempo_juego * 6.0));
    float grano_mate = grano * 0.06; // muy bajo para no ensuciar la lectura

    // =====================================================
    // 4. SCANLINES MINIMAS
    // =====================================================
    float scanline = sin(UV.y * 160.0) * 0.025 + 0.975;

    // =====================================================
    // 5. VIBRACION EN CRITICOS
    // =====================================================
    float es_critico  = step(0.6, color_texto.r) * step(color_texto.g, 0.3);
    float vib_amp     = es_critico * 0.002 * sin(tiempo_juego * 35.0);
    vec4  tex_vibrado = texture(TEXTURE, UV + vec2(vib_amp, 0.0));
    vec4  tex_final   = mix(tex, tex_vibrado, es_critico * 0.4);

    // =====================================================
    // COMPOSICION FINAL — sin sombra desplazada
    // =====================================================
    vec3 col_mate  = color_texto * 0.90;
    col_mate      -= vec3(grano_mate);
    col_mate      *= scanline;
    col_mate       = clamp(col_mate, vec3(0.0), vec3(1.0));

    float alpha_final = tex_final.a * alpha_base * erosion;

    COLOR = vec4(col_mate, alpha_final);
}