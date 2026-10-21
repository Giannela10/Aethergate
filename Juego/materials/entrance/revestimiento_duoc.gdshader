shader_type spatial;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float slit(vec2 p, vec4 r) {
	return step(r.x, p.x) * step(p.x, r.y) * step(r.z, p.y) * step(p.y, r.w);
}
void fragment() {
	vec2 p = world_pos.xy;
	float plank = floor(p.y / 0.24);
	float grain = sin(p.x * 16.0 + sin(p.y * 170.0) * 0.7) * 0.018;
	float variation = sin(plank * 8.21) * 0.025;
	float joint = 1.0 - smoothstep(0.006, 0.025, abs(fract(p.y / 0.24) - 0.5) * 0.24);
	vec3 wood = vec3(0.57, 0.51, 0.41) + grain + variation;
	wood = mix(wood, vec3(0.38, 0.34, 0.28), joint * 0.42);
	float windows = 0.0;
	windows += slit(p, vec4(-80.0, -62.0, 9.6, 10.2));
	windows += slit(p, vec4(-70.0, -37.0, 10.5, 11.1));
	windows += slit(p, vec4(-61.0, -35.0, 8.1, 8.8));
	windows += slit(p, vec4(-78.0, -66.0, 7.9, 8.45));
	windows += slit(p, vec4(-63.0, -42.0, 6.5, 7.1));
	windows += slit(p, vec4(-63.0, -44.0, 4.2, 4.8));
	windows += slit(p, vec4(-45.0, -34.0, 3.2, 3.9));
	windows += slit(p, vec4(-71.0, -51.0, 1.9, 2.5));
	windows += slit(p, vec4(-51.0, -34.0, 0.75, 1.35));
	windows = clamp(windows, 0.0, 1.0);
	float mullion = 1.0 - smoothstep(0.0, 0.035, abs(fract(p.x / 2.4) - 0.5));
	vec3 glass = mix(vec3(0.09, 0.19, 0.20), vec3(0.022, 0.029, 0.030), mullion);
	glass += vec3(0.06, 0.085, 0.08) * smoothstep(1.0, 11.0, p.y);
	ALBEDO = mix(wood, glass, windows);
	ROUGHNESS = mix(0.88, 0.18, windows);
	METALLIC = windows * 0.25;
	SPECULAR = mix(0.22, 0.7, windows);
}
