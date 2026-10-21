shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.zy / 3.0;
	vec2 uv = fract(p);
	vec2 joint_distance = min(uv, 1.0 - uv);
	vec2 aa = max(fwidth(p), vec2(0.0005));
	vec2 lines = 1.0 - smoothstep(vec2(0.012), vec2(0.012) + aa, joint_distance);
	float frame = max(lines.x, lines.y);
	float variation = sin(dot(floor(p), vec2(12.4, 8.7))) * 0.025;
	vec3 blue = vec3(0.16, 0.38, 0.50) + variation;
	ALBEDO = mix(blue, vec3(0.045, 0.065, 0.075), frame);
	ROUGHNESS = mix(0.18, 0.55, frame);
	METALLIC = mix(0.25, 0.6, frame);
	SPECULAR = 0.65;
}
