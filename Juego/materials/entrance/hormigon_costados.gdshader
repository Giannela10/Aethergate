shader_type spatial;
varying vec3 world_position;
float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
	vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash21(i),hash21(i+vec2(1.,0.)),f.x),mix(hash21(i+vec2(0.,1.)),hash21(i+vec2(1.,1.)),f.x),f.y);
}
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p=vec2(world_position.z,world_position.y);
	float q=p.y/0.95;
	float aa=max(fwidth(q),0.002);
	float joint=(1.0-smoothstep(0.012,0.012+aa,abs(fract(q)-0.5)))*(1.0-smoothstep(0.5,1.8,aa));
	float broad=noise2(p*vec2(0.20,0.12))-0.5;
	float grain=noise2(p*vec2(4.0,1.1))-0.5;
	float boards=noise2(vec2(p.x*0.055,floor(q)))-0.5;
	float value=0.52+broad*0.055+grain*0.018+boards*0.018-joint*0.065;
	ALBEDO=vec3(value*0.98,value,value*0.99);
	ROUGHNESS=0.96;
	METALLIC=0.0;
}
