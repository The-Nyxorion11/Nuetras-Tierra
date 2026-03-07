shader_type spatial;

// --- Configuración de Pintura ---
uniform vec4 base_color : source_color = vec4(0.1, 0.2, 0.5, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform float clearcoat : hint_range(0.0, 1.0) = 0.5;

// --- Control principal (desde GDScript) ---
instance uniform float dirt_amount   : hint_range(0.0, 1.0) = 0.0; // Cuánta suciedad
instance uniform float mud_amount    : hint_range(0.0, 1.0) = 0.0; // Cuánto barro
instance uniform float wet_amount    : hint_range(0.0, 1.0) = 0.0; // Cuánto mojado

// --- Texturas ---
uniform sampler2D dirt_noise_tex  : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mud_noise_tex   : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D wet_noise_tex   : source_color, filter_linear_mipmap, repeat_enable;

// --- Colores de suciedad ---
uniform vec4 dust_color : source_color = vec4(0.62, 0.54, 0.42, 1.0); // Polvo beige grisáceo
uniform vec4 mud_color  : source_color = vec4(0.28, 0.20, 0.12, 1.0); // Barro oscuro marrón
uniform vec4 mud_streak_color : source_color = vec4(0.18, 0.13, 0.08, 1.0); // Vetas oscuras de barro

// --- Escalas de textura ---
uniform float dust_scale : hint_range(0.1, 10.0) = 3.0;
uniform float mud_scale  : hint_range(0.1, 10.0) = 1.8;
uniform float wet_scale  : hint_range(0.1, 10.0) = 4.0;

// --- Profundidad de normales ---
uniform float dust_normal_depth : hint_range(0.0, 2.0) = 0.4;
uniform float mud_normal_depth  : hint_range(0.0, 3.0) = 1.4;

varying float v_height;
varying vec3 v_world_pos;
varying vec3 v_normal_world;

void vertex() {
	v_height = VERTEX.y;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal_world = NORMAL;
}

// Genera normal desde ruido para dar micro-relieve
vec3 bump_normal(sampler2D tex, vec2 uv, float strength) {
	float s01 = texture(tex, uv + vec2(-0.008, 0.0)).r;
	float s21 = texture(tex, uv + vec2( 0.008, 0.0)).r;
	float s10 = texture(tex, uv + vec2(0.0, -0.008)).r;
	float s12 = texture(tex, uv + vec2(0.0,  0.008)).r;
	vec3 va = normalize(vec3(2.0, 0.0, s21 - s01));
	vec3 vb = normalize(vec3(0.0, 2.0, s12 - s10));
	return cross(va, vb) * strength;
}

void fragment() {
	// ════════════════════════════════════════
	//  UVs TRI-PLANARES (sin estiramiento)
	// ════════════════════════════════════════
	vec2 uv_dust = v_world_pos.xz * dust_scale;
	vec2 uv_mud  = v_world_pos.xz * mud_scale;
	vec2 uv_wet  = v_world_pos.xz * wet_scale;

	float noise_dust = texture(dirt_noise_tex, uv_dust).r;
	float noise_mud  = texture(mud_noise_tex,  uv_mud).r;
	float noise_wet  = texture(wet_noise_tex,  uv_wet).r;

	// Detalle extra de barro con segunda capa desplazada (churretones)
	float noise_mud2 = texture(mud_noise_tex, uv_mud * 0.5 + vec2(0.3, 0.7)).r;
	float mud_streaks = noise_mud * noise_mud2; // Vetas donde se superponen

	// ════════════════════════════════════════
	//  GRADIENTE DE ALTURA
	//  Polvo acumula abajo y en recovecos
	//  Barro salpica fuerte abajo
	// ════════════════════════════════════════
	float height_dust = smoothstep(2.0, -0.5, v_height);       // Más abajo = más polvo
	float height_mud  = smoothstep(1.2, -1.0, v_height);       // Barro sube menos
	float height_wet  = clamp(1.0 - v_height * 0.15, 0.0, 1.0); // Húmedo es más uniforme

	// ════════════════════════════════════════
	//  MÁSCARAS FINALES
	// ════════════════════════════════════════
	// Polvo: granular y sutil, se acumula en zonas planas y bajas
	float dust_mask = smoothstep(
		1.0 - dirt_amount,
		1.05 - dirt_amount,
		noise_dust * height_dust
	);

	// Barro: más grueso, con churretones visibles
	float mud_base = smoothstep(
		1.0 - mud_amount,
		1.08 - mud_amount,
		noise_mud * height_mud
	);
	float mud_mask = clamp(mud_base + mud_streaks * mud_amount * 0.6, 0.0, 1.0);

	// Mojado: brillo en toda la superficie con variación de ruido
	float wet_mask = wet_amount * (0.6 + noise_wet * 0.4) * height_wet;

	// ════════════════════════════════════════
	//  NORMALES (micro-relieve por capa)
	// ════════════════════════════════════════
	vec3 n_dust = bump_normal(dirt_noise_tex, uv_dust, dust_normal_depth);
	vec3 n_mud  = bump_normal(mud_noise_tex,  uv_mud,  mud_normal_depth);

	vec3 final_normal = NORMAL;
	final_normal = mix(final_normal, normalize(final_normal + n_dust), dust_mask * 0.5);
	final_normal = mix(final_normal, normalize(final_normal + n_mud),  mud_mask);
	NORMAL = normalize(final_normal);

	// ════════════════════════════════════════
	//  COLOR BASE (pintura limpia con fresnel)
	// ════════════════════════════════════════
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 paint = mix(base_color.rgb, vec3(1.0), fresnel * clearcoat);

	// ════════════════════════════════════════
	//  ALBEDO FINAL
	//  Orden: pintura → polvo → barro
	//  El barro tapa el polvo porque es más reciente
	// ════════════════════════════════════════
	vec3 with_dust = mix(paint, dust_color.rgb, dust_mask);
	vec3 mud_final_color = mix(mud_color.rgb, mud_streak_color.rgb, clamp(mud_streaks * 2.0, 0.0, 1.0));
	vec3 with_mud  = mix(with_dust, mud_final_color, mud_mask);

	// Mojado oscurece ligeramente el color (efecto físico real: agua satura pigmentos)
	vec3 wet_darkened = with_mud * (1.0 - wet_mask * 0.25);
	ALBEDO = wet_darkened;

	// ════════════════════════════════════════
	//  PBR: METALLIC / ROUGHNESS / SPECULAR
	// ════════════════════════════════════════
	// Polvo: mate total, sin metal
	float m_dust = mix(metallic, 0.0, dust_mask);
	float r_dust = mix(roughness, 0.92, dust_mask);

	// Barro: muy mate y rugoso, parece pasta
	float m_mud  = mix(m_dust, 0.0,  mud_mask);
	float r_mud  = mix(r_dust, 0.98, mud_mask);

	// Mojado: baja la rugosidad (superficie especular como espejo húmedo)
	// Solo afecta donde NO hay barro grueso
	float wet_influence = wet_mask * (1.0 - mud_mask);
	METALLIC   = mix(m_mud, 0.0,  wet_influence);
	ROUGHNESS  = mix(r_mud, 0.08, wet_influence); // Casi espejo cuando está mojado
	SPECULAR   = mix(0.5,   0.9,  wet_influence); // Reflejo brillante del agua

	// El barro es completamente mate
	SPECULAR = mix(SPECULAR, 0.0, mud_mask);
}