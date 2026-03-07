shader_type spatial;
render_mode cull_back, blend_mix;

uniform float metallic_value : hint_range(0.0, 1.0) = 1.0;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.0;
uniform vec3 albedo_color : hint_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
	ALBEDO = albedo_color;
}
