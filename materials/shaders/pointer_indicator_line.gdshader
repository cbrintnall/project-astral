shader_type spatial;
render_mode cull_disabled;

void vertex() {
  vec3 object_pos = MODEL_MATRIX[3].xyz;
  vec3 camera_pos = INV_VIEW_MATRIX[3].xyz;
  vec3 look = camera_pos - object_pos;

  look.y = 0.0;
  look = normalize(look);

  vec3 up = vec3(0.0, 1.0, 0.0);
  vec3 side = normalize(cross(up, look));

  MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
    vec4(look, 0.0),
    vec4(up, 0.0),   
    vec4(side, 0.0), 
    MODEL_MATRIX[3]
  );
}

void fragment() {
  vec2 uv = step(vec2(.5), UV);
  vec2 bounded_uv = mod(UV+vec2(0.0, TIME), vec2(1.0));

  ALBEDO = vec3(1.0);
  EMISSION = vec3(5.0);
  ALPHA = step(bounded_uv.y, 0.7);
}
