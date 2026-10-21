shader_type spatial;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float pane = floor(world_pos.x / 3.0);
	float reflectivity = 0.025 * sin(pane * 19.4);
	vec3 glass = mix(vec3(0.06, 0.16, 0.17), vec3(0.25, 0.39, 0.40), smoothstep(12.0, 48.0, world_pos.y));
	float reflection = sin(world_pos.x * 0.045 + world_pos.y * 0.13) * 0.035;
	ALBEDO = glass + reflectivity + reflection;
	ROUGHNESS = 0.24;
	METALLIC = 0.28;
	SPECULAR = 0.65;
}
