// NOTE: Shader automatically converted from Godot Engine 4.7.beta1's StandardMaterial3D.
shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D noise: repeat_enable;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

varying vec3 coords;

void vertex() {
  coords = VERTEX;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv + vec2(TIME*0.1));
  float n1 = texture(noise, (coords.xz*3.0)+vec2(TIME*0.01)).x;
  
	ALBEDO = albedo.rgb * albedo_tex.rgb * 3.0;
	ALPHA *= albedo_tex.a;
}
