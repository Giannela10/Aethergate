shader_type spatial;
render_mode ambient_light_disabled;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = world_position.xz;
	vec2 tile = floor(p / 0.8);
	vec2 edge = min(fract(p / 0.8), 1.0 - fract(p / 0.8));
	float grout = 1.0 - smoothstep(0.003, 0.010, min(edge.x, edge.y));
	float wave = sin(p.x * 13.0 + sin(p.y * 5.0 + sin(p.x * 3.0)) * 3.0 + sin(p.y * 27.0 + p.x * 17.0) * 0.3);
	float veins = pow(1.0 - abs(wave), 12.0);
	float variation = hash(tile);
	vec3 stone = mix(vec3(0.075, 0.072, 0.070), vec3(0.15, 0.145, 0.14), variation);
	stone += veins * vec3(0.065, 0.060, 0.055);
	ALBEDO = mix(stone, vec3(0.035), grout * 0.6);
	EMISSION = ALBEDO * 0.65;
	ROUGHNESS = mix(0.32 + 0.06 * variation, 0.85, grout);
	SPECULAR = 0.22;
	METALLIC = 0.0;
}
