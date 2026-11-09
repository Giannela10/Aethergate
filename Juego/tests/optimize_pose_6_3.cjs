const fs=require('fs'),path=require('path'),cp=require('child_process');
const target='Juego/scripts/juego/human_npc_6_3.gd';
let code=fs.readFileSync(target,'utf8').replace(/^( +)/gm,s=>'\t'.repeat(s.length));
if(code.includes('var pose_names:'))throw Error('Optimization already installed');
code+=`
var pose_names: Array[String]=[]
var pose_parents: Array[int]=[]
var pose_rests: Array[Transform3D]=[]
var inverse_rests: Array[Transform3D]=[]
func initialize(owner_visual: Node3D) -> bool:
	if not super.initialize(owner_visual): return false
	for bone in rig.get_bone_count():
		pose_names.append(rig.get_bone_name(bone))
		pose_parents.append(rig.get_bone_parent(bone))
		pose_rests.append(rig.get_bone_rest(bone))
		inverse_rests.append(rig.get_bone_rest(bone).affine_inverse())
	return true
`;
let solver=fs.readFileSync('Juego/scripts/juego/human_student_6_2.gd','utf8').split('func update_pose(delta: float) -> void:')[1];
solver=solver.slice(0,solver.indexOf('\n\tvar blink='));
solver=solver.replace('\tvar poses: Array[Transform3D]=[]','\tvar poses: Array[Transform3D]=[]\n\tvar rig_inverse=rig.global_basis.inverse()\n\tvar to_rig=rig.global_transform.affine_inverse()');
solver=solver.replaceAll('rig.get_bone_count()','pose_names.size()').replaceAll('rig.get_bone_parent(i)','pose_parents[i]').replaceAll('rig.get_bone_rest(i)','pose_rests[i]').replaceAll('rig.get_bone_name(i)','pose_names[i]').replaceAll('rig.global_basis.inverse()*','rig_inverse*').replaceAll('rig.to_local(host.hips.global_position)','to_rig*host.hips.global_position');
solver=solver.replace('\tfor i in poses.size(): rig.set_bone_global_pose_override(i,poses[i],1.0,true)',`	# Apply local poses in hierarchy order, then flush once. Global overrides
	# force repeated hierarchy updates in the Compatibility renderer.
	for i in poses.size():
		var local=poses[i] if pose_parents[i]<0 else poses[pose_parents[i]].affine_inverse()*poses[i]
		rig.set_bone_pose(i,inverse_rests[i]*local)
	rig.force_update_all_bone_transforms()`);
code+='\nfunc update_pose(delta: float) -> void:'+solver+'\n';
const job=path.join(__dirname,'optimized_pose_jobs63.json');
fs.writeFileSync(job,JSON.stringify({file_path:'res://scripts/juego/human_npc_6_3.gd',content:code}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
