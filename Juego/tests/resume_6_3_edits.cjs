// Apply visual changes through the project-scoped Godot MCP bridge.
const fs=require('fs'),path=require('path'),cp=require('child_process');
const file='res://scripts/juego/npc_visual_6_3.gd';
const jobs=[{tool:'script_edit',arguments:{file_path:file,edits:[
 {old_string:'if role=="ODONTOLOGIA": model.wardrobe="clothing_trenchcoat"',new_string:'if role=="ODONTOLOGIA": model.wardrobe="clothing_shirt" # Trenchcoat intersects the clinical teaching pose.'},
 {old_string:'var interval=0.0 if distance<12 else 0.12 if distance<28 else 0.40',new_string:'var interval=1.0/30.0 if distance<12 else 0.12 if distance<28 else 0.40'},
 {old_string:'if tick<interval: return',new_string:'if tick+0.00001<interval: return'}
]} }];
const expanded=jobs.flatMap(job=>job.arguments.edits.map(edit=>({tool:job.tool,arguments:{file_path:job.arguments.file_path,...edit}})));
const out=path.join(__dirname,'resume_6_3_jobs.json');fs.writeFileSync(out,JSON.stringify(expanded,null,2));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',out],{stdio:'inherit'});
