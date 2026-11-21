shader_type spatial;

varying vec3 punto_local;

void vertex() {
	punto_local = VERTEX;
}

void fragment() {
	vec2 baldosa = (punto_local.xz + vec2(156.0, 4.0)) / 0.4;
	float banda = mod(floor(baldosa.x), 12.0);
	vec3 color = vec3(0.46, 0.40, 0.31);
	if (banda < 4.0) {
		color = banda >= 1.0 && banda < 3.0 ? vec3(0.089, 0.094, 0.088) : vec3(0.45, 0.22, 0.18);
	}
	vec2 borde = min(fract(baldosa), 1.0 - fract(baldosa));
	vec2 junta = smoothstep(vec2(0.015), vec2(0.035) + fwidth(baldosa), borde);
	float detalle = 0.92 + 0.15 * fract(sin(dot(floor(baldosa), vec2(27.13, 78.23))) * 4375.13);
	float lejos = smoothstep(0.24, 0.72, fwidth(baldosa.x));
	vec3 cerca = mix(vec3(0.29, 0.26, 0.21), color * detalle, junta.x * junta.y);
	ALBEDO = mix(cerca, vec3(0.40, 0.34, 0.27), lejos);
	ROUGHNESS = 0.94;
}
