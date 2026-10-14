shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D fotografia : source_color, filter_linear_mipmap;
uniform vec4 recorte = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool circular = false;
void fragment() {
	if (circular && length(UV - vec2(0.5)) > 0.49) { discard; }
	ALBEDO = texture(fotografia, recorte.xy + UV * recorte.zw).rgb;
}
