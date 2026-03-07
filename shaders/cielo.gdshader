shader_type sky;

// --- COLORES REALISTAS (menos saturados, mas naturales) ---
uniform vec3 color_dia_sup   : source_color = vec3(0.08, 0.18, 0.42);
uniform vec3 color_dia_hor   : source_color = vec3(0.52, 0.72, 0.88);
uniform vec3 color_tarde_sup : source_color = vec3(0.12, 0.08, 0.18);
uniform vec3 color_tarde_hor : source_color = vec3(0.85, 0.38, 0.12);
uniform vec3 color_noche_sup : source_color = vec3(0.003, 0.006, 0.015);
uniform vec3 color_noche_hor : source_color = vec3(0.012, 0.018, 0.035);

// --- AJUSTES ---
uniform float densidad_nubes    : hint_range(0.0, 3.0)  = 1.4;
uniform float velocidad_nubes   : hint_range(0.0, 0.05) = 0.004;
uniform float intensidad_sombras: hint_range(0.0, 1.0)  = 0.75;
uniform float intensidad_niebla : hint_range(0.0, 1.0)  = 0.35;
uniform float turbidez          : hint_range(0.0, 1.0)  = 0.55; // contaminacion/polvo en el aire

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// FBM optimizado para movil (4 octavas en lugar de 5)
float fbm(vec2 p) {
    float v = 0.0; float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.1;
        a *= 0.48;
    }
    return v;
}

// Dispersion de Rayleigh simplificada (da el azul realista del cielo)
vec3 rayleigh(float cos_theta, vec3 col_base) {
    // El cielo es mas azul perpendicular al sol, mas blanco cerca del sol
    float phase = 0.75 * (1.0 + cos_theta * cos_theta);
    return col_base * phase;
}

// Dispersion de Mie simplificada (halo solar realista)
float mie(float cos_theta, float g) {
    float g2 = g * g;
    return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * cos_theta, 1.5) * 0.25;
}

