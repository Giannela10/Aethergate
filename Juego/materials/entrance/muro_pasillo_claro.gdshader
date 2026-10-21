shader_type spatial;
varying vec3 pos;
void vertex() { pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float p = pos.y / 0.3;
	float edge = min(fract(p), 1.0 - fract(p));
	float seam = 1.0 - smoothstep(0.006, 0.006 + max(fwidth(p), 0.005), edge);
	float grain = sin(pos.x * 22.0 + pos.z * 19.0 + sin(pos.y * 6.0)) * 0.008;
	ALBEDO = mix(vec3(0.67, 0.64, 0.55) + grain, vec3(0.40, 0.38, 0.33), seam * 0.32);
	ROUGHNESS = 0.88;
	SPECULAR = 0.25;
}
