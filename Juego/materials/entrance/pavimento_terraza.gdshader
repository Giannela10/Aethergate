shader_type spatial;
varying vec3 pos;
void vertex() { pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = fract(pos.xz / vec2(2.0, 3.0));
	float seam = 1.0 - smoothstep(0.002, 0.009, min(min(p.x, 1.0 - p.x), min(p.y, 1.0 - p.y)));
	float variation = sin(dot(floor(pos.xz / vec2(2.0, 3.0)), vec2(12.3, 8.1))) * 0.015;
	ALBEDO = mix(vec3(0.38, 0.4, 0.42) + variation, vec3(0.20, 0.22, 0.24), seam);
	ROUGHNESS = 0.88;
}
