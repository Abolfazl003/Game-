shader_type spatial;
render_mode diffuse_toon, specular_toon;

// NovaForge Indie Cel-Shaded / Anime Shader
uniform vec4 albedo_color : source_color = vec4(0.92, 0.94, 0.98, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform int shade_bands : hint_range(2, 6) = 3;
uniform float rim_strength : hint_range(0.0, 2.0) = 0.65;
uniform vec4 rim_color : source_color = vec4(0.65, 0.85, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(albedo_tex, UV);
	ALBEDO = albedo_color.rgb * tex.rgb;
}

void light() {
	float ndotl = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float stepped = floor(ndotl * float(shade_bands)) / float(shade_bands);
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * stepped;
	SPECULAR_LIGHT += rim_color.rgb * fresnel * rim_strength * ATTENUATION;
}
