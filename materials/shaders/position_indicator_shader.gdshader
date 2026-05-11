shader_type spatial;

#include "res://otterlib/shaders/lib.gdshaderinc"

uniform sampler2D noise: repeat_enable;
uniform float rad: hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float feather: hint_range(0.0, 1.0, 0.01) = 0.5;

void fragment() {
  vec2 scalar = vec2(5.0, 5.0);
  vec2 polar = polar_coordinates(UV*scalar, vec2(scalar)*0.5, 0.5, 0.5)*vec2(1.0,1.0);
  float n = texture(noise, polar-vec2(0.0, TIME*0.1)).x;
  float dist = length(UV-vec2(0.5));
  n = step(n, 0.5);
  
  ALBEDO = vec3(n);
  ALPHA = min(n, smoothstep(rad, rad-feather, dist));
}