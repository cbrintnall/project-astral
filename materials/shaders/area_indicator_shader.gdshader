shader_type spatial;

uniform sampler2D tex;

void vertex() {
  float offset = (sin(TIME*3.0)+1.0)*0.5;
	VERTEX *= mix(0.8, 1.0, pow(offset, 10.0));
}

void fragment() {
	vec4 clr = texture(tex, UV);
  
  ALBEDO = clr.rgb;
  ALPHA = clr.a;
  EMISSION = clr.rgb;
}