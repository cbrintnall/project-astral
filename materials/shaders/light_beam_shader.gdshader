shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise: repeat_enable;
uniform vec3 clr: source_color;

void fragment() {
	float n = texture(noise, (UV*vec2(1.0, 0.05))+vec2(0.0, TIME*0.4)).x;
  float stepped = smoothstep(0.4, 0.8, n);
  
  ALBEDO = vec3(n);
  ALPHA = stepped;
  EMISSION = stepped*clr*5.0;
}
