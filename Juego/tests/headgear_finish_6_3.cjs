const fs=require('fs'),path=require('path'),cp=require('child_process');
const target='Juego/scripts/juego/npc_visual_6_3.gd';let code=fs.readFileSync(target,'utf8');
code=code.replace('var eyewear: Array[MeshInstance3D]=[]','var eyewear: Array[MeshInstance3D]=[]\nvar headgear: Array[MeshInstance3D]=[]');
code=code.replace('\t\tif role=="GUARDIA" and mesh.material_override', '\t\tvar appearance=host.get("appearance_adapter")\n\t\tif appearance!=null and mesh in appearance.extras and str(mesh.get_meta("visual_module",""))=="":\n\t\t\tif mesh.get_parent()==host.head_pivot and int(profile.get("accessory",0)) in [2,4]: keep=true\n\t\t\tif mesh.get_parent()==host.chest and int(profile.get("accessory",0)) in [5,6,8]: keep=true\n\t\tif role=="GUARDIA" and mesh.material_override');
code=code.replace('\t\tif not keep: mesh.hide();hidden.append(mesh)','\t\tif keep and mesh.get_parent()==host.head_pivot and (str(mesh.get_meta("visual_module",""))=="HEAD_ACCESSORY" or int(profile.get("accessory",0))==4): headgear.append(mesh)\n\t\tif not keep: mesh.hide();hidden.append(mesh)');
code=code.replace('hidden.clear();eyewear.clear()','hidden.clear();eyewear.clear();headgear.clear()');
code=code.replace('\talign_eyewear()','\talign_eyewear()\n\talign_headgear()');
code+=`
func align_headgear() -> void:
	if headgear.is_empty(): return
	var bone=model.rig.find_bone("head")
	var eyes=model.rig.global_transform*(model.rig.get_bone_global_pose(bone)*model.rig.get_bone_global_rest(bone).affine_inverse()*eye_rest)
	var unit=model.rig.global_basis.get_scale().y
	var center=eyes-(host.global_basis*Vector3.FORWARD).normalized()*0.065*unit
	var bounds=AABB()
	var first=true
	for part in headgear:
		if not is_instance_valid(part): continue
		var box=part.global_transform*part.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	if first: return
	var offset=center-bounds.get_center()
	offset.y=eyes.y+0.035*unit-bounds.get_center().y if int(profile.get("head_accessory",0))==1 else eyes.y+0.095*unit-bounds.position.y
	for part in headgear:
		if is_instance_valid(part): part.global_position+=offset
`;
const job=path.join(__dirname,'headgear_finish_write63.json');fs.writeFileSync(job,JSON.stringify({file_path:'res://scripts/juego/npc_visual_6_3.gd',content:code}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
