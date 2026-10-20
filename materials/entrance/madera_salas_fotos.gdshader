shader_type spatial;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float p=wp.x+wp.z;
 float grain=sin(p*65.0+sin(wp.y*0.8+p*2.2)*1.2)*0.018+sin(p*210.0+wp.y*0.5)*0.009;
 ALBEDO=vec3(0.72,0.60,0.44)+grain; ROUGHNESS=0.69;
}