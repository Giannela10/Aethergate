shader_type spatial;

uniform vec4 hormigon : source_color = vec4(0.53, 0.45, 0.36, 1.0);
varying vec3 punto_local;
varying vec3 normal_local;

void vertex() {
	punto_local = VERTEX;
	normal_local = NORMAL;
}

void fragment() {
	vec3 color = hormigon.rgb;
	if (abs(normal_local.y) < 0.5) {
		float lateral = abs(normal_local.x) > 0.5 ? punto_local.z : punto_local.x;
		vec2 celda = vec2(lateral / 3.2, punto_local.y / 3.1);
		vec2 borde = abs(fract(celda) - 0.5);
		vec2 ancho_pixel = max(fwidth(celda), vec2(0.001));
		vec2 ventana = 1.0 - smoothstep(vec2(0.34, 0.24) - ancho_pixel,
			vec2(0.34, 0.24) + ancho_pixel, borde);
		float variacion = fract(sin(dot(floor(celda), vec2(12.9898, 78.233))) * 43758.5453);
		vec3 vidrio = mix(vec3(0.043, 0.073, 0.09), vec3(0.15, 0.22, 0.25), variacion);
		color = mix(color, vidrio, ventana.x * ventana.y);
		float losa = smoothstep(0.41 - ancho_pixel.y, 0.41 + ancho_pixel.y, borde.y);
		color = mix(color, hormigon.rgb * 1.28, losa * 0.7);
	} else {
		color *= 0.7;
	}
	ALBEDO = color;
	ROUGHNESS = 0.85;
}
