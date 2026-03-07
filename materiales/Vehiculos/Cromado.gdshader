shader_type spatial;

uniform vec4 chrome_color : source_color = vec4(0.9, 0.9, 0.95, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 1.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.05;
uniform float fresnel_strength : hint_range(0.0, 5.0) = 2.0;
uniform vec4 fresnel_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform samplerCube environment_map : hint_default_white;
uniform float reflection_strength : hint_range(0.0, 2.0) = 1.2;

void fragment() {
    // Fresnel fuerte (característica principal del cromado)
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0) * fresnel_strength;

    // Reflexión del entorno
    vec3 reflected = reflect(-VIEW, NORMAL);
    vec3 env_sample = texture(environment_map, reflected).rgb * reflection_strength;

    // Mezcla base + fresnel + entorno
    vec3 final_color = mix(chrome_color.rgb, fresnel_color.rgb, fresnel);
    final_color = mix(final_color, env_sample, 0.6);

    ALBEDO = final_color;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = 1.0;
    EMISSION = env_sample * 0.1; // Pequeño glow del reflejo
}