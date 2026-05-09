// https://godotshaders.com/shader/simple-world-triplanar-grid-allows-transparency/
shader_type spatial;

global uniform vec3 global_mouse_position;

uniform sampler2D noise: repeat_enable;

uniform float line_width : hint_range(0.0, 1.0) = 0.04;
uniform float grid_size : hint_range(0.0, 10.0) = 1.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

const float mouse_distance = 10.0;

void fragment() {
	// Calculate world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz+(vec3(0.5, 0.0, 0.5));
  float n = texture(noise, (world_pos.xz*0.05)+vec2(TIME*0.01, 0.0)).x;
  float n2 = texture(noise, ((world_pos.xz+vec2(15.0))*0.1)+vec2(TIME*0.05, 0.0)).x;

	// Apply grid effect
  float step_range = 0.5;
	vec2 grid_pos = mod(world_pos.xz + grid_size * 0.5, grid_size) / grid_size - 0.5;
	grid_pos = (abs(grid_pos) * 2.0);
  float width = line_width+(pow(n2, 15.0)*0.3);
  width += (mouse_distance-min(distance(world_pos,global_mouse_position), mouse_distance))*0.005;
  //float width = line_width;
	//float line = min(smoothstep(width, width+step_range, grid_pos.x), smoothstep(width, width+step_range, grid_pos.y));
  float line = min(step(width, grid_pos.x), step(width, grid_pos.y));

	// Apply color and transparency
  vec3 clr = mix(line_color.rgb, fill_color.rgb, line);
	ALBEDO = clr+(clr*(n*5.0));
	ALPHA = mix(line_color.a, fill_color.a, line);
}