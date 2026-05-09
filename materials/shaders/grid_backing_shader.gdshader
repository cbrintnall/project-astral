shader_type spatial;
render_mode world_vertex_coords;

uniform vec3 clr_a: source_color;
uniform vec3 clr_b: source_color;

uniform float base_edge: hint_range(0.0, 1.0, 0.01) = 0.1;

uniform sampler2D noise: repeat_enable;

varying vec3 coords;

void vertex() {
  coords = VERTEX;
}

void fragment() {
  vec2 offset = vec2(TIME*0.00);
  float n = texture(noise, SCREEN_UV+offset+vec2(TIME*0.005)).x;
  float size = ((sin(TIME+coords.x)+1.0)*0.5)*250.0;
  float star = step(n, 0.9);
  
  ALBEDO = mix(clr_a*size, clr_b, star);
}
