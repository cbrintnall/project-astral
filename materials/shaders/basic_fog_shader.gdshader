shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D noise: repeat_enable;
uniform vec3 clr_a: source_color;
uniform vec3 clr_b: source_color;

varying vec2 world_coords;

void vertex() {
  world_coords = vec2(VERTEX.x, VERTEX.z);
}

void fragment() {
  float n = texture(noise, (world_coords*0.1)+vec2(TIME*0.01)).x;
  
  ALBEDO = mix(clr_a,clr_b,n);
  ALPHA = n*0.5;
}