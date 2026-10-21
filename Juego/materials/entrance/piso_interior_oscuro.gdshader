shader_type spatial;
varying vec3 pos;
void vertex() { pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = pos.xz / vec2(2.0, 2.0);
	vec2 uv = fract(p);
	vec2 edge = min(uv, 1.0 - uv);
	vec2 width = max(fwidth(p), vec2(0.0005));
	vec2 line = 1.0 - smoothstep(vec2(0.003), vec2(0.003) + width, edge);
	float seam = max(line.x, line.y);
	float variation = sin(dot(floor(p), vec2(12.3, 8.1))) * 0.004;
	ALBEDO = mix(vec3(0.045, 0.05, 0.052) + variation, vec3(0.012, 0.014, 0.015), seam);
	ROUGHNESS = 0.32;
	METALLIC = 0.06;
	SPECULAR = 0.5;
}
