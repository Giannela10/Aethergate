// Selective visual-only edits; recovery predates this script. Never edit gameplay owners.
const fs=require('fs');
if(fs.readFileSync('Juego/scripts/juego/humanoid.gd','utf8').includes('const Surface6'))throw Error('6.0 already applied; never reapply over user work');
function edit(p,fn){const s=fs.readFileSync(p,'utf8');const t=fn(s);if(s===t)throw Error('No change '+p);fs.writeFileSync(p,t);}
const root='Juego/scripts/';
edit(root+'juego/humanoid.gd',s=>{
 s=s.replace('var angry := false','const Surface6 = preload("res://scripts/juego/character_surface_6.gd")\nvar angry := false');
 s=s.replace('_cyl(chest, 0.165, 0.135, 0.30, Vector3(0, 0.12, 0), shirt_color, Vector3(1.1, 1.0, 0.74))\n\t_ball(chest, 0.16, Vector3(0, 0.26, 0), shirt_color, Vector3(1.1, 0.35, 0.74))','_node(chest,Surface6.contour("torso6",[Vector2(-0.03,0),Vector2(-0.02,0.132),Vector2(0.06,0.145),Vector2(0.18,0.175),Vector2(0.245,0.174),Vector2(0.28,0.115),Vector2(0.29,0.05),Vector2(0.295,0)],0.76),Vector3.ZERO,shirt_color,Vector3.ONE,0.88)');
 const start=s.indexOf('func _build_head() -> void:');const end=s.indexOf('func _build_arm',start);
 s=s.slice(0,start)+`func _build_head() -> void:
\tvar face := _node(head_pivot,Surface6.contour("head6",[Vector2(-0.012,0),Vector2(0.005,0.048),Vector2(0.035,0.073),Vector2(0.075,0.091),Vector2(0.12,0.093),Vector2(0.165,0.089),Vector2(0.198,0.070),Vector2(0.218,0.033),Vector2(0.223,0)],0.91,28),Vector3.ZERO,skin_color,Vector3.ONE,0.82)
\tface.name = "FaceContour6"
\tvar hair := SphereMesh.new()
\thair.radius=0.101
\thair.height=0.202
\thair.is_hemisphere=true
\t_node(head_pivot,hair,Vector3(0,0.137,0.012),hair_color,Vector3(0.96,0.83,0.94),0.95)
\tfor side in [-1.0,1.0]:
\t\t_ball(head_pivot,0.019,Vector3(side*0.094,0.09,0),skin_color,Vector3(0.5,1,0.65),0.84)
\t\tvar eye := _ball(head_pivot,0.012,Vector3(side*0.035,0.111,-0.079),Color("f4f3ec"),Vector3(1,0.47,0.42),0.5)
\t\teye.name = "EyeWhite6"
\t\t_ball(head_pivot,0.005,Vector3(side*0.035,0.111,-0.084),Color("303b32"),Vector3(1,1,0.45),0.45)
\t\tvar brow := _box(head_pivot,Vector3(0.032,0.004,0.006),Vector3(side*0.035,0.135,-0.079),hair_color,0.94)
\t\tbrow.rotation.z=side*0.05
\t\t_ball(head_pivot,0.014,Vector3(side*0.037,0.100,-0.071),skin_color,Vector3(1.2,0.32,0.8),0.84)
\t_ball(head_pivot,0.013,Vector3(0,0.099,-0.084),skin_color,Vector3(0.55,1.4,0.8),0.83)
\t_ball(head_pivot,0.012,Vector3(0,0.082,-0.093),skin_color.darkened(0.06),Vector3(0.8,0.6,0.8),0.82)
\tvar lips := _box(head_pivot,Vector3(0.036,0.003,0.006),Vector3(0,0.046,-0.066),Color("986958"),0.8)
\tlips.name="Mouth6"


`+s.slice(end);
 s=s.replace('return [shoulder, elbow, hand]','var fingers := _node(hand,Surface6.fingers(),Vector3.ZERO,skin_color,Vector3.ONE,0.84)\n\tfingers.name="Fingers6"\n\tfingers.visibility_range_end=14.0\n\treturn [shoulder, elbow, hand]');
 s=s.replace('var m := StandardMaterial3D.new()\n\tm.albedo_color','var m := StandardMaterial3D.new()\n\tm.metallic_specular = 0.25\n\tm.albedo_color');
 s=s.replace('expression in ["HAPPY","RELIEVED"]','expression in ["HAPPY","RELIEVED","VICTORY"]');
 return s;
});
edit(root+'juego/student_visual.gd',s=>{
 const start=s.indexOf('\t# Silueta');const end=s.indexOf('\tweapon_socket =',start);
 s=s.slice(0,start)+s.slice(end);
 const a=s.indexOf('func _build_head() -> void:');const b=s.indexOf('func equip(',a);
 s=s.slice(0,a)+'func _build_head() -> void:\n\tsuper._build_head()\n\n'+s.slice(b);
 return s;
});
edit(root+'juego/character_appearance.gd',s=>s.replace('const OPTIONS = {','const OPTIONS = {\n\t"face":["Equilibrado","Redondeado","Alargado","Mandíbula definida"],').replace('"Pantalón de trabajo"]','"Pantalón de trabajo","Pantalón deportivo"]').replace('"Audífonos académicos"]','"Audífonos académicos","Gorro liso"]'));
edit(root+'campaign/appearance_menu.gd',s=>s.replace('const LABELS = {','const LABELS = {"face":"Forma del rostro",'));
edit(root+'juego/character_visual_presets.gd',s=>s.replace('raw["body_variant"] =','raw["face"] = absi((id+"face").hash())%4\n\traw["body_variant"] =').replace('for key in ["bottom_style"','for key in ["face","bottom_style"').replace('model.chest.scale.x = width','model.chest.scale.x = width\n\tif not preset.has("face"):\n\t\tvar profile: Dictionary = model.get_meta("appearance_profile",{}).duplicate()\n\t\tprofile.face = absi(str(preset).hash())%4\n\t\tmodel.apply_appearance(profile)'));
console.log('Visual source edits applied');
