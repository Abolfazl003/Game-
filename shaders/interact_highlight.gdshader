shader_type spatial;
render_mode unshaded, cull_front, blend_add;

// NovaForge Smart Interactable & NPC Selection Fresnel Highlight
uniform vec4 highlight_color : source_color = vec4(0.2, 0.85, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 0.08) = 0.022;
uniform float pulse_speed : hint_range(0.5, 8.0) = 3.2;

void vertex() {
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);
	VERTEX += NORMAL * outline_width * pulse;
}

void fragment() {
	ALBEDO = highlight_color.rgb;
	ALPHA = highlight_color.a;
}
