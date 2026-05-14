shader_type spatial;

uniform sampler2D noise: repeat_enable;
uniform vec3 clr_a: source_color;
uniform vec3 clr_b: source_color;

void fragment() {
	float n = texture(noise, (UV*vec2(0.4, 1.0)) + (vec2(TIME)*vec2(0.2))).a;
  float alpha = smoothstep(.05, 0.5, n);
  
  ALBEDO = vec3(clr_a);
  ALPHA = alpha*pow(UV.y,2.0);
  EMISSION = mix(clr_a, clr_b, alpha)*50.0;
}
