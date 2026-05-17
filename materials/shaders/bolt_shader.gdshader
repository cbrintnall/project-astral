shader_type spatial;
render_mode cull_disabled;

#include "res://otterlib/shaders/lib.gdshaderinc"

uniform sampler2D noise: repeat_enable;
uniform float leg_scalar = 1.0;
uniform float speed = 1.0;

void fragment() {
  vec2 polar_uv = polar_coordinates(UV, vec2(0.5), 1.0, 1.0);
  float n = texture(noise, polar_uv+vec2(-TIME*speed, 0.0)).x;
  
  ALBEDO = vec3(n);
  //ALPHA = max(clamp(1.0-(polar_uv.x+0.5), 0.0, 1.0), step(n, 0.2));
  ALPHA = step(n,(1.0-polar_uv.x)*leg_scalar); 
  EMISSION = vec3(n)*15.0;
}