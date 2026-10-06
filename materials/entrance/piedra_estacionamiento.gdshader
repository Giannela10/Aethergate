shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p = world_position.xz/vec2(0.65,0.42);
 p.x += mod(floor(p.y),2.0)*0.5;
 vec2 cell = floor(p);
 vec2 uv = fract(p);
 float edge = min(min(uv.x,1.0-uv.x),min(uv.y,1.0-uv.y));
 float joint = smoothstep(0.012,0.045,edge);
 float grain = hash(floor(world_position.xz*90.0));
 vec3 stone = vec3(0.40,0.405,0.39)+(hash(cell)-0.5)*0.17+(grain-0.5)*0.055;
 ALBEDO = mix(vec3(0.20,0.205,0.20),stone,joint);
 ROUGHNESS = 0.96;
}
