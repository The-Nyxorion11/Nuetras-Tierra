shader_type canvas_item;

// Shader simple para oscurecer el fondo con un efecto sutil
void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb *= 0.7; // Oscurecer 30%
}
