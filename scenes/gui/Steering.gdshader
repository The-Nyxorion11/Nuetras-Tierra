// volante.gdshader
shader_type canvas_item;

uniform float rotacion : hint_range(-1.0, 1.0) = 0.0;
uniform float escala : hint_range(0.1, 1.0) = 0.8; // Ajusta si se cortan las esquinas

mat2 rot(float a) {
    float s = sin(a); float c = cos(a);
    return mat2(vec2(c, -s), vec2(s, c));
}

void fragment() {
    // 1. Centrar y escalar
    vec2 uv = (UV - 0.5) / escala;
    
    // 2. Aplicar rotación visual (PI * 1.5 aprox para realismo)
    uv = uv * rot(rotacion * 4.71); 
    uv += 0.5;
    
    // 3. Dibujar textura con transparencia corregida
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0);
    } else {
        vec4 tex = texture(TEXTURE, uv);
        
        // Efecto Cristal sutil (Dorado/Ambar en bordes)
        float borde = smoothstep(0.45, 0.55, tex.a) * (1.0 - tex.a);
        vec3 glow = vec3(1.0, 0.6, 0.2) * borde * 0.8;
        
        COLOR = vec4(tex.rgb + glow, tex.a);
    }
}