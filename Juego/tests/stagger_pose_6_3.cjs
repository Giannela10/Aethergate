const fs=require('fs'),path=require('path'),cp=require('child_process');
const file='res://scripts/juego/npc_visual_6_3.gd';
const jobs=[
 {tool:'script_edit',arguments:{file_path:file,old_string:'var tick=0.0',new_string:'var tick=0.0\nvar pose_delta=0.0'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'adapter.name="HumanVisual63";adapter.host=visual;adapter.identity=id;adapter.role=kind',new_string:'adapter.name="HumanVisual63";adapter.host=visual;adapter.identity=id;adapter.role=kind\n adapter.tick=float(absi(id.hash())%1000)/30000.0'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'tick+=delta',new_string:'tick+=delta;pose_delta+=delta'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'model.update_pose(tick);tick=0',new_string:'model.update_pose(pose_delta);pose_delta=0\n tick=fmod(tick,interval)'}},
 {tool:'script_edit',arguments:{file_path:file,old_string:'mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if distance<22 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF',new_string:'mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if distance<16 and host.cast_near_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF'}}
];
const job=path.join(__dirname,'stagger_pose_jobs63.json');fs.writeFileSync(job,JSON.stringify(jobs));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',job],{stdio:'inherit'});
