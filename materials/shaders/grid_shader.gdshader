// https://godotshaders.com/shader/simple-world-triplanar-grid-allows-transparency/
shader_type spatial;

global uniform vec3 global_mouse_position;
global uniform vec2 grid_size;
global uniform vec3 grid_root;

uniform sampler2D noise: repeat_enable;

uniform float line_width : hint_range(0.0, 1.0) = 0.04;
uniform float visual_grid_size : hint_range(0.0, 10.0) = 1.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const float mouse_distance = 10.0;

void fragment() {
	// Calculate world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz+(vec3(0.5, 0.0, 0.5));
  float n = texture(noise, (world_pos.xz*0.05)+vec2(TIME*0.01, 0.0)).x;
  float n2 = texture(noise, ((world_pos.xz+vec2(15.0)+vec2(n))*0.1)+vec2(TIME*0.05, 0.0)).x;

	// Apply grid effect
  float step_range = 0.5;
	vec2 grid_pos = mod(world_pos.xz + visual_grid_size * 0.5, visual_grid_size) / visual_grid_size - 0.5;
	grid_pos = (abs(grid_pos) * 2.0);
  float width = line_width+(pow(n2, 5.0)*0.2);
  //width += (mouse_distance-min(distance(world_pos,global_mouse_position), mouse_distance))*0.005;
  //float width = line_width;
	//float line = min(smoothstep(width, width+step_range, grid_pos.x), smoothstep(width, width+step_range, grid_pos.y));
  float line = min(step(width, grid_pos.x), step(width, grid_pos.y));

  const float tile_fade_length = 1.0;
  vec3 dist = abs(world_pos - vec3(grid_root.x, 0.0, grid_root.y));
  vec2 used_size = ((grid_size+vec2(2.0))*0.5)+vec2(0.5*sign(world_pos.xz));
  float alpha_base = max(
    1.0-smoothstep(dist.x, dist.x+tile_fade_length, used_size.x),
    1.0-smoothstep(dist.z, dist.z+tile_fade_length, used_size.y)
  );
  
  // Apply color and transparency
  vec3 clr = mix(line_color.rgb, fill_color.rgb, line);
  ALBEDO = clr+(clr*(n*1.0));
  ALPHA = min(mix(line_color.a, fill_color.a, line), 1.0-alpha_base);
}