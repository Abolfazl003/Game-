shader_type spatial;
render_mode vertex_lighting, skip_vertex_transform;

// NovaForge PSX / PS1 Retro Indie Shader (Vertex Grid Snapping + Bayer 4x4 Dither)
uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(1.0);
uniform float snap_resolution : hint_range(60.0, 480.0) = 160.0;
uniform float color_depth : hint_range(8.0, 64.0) = 24.0;

const mat4 BAYER_4X4 = mat4(
	vec4(-0.5,  0.0, -0.375, 0.125),
	vec4( 0.25, -0.25, 0.375, -0.125),
	vec4(-0.3125, 0.1875, -0.4375, 0.0625),
	vec4( 0.4375, -0.0625, 0.3125, -0.1875)
);

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	clip.xy = floor(clip.xy / clip.w * snap_resolution + 0.5) / snap_resolution * clip.w;
	POSITION = clip;
}

void fragment() {
	vec4 col = texture(albedo_tex, UV) * tint;
	ivec2 px = ivec2(FRAGCOORD.xy) % 4;
	float dither = BAYER_4X4[px.x][px.y] / color_depth;
	ALBEDO = floor((col.rgb + dither) * color_depth) / color_depth;
}
