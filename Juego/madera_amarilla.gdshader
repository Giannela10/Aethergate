shader_type spatial;
varying vec3 p;
void vertex() { p = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float grain = sin(p.x * 9.0 + sin(p.y * 1.7 + p.z * 1.2) * 3.0);
	float veins = smoothstep(0.6,1.0,grain);
	ALBEDO = mix(vec3(0.78,0.56,0.19),vec3(0.48,0.29,0.08),veins * 0.4);
	ROUGHNESS = 0.7;
}