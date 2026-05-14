shader_type spatial;
render_mode cull_disabled;

uniform sampler2D star_noise: repeat_enable;

uniform vec3 color: source_color;

void fragment() {
	float n = texture(star_noise, (UV*vec2(3.0, 1.0)) + vec2(TIME*0.1, 0.0)).x;
  float stepped = step(n, 0.3);
  
  EMISSION = vec3(max(n,UV.y))*color;
  ALBEDO = vec3(max(n,pow(UV.y, 10.0)))*color;
  ALPHA = UV.y;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
