shader_type spatial;
render_mode cull_disabled;

uniform sampler2D noise: repeat_enable;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float n = texture(noise, UV + vec2(TIME*.01, 0.0)).x;
  
  //ALPHA = max(clamp(1.0-(polar_uv.x+0.5), 0.0, 1.0), step(n, 0.2));
  //ALPHA = step(n,(UV.y)*1.0); 
  //ALPHA = n;
  EMISSION = vec3(n)*1.0;
  ALBEDO.rg = UV;
  ALPHA = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
