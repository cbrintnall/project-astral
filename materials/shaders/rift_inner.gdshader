shader_type spatial;
render_mode cull_disabled;

uniform sampler2D star_noise: repeat_enable;

uniform vec3 clr_a: source_color;
uniform vec3 clr_b: source_color;

void fragment() {
  float n1 = texture(star_noise, SCREEN_UV+vec2(500.0)).x;
	float n = texture(star_noise, SCREEN_UV + (vec2(n1)*0.1) + vec2(TIME*0.01, TIME*0.05)).x;
  
  float stepped = step(n, 0.4);
  
  ALBEDO = mix(clr_a,clr_b,smoothstep(0.4, 0.8, n));
  EMISSION = ALBEDO*3.0*n1;
  ALPHA = n1;
}