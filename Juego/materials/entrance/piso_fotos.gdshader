shader_type spatial;
render_mode ambient_light_disabled;
varying vec3 wp;
varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; wn=normalize(mat3(MODEL_MATRIX)*NORMAL);}
void fragment(){
 vec2 p=wp.xz/1.2;
 vec2 edge=min(fract(p),1.0-fract(p));
 float joint=1.0-smoothstep(0.004,0.012,min(edge.x,edge.y));
 float v=sin(wp.x*3.1+wp.z*2.3+sin(wp.z*1.3)*2.2);
 float veins=pow(1.0-abs(v),48.0)*0.065;
 float grain=sin(wp.x*137.0+wp.z*89.0)*0.004;
 vec3 base=mix(vec3(0.073+veins+grain),vec3(0.023),joint);
 ALBEDO=base; EMISSION=base*0.65; ROUGHNESS=0.28; SPECULAR=0.55;
 if(wn.y<0.7){ALBEDO=vec3(0.30+grain);EMISSION=vec3(0.10);ROUGHNESS=0.90;SPECULAR=0.18;}
}