const fs=require('fs'),path=require('path'),cp=require('child_process');
const file='res://tests/npc_validation_6_3.gd';
const jobs=[{tool:'script_edit',arguments:{file_path:file,old_string:'row["poses"]={}',new_string:'row["poses"]={}\n\t\trow["anatomy_valid"]=true'}},
{tool:'script_edit',arguments:{file_path:file,old_string:'row.poses[state]=bones',new_string:'row.poses[state]=bones\n\t\t\tvar head_y=skeleton.get_bone_global_pose(skeleton.find_bone("head")).origin.y\n\t\t\tvar foot_y=minf(skeleton.get_bone_global_pose(skeleton.find_bone("foot_l")).origin.y,skeleton.get_bone_global_pose(skeleton.find_bone("foot_r")).origin.y)\n\t\t\tif head_y-foot_y<0.45 or head_y-foot_y>2.5: row.anatomy_valid=false'}}];
const output=path.join(__dirname,'anatomy_validation_jobs63.json');fs.writeFileSync(output,JSON.stringify(jobs));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'run',output],{stdio:'inherit'});
