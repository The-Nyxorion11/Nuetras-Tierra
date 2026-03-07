shader_type canvas_item;

uniform float opacidad      : hint_range(0.0, 1.0) = 0.55;
uniform float presionado    : hint_range(0.0, 1.0) = 0.0;
uniform float redondeo      : hint_range(0.0, 0.1) = 0.03;

float sdRect(vec2 p, vec2 b, float r) {
	vec2 d = abs(p) - b + vec2(r);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}

void fragment() {
	vec2 uv = UV - 0.5;

	// ── CUERPO ───────────────────────────────────────────────────
	float cuerpo         = sdRect(uv, vec2(0.25, 0.42), redondeo);
	float mascara_cuerpo = smoothstep(0.005, 0.0, cuerpo);

	// Borde fino
	float mascara_borde  = smoothstep(0.015, 0.005, cuerpo);

	// ── PANTALLA ─────────────────────────────────────────────────
	float pantalla         = sdRect(uv + vec2(0.0, 0.01), vec2(0.20, 0.32), redondeo * 0.5);
	float mascara_pantalla = smoothstep(0.004, 0.0, pantalla);

	// ── CÁMARA ───────────────────────────────────────────────────
	float camara         = length(uv - vec2(0.0, -0.345)) - 0.015;
	float mascara_camara = smoothstep(0.003, 0.0, camara);

	// ── GRISES ───────────────────────────────────────────────────
	vec3 c_cuerpo   = vec3(0.12);          // Gris muy oscuro
	vec3 c_borde    = vec3(0.22);          // Gris medio para borde
	vec3 c_pantalla = vec3(0.08);          // Casi negro en pantalla
	vec3 c_presion  = vec3(0.35);          // Gris claro al presionar
	vec3 c_camara   = vec3(0.05);          // Negro cámara

	// ── COMPOSICIÓN ──────────────────────────────────────────────
	vec3 color_final = vec3(0.0);

	color_final = mix(color_final, c_cuerpo,   mascara_cuerpo);
	color_final = mix(color_final, c_borde,    mascara_borde * (1.0 - mascara_pantalla));
	color_final = mix(color_final, c_pantalla, mascara_pantalla);
	color_final = mix(color_final, c_presion,  mascara_pantalla * presionado);
	color_final = mix(color_final, c_camara,   mascara_camara);

	// Opacidad global
	float alpha = mascara_cuerpo * opacidad;

	COLOR = vec4(color_final, alpha);
}