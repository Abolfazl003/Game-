shader_type spatial;

// NovaForge Elemental Chemistry Surface Shader (Dynamic Rain Wetness + Fire Charring)
uniform vec4 base_albedo : source_color = vec4(0.65, 0.62, 0.58, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float burn_char : hint_range(0.0, 1.0) = 0.0;
uniform float ember_glow : hint_range(0.0, 4.0) = 0.0;

void fragment() {
	vec3 wet_tinted = mix(base_albedo.rgb, base_albedo.rgb * 0.48, wetness);
	vec3 charred = mix(wet_tinted, vec3(0.06, 0.05, 0.05), burn_char);
	ALBEDO = charred;
	ROUGHNESS = mix(0.78, 0.08, wetness * (1.0 - burn_char));
	METALLIC = mix(0.05, 0.18, wetness);
	EMISSION = vec3(1.0, 0.28, 0.03) * burn_char * ember_glow;
}
