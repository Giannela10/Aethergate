shader_type spatial;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 plane = abs(world_normal.x) > 0.5 ? world_position.zy : world_position.xy;
	vec2 tile = plane / vec2(1.25, 0.55);
	vec2 edge = min(fract(tile), 1.0 - fract(tile));
	float joint = 1.0 - smoothstep(0.002, 0.008, min(edge.x, edge.y));
	ALBEDO = mix(vec3(0.66, 0.58, 0.47), vec3(0.27, 0.24, 0.20), joint * 0.65);
	ROUGHNESS = 0.78;
}
