shader_type spatial;
render_mode world_vertex_coords, cull_front;

uniform sampler2D noise: repeat_enable;
uniform sampler2D vnoise: repeat_enable;

uniform float fresnel_power = 1.0;

uniform vec3 clr_a: source_color;
uniform vec3 clr_b: source_color;

varying vec3 normal;

void vertex() {
	float n = texture(noise, VERTEX.xz + vec2(TIME*0.1, 0.0)).x;
  
  normal = NORMAL;
  VERTEX += NORMAL*n*0.005;
}

void fragment() {
  float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
  float pn = texture(noise, SCREEN_UV + vec2((TIME*0.01)+10.0, 0.0)).x;
  float n = texture(vnoise, SCREEN_UV + vec2(TIME*0.01, pn) ).x;
  
  ALBEDO = vec3(fresnel) + mix(clr_b, clr_a, vec3(n));
  EMISSION = vec3(fresnel) * 2.0;
}
