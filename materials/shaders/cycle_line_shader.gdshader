shader_type canvas_item;

uniform float size = 1.0;
uniform float repeat = 0.2;
uniform float speed_scalar = 1.0;

void fragment() {
  float bound = mod(UV.x - TIME*speed_scalar,repeat);
	COLOR.a = step(bound, size);
}