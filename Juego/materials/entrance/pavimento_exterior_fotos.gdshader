shader_type spatial;
render_mode unshaded;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=wp.xz/vec2(0.60,0.30);
 p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 e=min(fract(p),1.0-fract(p));
 float joint=1.0-smoothstep(0.015,0.035,min(e.x,e.y));
 float tone=fract(sin(dot(floor(p),vec2(19.1,47.7)))*412.4)*0.035;
 ALBEDO=mix(vec3(0.30+tone),vec3(0.18),joint); ROUGHNESS=0.92;
}