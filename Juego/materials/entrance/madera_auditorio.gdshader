shader_type spatial;
varying vec3 pos;
void vertex() {
	pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = abs(NORMAL.y) > 0.6 ? pos.xz : pos.xy;
	vec2 panel = floor(p / vec2(3.0, 2.5));
	vec2 uv = fract(p / vec2(3.0, 2.5));
	float grain = sin(p.x * 45.0 + sin(p.y * 3.0) * 2.5) * 0.006;
	float knot = sin(length((uv - vec2(0.35, 0.6)) * vec2(1.7, 0.7)) * 48.0) * 0.008;
	float variation = sin(dot(panel, vec2(13.1, 7.4))) * 0.024;
	ALBEDO = vec3(0.64, 0.55, 0.40) + grain + knot + variation;
	ROUGHNESS = 0.83;
	SPECULAR = 0.23;
}
