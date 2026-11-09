shader_type spatial;
uniform sampler2D source_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform bool use_normal=false;
uniform vec4 tone : source_color = vec4(1.0);
void fragment(){
 vec3 original=texture(source_texture,UV).rgb;
 float value=dot(original,vec3(0.2126,0.7152,0.0722));
 float panel=smoothstep(0.16,0.72,value);
 ALBEDO=mix(vec3(0.24,0.28,0.34),vec3(0.93,0.94,0.95),panel)*tone.rgb;
 ROUGHNESS=0.86;
 SPECULAR=0.2;
 if(use_normal){NORMAL_MAP=texture(normal_texture,UV).rgb;NORMAL_MAP_DEPTH=0.65;}
}
