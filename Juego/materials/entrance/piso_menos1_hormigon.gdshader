shader_type spatial;
render_mode specular_schlick_ggx;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}
void fragment() {
	vec2 p = world_position.xz * 0.85;
	float n = noise2(p) * 0.65 + noise2(p * 3.7) * 0.25 + noise2(p * 13.0) * 0.10;
	vec2 joint_cell = abs(fract(world_position.xz * 0.22) - vec2(0.5));
	float joint = 1.0 - smoothstep(0.475, 0.495, max(joint_cell.x, joint_cell.y));
	float scuff = noise2(world_position.xz * 4.4);
	vec3 concrete = mix(vec3(0.34, 0.35, 0.36), vec3(0.46, 0.47, 0.47), n);
	concrete *= 0.94 + scuff * 0.10;
	concrete = mix(concrete, concrete * 0.70, joint * 0.16);
	ALBEDO = concrete;
	EMISSION = concrete * 0.50;
	ROUGHNESS = 0.72;
	METALLIC = 0.025;
	SPECULAR = 0.28;
}