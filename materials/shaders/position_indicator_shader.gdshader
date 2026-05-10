shader_type spatial;

#include "res://otterlib/shaders/lib.gdshaderinc"

uniform sampler2D noise: repeat_enable;

void fragment() {
  vec2 polar = polar_coordinates(UV, vec2(0.5), 0.5, 0.5);
  float n = texture(noise, polar-vec2(0.0, TIME*0.1)).x;
  vec2 dist = abs(UV-vec2(0.5))*2.0;
  n = step(n, 0.5);
  
  ALBEDO = vec3(n);
  ALPHA = min(n, min(dist.x,dist.y));
  
  ALBEDO.r = polar.x;
}