shader_type canvas_item;

instance uniform float progress = 0.5;

void fragment() {
  COLOR = mix(
    COLOR, 
    COLOR*vec4(1.0, 1.0, 1.0, 0.1), 
    step(progress, 1.0-UV.y)
  );
}
