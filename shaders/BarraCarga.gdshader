shader_type canvas_item;

uniform float progreso : hint_range(0, 1) = 0.0;
uniform vec4 color_fondo : source_color = vec4(0.08, 0.12, 0.18, 1.0);
uniform vec4 color_barra : source_color = vec4(0.2, 0.7, 0.3, 1.0);
uniform vec4 color_borde : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float borde_grosor : hint_range(0, 0.1) = 0.02;
uniform float animacion = 0.0;

void fragment() {
    vec2 uv = UV;
    float borde = borde_grosor;
    float inside = step(borde, uv.x) * step(borde, uv.y) * step(uv.x, 1.0 - borde) * step(uv.y, 1.0 - borde);
    float relleno = step(uv.x, progreso);

    float t = animacion;
    float pulso = 0.5 + 0.5 * sin(t * 3.2 + uv.x * 8.0);
    vec3 grad_a = color_barra.rgb;
    vec3 grad_b = mix(color_barra.rgb, vec3(0.95, 0.35, 1.0), 0.55);
    vec3 grad_c = mix(color_barra.rgb, vec3(0.2, 1.0, 0.95), 0.6);

    vec3 gradiente = mix(grad_a, grad_b, uv.x);
    gradiente = mix(gradiente, grad_c, uv.y * 0.45);

    float barrido_pos = fract(t * 0.7);
    float barrido = exp(-pow((uv.x - barrido_pos) * 26.0, 2.0)) * relleno;
    float frente = exp(-pow((uv.x - progreso) * 85.0, 2.0)) * smoothstep(0.0, 1.0, progreso);

    vec3 fondo = color_fondo.rgb;
    vec3 barra_color = gradiente * (0.82 + 0.35 * pulso);
    barra_color += vec3(0.85, 0.95, 1.0) * (barrido * 0.55 + frente * 0.75);

    vec3 color_final = mix(fondo, barra_color, relleno * inside);

    float borde_mask = 1.0 - inside;
    color_final = mix(color_final, color_borde.rgb, borde_mask * 0.75);

    COLOR = vec4(color_final, 1.0);
}
