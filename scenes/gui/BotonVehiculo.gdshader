shader_type canvas_item;

uniform bool activo = false;
uniform vec4 color_activo   = vec4(1.0, 0.9, 0.1, 0.88); // Amarillo cálido semitransparente
uniform vec4 color_inactivo = vec4(1.0, 1.0, 1.0, 0.22); // Blanco suave con opacidad
uniform float brillo_activo  : hint_range(0.5, 2.0) = 1.4;
uniform float radio_bordes   : hint_range(0.0, 0.49) = 0.18; // Fracción del tamaño

void fragment() {
	// SDF rectángulo redondeado centrado en UV [0,1]
	vec2 uv = UV - 0.5;
	float r = radio_bordes;
	vec2 q = abs(uv) - vec2(0.5 - r);
	float dist = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
	float alpha_forma = 1.0 - smoothstep(-0.005, 0.005, dist);

	// Color y brillo según estado activo
	vec4 color_base = activo ? color_activo : color_inactivo;
	float brillo     = activo ? brillo_activo : 1.0;

	vec3 color_final = clamp(color_base.rgb * brillo, 0.0, 1.0);
	float alpha_final = color_base.a * alpha_forma;

	COLOR = vec4(color_final, alpha_final);
}
