shader_type spatial;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
	float grain=sin(p.y*92.0+sin(p.x*0.8)*3.0)*0.008;
	grain*=1.0-smoothstep(0.025,0.12,fwidth(p.y));
	ALBEDO=vec3(0.68,0.53,0.35)+grain;
	ROUGHNESS=0.72;
}