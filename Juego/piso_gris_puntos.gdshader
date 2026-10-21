shader_type spatial;
varying vec3 world_pos;
float hash21(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 grid = world_pos.xz * 7.0;
	vec2 cell = floor(grid);
	vec2 offset = vec2(hash21(cell), hash21(cell + 13.7)) * 0.6 + 0.2;
	float radius = mix(0.04,0.13,hash21(cell + 51.3));
	float dots = 1.0 - smoothstep(radius, radius + 0.018, length(fract(grid) - offset));
	ALBEDO = mix(vec3(0.48,0.49,0.50), vec3(0.025), dots);
	ROUGHNESS = 0.88;
}