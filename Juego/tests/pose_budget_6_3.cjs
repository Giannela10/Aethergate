const fs=require('fs'),path=require('path'),cp=require('child_process');
const jobs=[
 {tool:'script_edit',arguments:{file_path:'res://scripts/juego/human_npc_6_3.gd',old_string:'\trig.force_update_all_bone_transforms()',new_string:'\t# Skeleton3D flushes the local pose changes once before rendering.'}},
 {tool:'script_edit',arguments:{file_path:'res://scripts/juego/npc_visual_6_3.gd',old_string:'var interval=1.0/30.0 if distance<12 else 0.12 if distance<28 else 0.40',new_string:'var interval=1.0/30.0 if distance<4 else 1.0/15.0 if distance<10 else 0.12 if distance<28 else 0.40'}},
 {tool:'script_edit',arguments:{file_path:'res://scripts/juego/npc_visual_6_3.gd',old_string:'host.set_meta("npc63_distant",distance>16)',new_string:'host.set_meta("npc63_distant",distance>8)'}}
];
const file=path.join(__dirname,'pose_budget_jobs63.json');fs.writeFileSync(file,JSON.stringify(jobs));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',file],{stdio:'inherit'});
