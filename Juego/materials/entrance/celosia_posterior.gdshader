shader_type spatial;
varying vec3 world_pos;
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
	vec2 p=world_pos.xy/vec2(0.55,3.0);
	vec2 d=min(fract(p),1.0-fract(p));
	vec2 aa=max(fwidth(p),vec2(0.0001));
	vec2 lines=1.0-smoothstep(vec2(0.045),vec2(0.045)+aa,d);
	float grid=max(lines.x,lines.y);
	float visibility=1.0-smoothstep(0.3,1.5,max(aa.x,aa.y));
	ALBEDO=mix(vec3(0.065,0.095,0.10),vec3(0.025,0.036,0.038),grid*visibility);
	ROUGHNESS=0.4;
	METALLIC=0.25;
}