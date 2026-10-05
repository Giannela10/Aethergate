shader_type spatial;
varying vec3 pos;
void vertex() { pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = pos.xy / vec2(3.0, 3.0);
	vec2 uv = fract(p);
	vec2 distance_to_joint = min(uv, 1.0 - uv);
	vec2 antialias = max(fwidth(p), vec2(0.0005));
	vec2 line = 1.0 - smoothstep(vec2(0.007), vec2(0.007) + antialias, distance_to_joint);
	float frame = max(line.x, line.y);
	float pane = sin(dot(floor(p), vec2(12.4, 8.7))) * 0.018;
	float sky_reflection = smoothstep(48.0, 96.0, pos.y) * 0.08;
	vec3 blue_glass = vec3(0.19, 0.30, 0.33) + pane + sky_reflection;
	ALBEDO = mix(blue_glass, vec3(0.055, 0.075, 0.08), frame);
	ROUGHNESS = mix(0.22, 0.46, frame);
	METALLIC = mix(0.32, 0.6, frame);
	SPECULAR = 0.65;
}
