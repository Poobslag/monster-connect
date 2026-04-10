shader_type spatial;

render_mode unshaded;

uniform vec4 mix_color: source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform sampler2D tex: source_color, repeat_disable;

void fragment() {
	vec4 color = texture(tex, UV);
	color.rgb = mix(color.rgb, mix_color.rgb, mix_color.a);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}