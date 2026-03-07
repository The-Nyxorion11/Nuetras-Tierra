shader_type canvas_item;

uniform float hambre : hint_range(0.0, 1.0) = 1.0;
uniform float tiempo_juego : hint_range(0.0, 1000.0) = 0.0;

const float GROSOR = 0.18;

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float hash1(float n) {
    return fract(sin(n) * 43758.5453);
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

    float poca_hambre = smoothstep(0.35, 0.05, hambre);
    float temblor_amp = poca_hambre * 0.012;
    vec2  uv_tem      = uv + vec2(
        sin(tiempo_juego * 18.0) * temblor_amp,
        cos(tiempo_juego * 23.0) * temblor_amp * 0.6
    );
    float dist_tem = length(uv_tem);

    float latido = sin(tiempo_juego * mix(4.0, 11.0, poca_hambre)) * 0.5 + 0.5;
    latido       = pow(latido, 4.0);
    float pulso  = poca_hambre * latido;

    float radio_ext_p = radio_ext + pulso * 0.03;
    float radio_int_p = radio_int - pulso * 0.012;

    float anillo = smoothstep(radio_ext_p + 0.012, radio_ext_p - 0.012, dist_tem)
                 - smoothstep(radio_int_p + 0.012, radio_int_p - 0.012, dist_tem);

    float angulo  = atan(uv.x, -uv.y);
    angulo        = (angulo + PI) / (2.0 * PI);
    float en_barra = step(angulo, hambre);

    vec3 col_lleno  = vec3(0.95, 0.65, 0.05);
    vec3 col_medio  = vec3(0.85, 0.38, 0.02);
    vec3 col_vacio  = vec3(0.45, 0.15, 0.02);
    vec3 col_activa = mix(col_vacio, mix(col_medio, col_lleno, smoothstep(0.3, 0.7, hambre)), smoothstep(0.0, 0.3, hambre));

    float ang_noise  = fbm(vec2(angulo * 7.0 + tiempo_juego * 0.12, dist * 5.0));
    float dist_noise = fbm(vec2(dist * 9.0, angulo * 3.5 - tiempo_juego * 0.08));
    vec3  col_tex    = mix(col_activa * 0.55, col_activa * 1.35, ang_noise * 0.5 + dist_noise * 0.5);

    float flujo_pos  = fract(tiempo_juego * 0.35);
    float flujo_zona = fract(angulo - flujo_pos);
    float flujo      = smoothstep(0.0, 0.05, flujo_zona) * smoothstep(0.20, 0.05, flujo_zona);
    flujo           *= en_barra * anillo;

    float fresnel_ext = smoothstep(radio_ext_p, radio_ext_p - 0.03, dist_tem)
                      * smoothstep(radio_ext_p - 0.06, radio_ext_p - 0.03, dist_tem);
    float fresnel_int = smoothstep(radio_int_p, radio_int_p + 0.03, dist_tem)
                      * smoothstep(radio_int_p + 0.06, radio_int_p + 0.03, dist_tem);
    float fresnel     = (fresnel_ext + fresnel_int) * en_barra;

    float burbujas = 0.0;
    for (int b = 0; b < 8; b++) {
        float seed     = float(b) * 1.618;
        float ang_bub  = hash1(seed) * hambre;
        float vel_bub  = 0.3 + hash1(seed + 1.0) * 0.3;
        float fase_bub = fract(hash1(seed + 2.0) + tiempo_juego * vel_bub);
        float r_bub    = mix(radio_int_p + 0.02, radio_ext_p - 0.02, fase_bub);
        float tam_bub  = mix(0.018, 0.008, fase_bub);
        float ang_rad  = ang_bub * 2.0 * PI - PI;
        vec2  pos_bub  = vec2(sin(ang_rad), -cos(ang_rad)) * r_bub;
        float d_bub    = distance(uv, pos_bub);
        float mask_bub = smoothstep(tam_bub, 0.0, d_bub);
        float bright   = smoothstep(tam_bub, tam_bub * 0.3, d_bub);
        burbujas += (mask_bub + bright * 0.4) * poca_hambre;
    }
    burbujas = clamp(burbujas, 0.0, 1.0);

    float halo = smoothstep(radio_ext_p + 0.08, radio_ext_p, dist_tem)
               - smoothstep(radio_ext_p + 0.01, radio_ext_p - 0.01, dist_tem);
    halo *= en_barra;
    float halo_intensity = mix(0.25, 0.65, pulso);
    float halo_hambre    = smoothstep(radio_ext_p + 0.12, radio_ext_p, dist_tem) * poca_hambre * latido * 0.4;
    float fondo = (1.0 - en_barra) * anillo;

    vec3 col_final = col_tex;
    col_final += vec3(1.0, 0.9, 0.5) * flujo * 0.9;
    col_final += col_activa * fresnel * 0.7;
    vec3 col_burbuja = mix(col_activa * 1.5, vec3(1.0, 0.85, 0.4), 0.5);
    col_final  = mix(col_final, col_burbuja, burbujas * anillo * en_barra);
    col_final += col_activa * pulso * 0.55;
    col_final  = mix(col_final, col_final + vec3(0.5, 0.0, 0.0) * latido, poca_hambre * 0.35);
    col_final += col_activa * halo * halo_intensity;
    col_final += vec3(0.8, 0.1, 0.0) * halo_hambre;

    vec3 col_fondo = vec3(0.06, 0.04, 0.02);
    float alpha_barra = en_barra * anillo;
    float alpha_fondo = fondo * 0.28;
    float alpha_burb  = burbujas * anillo * en_barra * 0.9;
    float alpha_halo  = (halo * halo_intensity + halo_hambre) * 0.5;
    float alpha = clamp(alpha_barra + alpha_fondo + alpha_burb + alpha_halo, 0.0, 1.0);

    col_final = mix(col_fondo, col_final, alpha_barra + alpha_burb + alpha_halo);

    COLOR = vec4(col_final, alpha);
}