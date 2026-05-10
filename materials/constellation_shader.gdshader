// NOTE: Shader automatically converted from Godot Engine 4.7.beta1's StandardMaterial3D.

shader_type spatial;
render_mode cull_disabled, world_vertex_coords;

instance uniform float glow = 10.0;

uniform sampler2D noise: repeat_enable;
uniform vec3 clr: source_color;

varying vec3 coords;

void vertex() {
  coords = VERTEX;
}

void fragment() {
  float n = texture(noise, (UV*vec2(4.0, 0.00001)) + vec2(TIME*0.1, 0.0)).x;
  //n = min(n, pow(UV.y,3.0));
  n = smoothstep(n,n+.75,UV.y*1.1);
  
  ALBEDO = vec3(n)*clr*glow;
  ALPHA = n;
}