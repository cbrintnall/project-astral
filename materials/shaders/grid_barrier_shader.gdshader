shader_type spatial;
render_mode world_vertex_coords;

global uniform vec2 grid_size;
global uniform vec3 grid_root;

uniform float border_margin = 0.0;
uniform float mist_margin = 0.0;
uniform vec3 color: source_color;
uniform vec3 base_color: source_color;
uniform sampler2D noise: repeat_enable;

varying vec3 world_pos;

void vertex() {
	world_pos = VERTEX;
}

void fragment() {
  float n = texture(noise, (world_pos.xz*0.1)+vec2(TIME*0.03)).x;
  float n1 = texture(noise, (world_pos.xz*0.1)+vec2(TIME*0.01)+vec2(500.0)).x;
  
  vec3 dist = abs(world_pos - vec3(grid_root.x, 0.0, grid_root.y));
  
  vec2 used_size = ((grid_size)*0.5)+vec2(0.5)+vec2(border_margin);
  
  ALBEDO = mix(base_color, color, n1);
  
  float alpha_base = max(
    1.0-step(dist.x, used_size.x+n*mist_margin),
    1.0-step(dist.z, used_size.y+n*mist_margin)
  );
  
	ALPHA = min(alpha_base, pow(n1,2.0)*5.0);
}
