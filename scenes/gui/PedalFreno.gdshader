shader_type canvas_item;

uniform bool presionado = false;
uniform float intensidad_presion : hint_range(0.0, 1.0) = 0.0;
uniform float opacidad_global : hint_range(0.0, 1.0) = 0.8;
uniform bool es_freno = true; 

// --- FUNCIONES COMPARTIDAS ---
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float sdRect(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

void fragment() {
    // 1. AJUSTE RECTANGULAR (Igual al acelerador)
    vec2 uv = UV - vec2(0.5);
    uv.x *= 0.52; 

    // 2. PALETA TECH
    vec3 col_fuego   = vec3(1.0, 0.28, 0.05); // Rojo Freno
    vec3 col_cristal = vec3(0.14, 0.17, 0.21);
    vec3 col_blanco  = vec3(1.0, 1.0, 1.0);
    vec3 col_main    = col_fuego;

    // 3. EFECTO DE HUNDIMIENTO
    float hundimiento = mix(1.0, 0.88, intensidad_presion);
    vec2 uv_p = (uv + vec2(0.0, intensidad_presion * 0.03)) / hundimiento;

    // 4. GEOMETRÍA UNIFICADA (Rectángulo Vertical)
    // d_base y d_vastago crean la estructura mecánica de fondo
    float d_base = sdRect(uv - vec2(0.0, 0.43), vec2(0.2, 0.03), 0.01);
    float d_vastago = sdRect(uv_p - vec2(0.0, 0.2), vec2(0.05, 0.3), 0.005);
    
    // d_pedal es el rectángulo principal
    float d_pedal = sdRect(uv_p, vec2(0.2, 0.42), 0.04);

    // 5. MÁSCARAS
    float m_base = smoothstep(0.01, -0.01, d_base);
    float m_pedal = smoothstep(0.01, -0.01, d_pedal);
    float m_vastago = smoothstep(0.01, -0.01, d_vastago) * (1.0 - m_pedal);
    float borde = smoothstep(0.02, 0.01, abs(d_pedal));

    // 6. DETALLES VISUALES
    float grano = hash(uv_p * 250.0) * 0.04;
    vec3 cristal_rgb = col_cristal - grano;
    
    // Rayas de agarre (Grip industrial horizontal)
    float rayas = step(0.78, fract(uv_p.y * 14.0)) * m_pedal;
    rayas *= smoothstep(0.18, 0.14, abs(uv_p.x));

    // 7. COMPOSICIÓN
    vec3 final_rgb = mix(vec3(0.0), col_cristal * 0.6, m_vastago);
    final_rgb = mix(final_rgb, col_cristal * 0.8, m_base);
    final_rgb = mix(final_rgb, cristal_rgb, m_pedal);
    
    // Iluminación reactiva (Borde y Glow)
    final_rgb += col_main * borde * (1.0 + intensidad_presion * 3.5);
    final_rgb += col_main * m_pedal * intensidad_presion * 0.2;
    
    // Líneas blancas brillantes
    final_rgb = mix(final_rgb, col_blanco, rayas * (0.2 + intensidad_presion * 0.5));
    
    // Sombra de profundidad
    float sombra = smoothstep(0.0, 0.2, d_pedal) * (1.0 - m_pedal) * intensidad_presion * 0.6;
    
    // 8. ALFA FINAL
    float alfa = (max(max(m_pedal, m_base), m_vastago) + borde) * opacidad_global;

    COLOR = vec4(final_rgb, clamp(alfa - sombra, 0.0, 1.0));
}