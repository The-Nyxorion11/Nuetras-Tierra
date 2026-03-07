shader_type canvas_item;

uniform float blink_progress : hint_range(0.0, 1.0) = 0.0;
uniform float softness : hint_range(0.0, 0.5) = 0.15;

void fragment() {
    float dist = abs(UV.y - 0.5);
    float border = 0.5 - (blink_progress * 0.5);
    
    // Invertimos el orden: ahora 'dist' se compara de forma que
    // lo que está lejos del centro se pinte de negro.
    float mask = smoothstep(border - softness, border, dist);
    
    COLOR = vec4(0.0, 0.0, 0.0, mask);
}