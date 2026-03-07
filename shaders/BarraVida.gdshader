shader_type canvas_item;

uniform float salud : hint_range(0.0, 1.0) = 1.0;
uniform float flash_danio : hint_range(0.0, 1.0) = 0.0;
uniform float tiempo_juego : hint_range(0.0, 1000.0) = 0.0;

const float GROSOR = 0.18;

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
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);

    float radio_ext = 0.48;
    float radio_int = radio_ext - GROSOR;

    float poca_vida = smoothstep(0.35, 0.05, salud);
    float latido    = sin(tiempo_juego * mix(5.0, 9.0, poca_vida)) * 0.5 + 0.5;
    latido          = pow(latido, 3.0);
    float pulso     = poca_vida * latido;

    float radio_ext_p = radio_ext + pulso * 0.035;
    float radio_int_p = radio_int - pulso * 0.015;

    float anillo = smoothstep(radio_ext_p + 0.012, radio_ext_p - 0.012, dist)
                 - smoothstep(radio_int_p + 0.012, radio_int_p - 0.012, dist);

    float angulo  = atan(uv.x, -uv.y);
    angulo        = (angulo + PI) / (2.0 * PI);
    float en_barra = step(angulo, salud);

    vec3 col_verde  = vec3(0.1, 0.9, 0.25);
    vec3 col_ambar  = vec3(0.95, 0.7, 0.05);
    vec3 col_rojo   = vec3(0.9, 0.08, 0.05);
    vec3 col_activa = mix(col_rojo, mix(col_ambar, col_verde, smoothstep(0.3, 0.6, salud)), smoothstep(0.0, 0.3, salud));

    float ang_noise  = fbm(vec2(angulo * 8.0 + tiempo_juego * 0.15, dist * 6.0));
    float dist_noise = fbm(vec2(dist * 10.0, angulo * 4.0 - tiempo_juego * 0.1));
    vec3  col_tex    = mix(col_activa * 0.6, col_activa * 1.3, ang_noise * 0.5 + dist_noise * 0.5);

    float flujo_pos  = fract(tiempo_juego * 0.45);
    float flujo_zona = fract(angulo - flujo_pos);
    float flujo      = smoothstep(0.0, 0.04, flujo_zona) * smoothstep(0.22, 0.04, flujo_zona);
    flujo           *= en_barra * anillo;
    float flujo2_pos  = fract(-tiempo_juego * 0.2 + 0.5);
    float flujo2_zona = fract(angulo - flujo2_pos);
    float flujo2      = smoothstep(0.0, 0.06, flujo2_zona) * smoothstep(0.3, 0.06, flujo2_zona);
    flujo2           *= en_barra * anillo * 0.4;

    float fresnel_ext = smoothstep(radio_ext_p, radio_ext_p - 0.03, dist)
                      * smoothstep(radio_ext_p - 0.06, radio_ext_p - 0.03, dist);
    float fresnel_int = smoothstep(radio_int_p, radio_int_p + 0.03, dist)
                      * smoothstep(radio_int_p + 0.06, radio_int_p + 0.03, dist);
    float fresnel = (fresnel_ext + fresnel_int) * en_barra;

    float borde_barra  = smoothstep(0.018, 0.0, abs(angulo - salud)) * anillo;
    float gota_noise_ext = fbm(vec2(angulo * 14.0 + 0.3, tiempo_juego * 0.6 + dist * 6.0));
    float gota_ext_mask  = smoothstep(radio_ext_p, radio_ext_p + 0.10, dist);
    float gota_ext_fade  = smoothstep(radio_ext_p + 0.12, radio_ext_p + 0.02, dist);
    float sangre_ext     = borde_barra * gota_noise_ext * gota_ext_mask * gota_ext_fade * (1.0 - salud * 0.6);
    float gota_noise_int = fbm(vec2(angulo * 10.0, tiempo_juego * 0.7 - dist * 5.0));
    float gota_int_mask  = smoothstep(radio_int_p, radio_int_p - 0.08, dist);
    float gota_int_fade  = smoothstep(radio_int_p - 0.10, radio_int_p - 0.01, dist);
    float sangre_int     = borde_barra * gota_noise_int * gota_int_mask * gota_int_fade * (1.0 - salud * 0.6);
    float goteo_continuo = fbm(vec2(angulo * 18.0, tiempo_juego * 1.2)) * poca_vida;
    float goteo_ext_mask = smoothstep(radio_ext_p - 0.01, radio_ext_p + 0.06, dist)
                         * smoothstep(radio_ext_p + 0.09, radio_ext_p + 0.02, dist);
    float goteo          = goteo_continuo * goteo_ext_mask * en_barra * 0.6;

    float flash_int = flash_danio * (sin(tiempo_juego * 22.0) * 0.35 + 0.65);
    vec3  col_flash = vec3(1.0, 0.0, 0.0);

    float halo = smoothstep(radio_ext_p + 0.08, radio_ext_p, dist)
               - smoothstep(radio_ext_p + 0.01, radio_ext_p - 0.01, dist);
    halo *= en_barra;
    float halo_intensity = mix(0.3, 0.7, pulso);
    float fondo = (1.0 - en_barra) * anillo;

    vec3 col_final = col_tex;
    col_final += vec3(1.0, 0.95, 0.7) * flujo * 1.1;
    col_final += vec3(1.0, 0.95, 0.7) * flujo2;
    col_final += col_activa * fresnel * 0.8;
    col_final += col_activa * pulso * 0.6;
    col_final += vec3(0.7, 0.0, 0.0) * (sangre_ext + sangre_int) * 2.5;
    col_final += vec3(0.6, 0.0, 0.0) * goteo * 2.0;
    col_final  = mix(col_final, col_flash, flash_int * 0.85);
    col_final += col_flash * flash_int * 0.4 * anillo;
    col_final += col_activa * halo * halo_intensity;

    vec3 col_fondo = vec3(0.05, 0.05, 0.07);
    float alpha_barra  = en_barra * anillo;
    float alpha_fondo  = fondo * 0.28;
    float alpha_sangre = (sangre_ext + sangre_int + goteo) * 0.9;
    float alpha_halo   = halo * halo_intensity * 0.5;
    float alpha = clamp(alpha_barra + alpha_fondo + alpha_sangre + alpha_halo, 0.0, 1.0);

    col_final = mix(col_fondo, col_final, alpha_barra + alpha_sangre + alpha_halo);
    col_final += col_flash * flash_int * 0.2 * fondo;

    COLOR = vec4(col_final, alpha);
}