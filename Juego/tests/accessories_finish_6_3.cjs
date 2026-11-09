const fs=require('fs'),path=require('path'),cp=require('child_process');
const file='res://scripts/juego/npc_visual_6_3.gd';
const jobs=[
 {tool:'script_edit',arguments:{file_path:file,old_string:'var skin_meshes: Array[MeshInstance3D]=[]',new_string:'var skin_meshes: Array[MeshInstance3D]=[]\nvar eyewear: Array[MeshInstance3D]=[]\nvar eye_rest=Vector3.ZERO'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'if role=="GUARDIA": profile.clothes=2;',new_string:'if role=="GUARDIA": profile.clothes=5;'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'if not keep: mesh.hide();hidden.append(mesh)',new_string:'if keep and mesh.get_parent()==host.head_pivot and ((role=="BIBLIOTECARIA" and mesh.mesh is BoxMesh) or (int(profile.get("accessory",0))==1 and str(mesh.get_meta("visual_module",""))=="ACCESSORY")): eyewear.append(mesh)\n  if not keep: mesh.hide();hidden.append(mesh)'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'update(0.016)\n return true',new_string:'var eyes=model.human.find_children("Eyes","MeshInstance3D",true,false)\n if not eyes.is_empty(): eye_rest=model.rig.to_local(eyes[0].to_global(eyes[0].get_aabb().get_center()))\n update(0.016)\n return true'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'hidden.clear()\n build()',new_string:'hidden.clear();eyewear.clear()\n build()'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'model.update_pose(pose_delta);pose_delta=0',new_string:'model.update_pose(pose_delta);pose_delta=0\n align_eyewear()'}}
];
const content=`
func align_eyewear() -> void:
	if eyewear.is_empty(): return
	var bone=model.rig.find_bone("head")
	var target=model.rig.global_transform*(model.rig.get_bone_global_pose(bone)*model.rig.get_bone_global_rest(bone).affine_inverse()*eye_rest)
	target+=(host.global_basis*Vector3.FORWARD).normalized()*0.025
	var center=Vector3.ZERO
	var count=0
	for part in eyewear:
		if is_instance_valid(part): center+=part.to_global(part.get_aabb().get_center());count+=1
	if count==0: return
	var offset=target-center/float(count)
	for part in eyewear:
		if is_instance_valid(part): part.global_position+=offset
`;
let source=fs.readFileSync('Juego/scripts/juego/npc_visual_6_3.gd','utf8');
for(const job of jobs){if(!source.includes(job.arguments.old_string))throw Error('Missing span '+job.arguments.old_string);source=source.replace(job.arguments.old_string,job.arguments.new_string);}
source=source.replace(/^( +)/gm,s=>'\t'.repeat(s.length))+content;
const output=path.join(__dirname,'accessories_finish_write63.json');fs.writeFileSync(output,JSON.stringify({file_path:file,content:source}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+output],{stdio:'inherit'});
