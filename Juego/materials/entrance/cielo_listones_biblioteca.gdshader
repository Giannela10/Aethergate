shader_type spatial;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float phase=p.x/0.32;
	float aa=max(fwidth(phase),0.0001);
	float slat=1.0-smoothstep(0.28-aa,0.28+aa,abs(fract(phase)-0.5));
	float fade=1.0-smoothstep(0.3,0.9,aa);
	slat=mix(0.56,slat,fade);
	ALBEDO=mix(vec3(0.15,0.115,0.075),vec3(0.63,0.48,0.29),slat);
	ROUGHNESS=0.8;
}