void sky() {
    float d       = EYEDIR.y;
    float sun_h   = LIGHT0_DIRECTION.y;
    float cos_sun = clamp(dot(EYEDIR, LIGHT0_DIRECTION), 0.0, 1.0);
    float sun_h01 = clamp(sun_h * 0.5 + 0.5, 0.0, 1.0); // 0=noche 1=mediodia

    // =====================================================
    // FACTORES DE TRANSICION (mas suaves y realistas)
    // =====================================================
    // Amanecer/atardecer: cuando el sol esta cerca del horizonte
    float tarde_factor = clamp(1.0 - abs(sun_h - 0.08) * 5.0, 0.0, 1.0);
    tarde_factor        = pow(tarde_factor, 1.4); // curva mas suave
    float noche_factor  = clamp(-sun_h * 5.0, 0.0, 1.0);
    float dia_factor    = 1.0 - noche_factor;

    // =====================================================
    // 1. GRADIENTE ATMOSFERICO REALISTA
    // Cielo real: mas oscuro arriba, mas claro en el horizonte
    // Con dispersion de Rayleigh
    // =====================================================
    // Altura normalizada (0=horizonte, 1=zenith)
    float altura = clamp(d * 2.2, 0.0, 1.0);
    // Curva exponencial — el cielo se oscurece mas rapido hacia arriba
    float grad   = pow(altura, 0.6);

    vec3 col_sup = mix(color_dia_sup, color_tarde_sup, tarde_factor);
    col_sup       = mix(col_sup, color_noche_sup, noche_factor);
    vec3 col_hor  = mix(color_dia_hor, color_tarde_hor, tarde_factor);
    col_hor        = mix(col_hor, color_noche_hor, noche_factor);

    vec3 sky_color = mix(col_hor, col_sup, grad);

    // Dispersion de Rayleigh (tinte azul mas intenso lejos del sol)
    vec3  rayleigh_col = rayleigh(cos_sun, vec3(0.06, 0.15, 0.38)) * dia_factor * (1.0 - tarde_factor);
    sky_color         += rayleigh_col * (1.0 - grad) * 0.35;

    // =====================================================
    // 2. SOL REALISTA
    // Disco solar + corona + halo de Mie
    // =====================================================
    if (d > -0.05) {
        // Disco solar (pequeno y brillante)
        float disco_sol  = smoothstep(0.9985, 0.9998, cos_sun);
        // Corona inmediata (calida)
        float corona     = smoothstep(0.990, 0.9985, cos_sun) * (1.0 - disco_sol);
        // Halo de Mie (dispersion por particulas — da el brillo lechoso)
        float halo_mie   = mie(cos_sun, mix(0.76, 0.92, turbidez)) * dia_factor;

        // Color del sol segun hora
        // Mediodia: blanco-amarillo, atardecer: naranja-rojo intenso
        vec3 col_sol_dia   = vec3(1.0, 0.97, 0.88);
        vec3 col_sol_tarde = vec3(1.0, 0.45, 0.12);
        vec3 col_sol       = mix(col_sol_dia, col_sol_tarde, tarde_factor);

        // Disco
        sky_color += col_sol * disco_sol * 8.0 * dia_factor;
        // Corona calida
        sky_color += mix(vec3(1.0, 0.85, 0.5), vec3(1.0, 0.4, 0.1), tarde_factor)
                   * corona * 2.5 * dia_factor;
        // Halo Mie (lechoso, cubre area grande)
        sky_color += mix(vec3(0.85, 0.90, 0.95), vec3(0.95, 0.55, 0.22), tarde_factor)
                   * halo_mie * mix(0.18, 0.45, turbidez) * dia_factor;

        // Brillo naranja en el horizonte al atardecer
        float glow_tarde  = pow(clamp(1.0 - abs(d) * 3.5, 0.0, 1.0), 2.5) * tarde_factor;
        float glow_dir    = pow(cos_sun, 4.0) * tarde_factor;
        sky_color        += vec3(0.9, 0.32, 0.05) * glow_tarde * glow_dir * 1.8;

        // Franja calida en el horizonte (realismo atmosferico)
        float franja_hor  = pow(clamp(1.0 - abs(d + 0.02) * 8.0, 0.0, 1.0), 2.0);
        sky_color        += mix(vec3(0.6, 0.72, 0.88), vec3(0.88, 0.48, 0.18), tarde_factor)
                          * franja_hor * 0.30 * dia_factor;
    }

    // =====================================================
    // 3. LUNA (noche)
    // =====================================================
    if (noche_factor > 0.1) {
        // La luna esta en direccion opuesta al sol
        vec3  dir_luna   = -LIGHT0_DIRECTION;
        float cos_luna   = clamp(dot(EYEDIR, dir_luna), 0.0, 1.0);
        float disco_luna = smoothstep(0.9992, 0.9999, cos_luna);
        float halo_luna  = smoothstep(0.994, 0.9992, cos_luna) * (1.0 - disco_luna);
        // Color de la luna: blanco frio ligeramente amarillento
        sky_color += vec3(0.90, 0.92, 0.88) * disco_luna * noche_factor * 4.0;
        sky_color += vec3(0.55, 0.58, 0.62) * halo_luna  * noche_factor * 0.6;
    }

    // =====================================================
    // 4. ESTRELLAS REALISTAS
    // Dos capas: estrellas brillantes + campo de fondo
    // =====================================================
    if (noche_factor > 0.2 && d > 0.0) {
        // Campo de estrellas de fondo (muchas, tenues)
        float st_campo = hash(floor(EYEDIR.xz * 800.0));
        if (st_campo > 0.985) {
            float brillo_c = (st_campo - 0.985) / 0.015;
            // Centelleo sutil
            float centelleo = sin(TIME * (1.5 + st_campo * 8.0) + st_campo * 20.0) * 0.18 + 0.82;
            // Tinte ligeramente variable (algunas azuladas, algunas rojizas)
            float tinte = hash(EYEDIR.xz * 200.0 + vec2(1.3));
            vec3  col_st = mix(vec3(0.75, 0.80, 1.00), vec3(1.00, 0.85, 0.72), tinte);
            sky_color   += col_st * brillo_c * centelleo * noche_factor * 0.20
                         * smoothstep(0.0, 0.3, d); // desaparecen cerca del horizonte
        }

        // Estrellas brillantes (pocas, mas intensas)
        float st_bright = hash(floor(EYEDIR.xz * 200.0 + vec2(7.3)));
        if (st_bright > 0.997) {
            float brillo_b  = (st_bright - 0.997) / 0.003;
            float centelleo = sin(TIME * (2.0 + st_bright * 5.0)) * 0.25 + 0.75;
            float tinte     = hash(EYEDIR.xz * 50.0 + vec2(3.7));
            vec3  col_sb    = mix(vec3(0.70, 0.78, 1.00), vec3(1.00, 0.92, 0.72), tinte);
            // Cruz de difraccion en estrellas muy brillantes
            float cruz_h = smoothstep(0.003, 0.0, abs(fract(EYEDIR.x * 200.0) - 0.5));
            float cruz_v = smoothstep(0.003, 0.0, abs(fract(EYEDIR.z * 200.0) - 0.5));
            sky_color   += col_sb * brillo_b * centelleo * noche_factor * 0.55
                         * smoothstep(0.0, 0.25, d);
            sky_color   += col_sb * (cruz_h + cruz_v) * 0.04 * noche_factor * brillo_b;
        }

        // Via Lactea muy sutil (banda de fondo)
        float banda_vl = abs(sin(EYEDIR.x * 2.5 + 0.8));
        float via_lac  = pow(clamp(banda_vl, 0.0, 1.0), 4.0);
        float ruido_vl = fbm(EYEDIR.xz * 3.5 + vec2(TIME * 0.0005));
        sky_color     += vec3(0.10, 0.12, 0.20) * via_lac * ruido_vl
                       * noche_factor * 0.12 * smoothstep(0.0, 0.4, d);
    }

    // =====================================================
    // 5. NUBES VOLUMETRICAS REALISTAS
    // =====================================================
    if (d > -0.12) {
        // UV de las nubes con perspectiva correcta
        float altura_nubes = max(d, 0.0) + 0.10;
        vec2  sky_uv       = EYEDIR.xz / altura_nubes;
        vec2  uv_nubes     = sky_uv * 0.38 + TIME * velocidad_nubes * vec2(1.0, 0.4);

        // Dos capas de FBM para mayor detalle volumetrico
        float n1 = fbm(uv_nubes);
        float n2 = fbm(uv_nubes * 2.3 + vec2(5.2, 1.7)); // detalle fino
        float n  = n1 * 0.65 + n2 * 0.35;

        float cloud_mask = smoothstep(0.38, 0.80, n * densidad_nubes);
        float cloud_detail = smoothstep(0.42, 0.85, n2 * densidad_nubes); // detalle fino

        // --- COLOR DE LAS NUBES REALISTA ---
        // Parte iluminada: blanca con tinte solar
        vec3 col_nube_lit  = mix(vec3(0.96, 0.97, 1.00), vec3(1.00, 0.92, 0.80), tarde_factor);
        col_nube_lit        = mix(col_nube_lit, vec3(0.55, 0.52, 0.60), noche_factor);

        // Parte en sombra: gris azulado (no negro — las nubes transmiten luz)
        vec3 col_nube_sombra = mix(vec3(0.55, 0.60, 0.70), vec3(0.38, 0.22, 0.18), tarde_factor);
        col_nube_sombra       = mix(col_nube_sombra, vec3(0.08, 0.09, 0.14), noche_factor);

        // Oclusion: partes densas mas oscuras (volumetria simulada)
        float oclusion    = mix(1.0, n, intensidad_sombras * 0.9);
        float oclusion2   = mix(1.0, n2, intensidad_sombras * 0.5);
        vec3  col_nube    = mix(col_nube_sombra, col_nube_lit, oclusion * oclusion2);

        // Borde iluminado por el sol (scattering en los bordes de la nube)
        float borde_sol   = pow(cos_sun, 8.0) * dia_factor;
        float borde_lit   = (1.0 - cloud_detail) * cloud_mask * borde_sol;
        col_nube         += mix(vec3(1.0, 0.95, 0.80), vec3(1.0, 0.50, 0.15), tarde_factor)
                          * borde_lit * 0.55;

        // Tinte rosado/naranja en los bordes al atardecer (fenomeno real)
        float tinte_tarde = cloud_mask * tarde_factor * pow(cos_sun, 3.0);
        col_nube         += vec3(0.80, 0.28, 0.06) * tinte_tarde * 0.40;

        // Desvanecimiento en el horizonte (niebla atmosferica)
        float fade_hor  = smoothstep(-0.12, 0.25, d);
        // Niebla entre el observador y las nubes (dispersion atmosferica)
        vec3  col_niebla = mix(col_hor, vec3(0.75, 0.80, 0.88), tarde_factor * 0.5);
        col_nube          = mix(col_niebla, col_nube, fade_hor * 0.88);

        sky_color = mix(sky_color, col_nube, cloud_mask * fade_hor);

        // Niebla nocturna (sutil, solo en el horizonte)
        float neb_noc = intensidad_niebla * noche_factor;
        float neb_fres = pow(1.0 - clamp(d + 0.08, 0.0, 1.0), 3.5);
        float neb_osc  = (sin(TIME * 0.08) * 0.5 + 0.5) * neb_noc;
        sky_color = mix(sky_color, color_noche_hor * 1.8, neb_fres * neb_osc * 0.55);
    }

    // =====================================================
    // 6. NEBLINA ATMOSFERICA EN EL HORIZONTE
    // Fenomeno real: el aire dispersa la luz en el horizonte
    // =====================================================
    float niebla_hor = pow(clamp(1.0 - abs(d) * 4.5, 0.0, 1.0), 3.0);
    vec3  col_niebla_atm = mix(
        mix(vec3(0.70, 0.80, 0.90), vec3(0.78, 0.58, 0.42), tarde_factor),
        vec3(0.04, 0.05, 0.09),
        noche_factor
    );
    sky_color = mix(sky_color, col_niebla_atm, niebla_hor * turbidez * 0.45 * dia_factor);

    // =====================================================
    // 7. TONEMAPPING PARA MOVIL
    // Evita sobreexposicion y da look cinematico natural
    // =====================================================
    // Exposicion segun hora (dia brillante, noche oscura)
    float exposicion = mix(0.85, 0.40, noche_factor);
    exposicion        = mix(exposicion, 0.70, tarde_factor * 0.5);
    sky_color        *= exposicion;

    // Tonemapping Reinhard (barato para movil)
    sky_color = sky_color / (sky_color + vec3(1.0));

    // Correccion gamma (sRGB)
    sky_color = pow(max(sky_color, vec3(0.0)), vec3(0.4545));

    // Saturacion ligeramente reducida para look mas fotografico
    float lum    = dot(sky_color, vec3(0.299, 0.587, 0.114));
    sky_color    = mix(vec3(lum), sky_color, 0.88);

    COLOR = sky_color;
}