shader_type spatial;
render_mode cull_disabled;

global uniform vec4 select_color;

uniform sampler2D noise: repeat_enable;

void fragment() {
  float n = texture(noise, UV + vec2(0.0, TIME*0.2)).x;
  float n2 = texture(noise, UV+vec2(0.5)).x;
  float n3 = texture(noise, UV+n2*0.3+vec2(TIME*0.1)).x;
  
  float snapped = step(n, 0.5);
  float snapped3 = step(n3, 0.5);
  
  ALBEDO = vec3(snapped3)*pow(select_color.rgb,vec3(2.2))*max(n,0.5)*250.0;
  ALPHA = pow(UV.y,3.0)*snapped*sin(n3);
}
