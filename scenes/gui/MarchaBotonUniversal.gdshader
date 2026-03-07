shader_type canvas_item;

uniform bool activo = false;
uniform vec3 color_activo : source_color = vec3(0.0, 0.8, 1.0); 
uniform vec3 color_inactivo : source_color = vec3(0.3, 0.35, 0.4);
uniform float opacidad : hint_range(0.0, 1.0) = 0.9;

// Función de rectángulo redondeado corregida para asegurar bordes internos
float sdRect(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

void fragment() {
    // UV centrado (-0.5 a 0.5)
    vec2 uv = UV - 0.5;
    
    vec3 col_fondo = vec3(0.05, 0.06, 0.08);
    vec3 color_tema = activo ? color_activo : color_inactivo;
    
    // El tamaño del rect (0.48) asegura que casi toque los bordes del botón
    float d = sdRect(uv, vec2(0.48, 0.45), 0.1);
    
    // Máscara principal (el cuerpo del botón)
    // Usamos un smoothstep invertido para que el interior sea 1.0
    float mask = smoothstep(0.01, -0.01, d);
    
    // Borde: creamos una línea fina justo en el borde del rectángulo
    float borde_ancho = 0.02;
    float borde = smoothstep(borde_ancho, 0.0, abs(d));
    
    // Glow: un degradado radial suave que solo aparece si está activo
    float glow = activo ? (1.0 - length(uv * 2.0)) * 0.5 : 0.0;
    glow = clamp(glow, 0.0, 1.0);
    
    // Mezcla final de colores
    vec3 col = col_fondo;
    
    // Si es el cuerpo, ponemos el fondo oscuro con un toque del color del tema
    col = mix(col, col + (color_tema * 0.15), mask);
    
    // Sumamos el borde neón
    col += color_tema * borde;
    
    // Sumamos el resplandor central
    col += color_tema * glow * mask;
    
    // IMPORTANTE: Aseguramos que la opacidad no sea 0 si hay contenido
    // Usamos el máximo entre la máscara y el borde para que el botón no desaparezca
    float alpha_final = clamp(mask + borde, 0.0, 1.0) * opacidad;
    
    COLOR = vec4(col, alpha_final);
}