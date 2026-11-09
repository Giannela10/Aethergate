const fs=require('fs'),path=require('path'),cp=require('child_process');
const source='Juego/tests/npc_validation_6_3.gd';
let code=fs.readFileSync(source,'utf8');
code=code.replace('visual.lod_level=0;visual.activity_level=0','visual.lod_level=0;visual.activity_level=0;visual.lod_tick=0;visual.update_visual_lod(1)');
// Keep authored contexts visible when capturing the first frame after a floor visit.
code=code.replace('var rows=[]','var rows=[]\n for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()');
code=code.replace('for state in ["walk","run","crouch","attack","read","computer"]:', 'for state in ["walk","run","crouch","attack","read","computer","talk","sit","stand","write","celebrate"]:');
code=code.replace('if state=="attack": visual.start_punch()', 'if state=="attack": visual.start_punch()\n   if state in ["talk","write","celebrate"]: visual.set_visual_activity({"talk":"EXPLAIN","write":"WRITE","celebrate":"CELEBRATE"}[state])\n   if state=="sit": visual.contextual_pose.seated=true;visual.contextual_pose.seat_height=0.55\n   if state=="stand": visual.contextual_pose.seated=false');
code=code.replace('var pose=skeleton.get_bone_global_pose(skeleton.find_bone(label))','var pose=skeleton.get_bone_global_pose(skeleton.find_bone(label))');
code=code.replace(/^( +)/gm,s=>'\t'.repeat(s.length));
const file=path.join(__dirname,'validation_write63.json');fs.writeFileSync(file,JSON.stringify({file_path:'res://tests/npc_validation_6_3.gd',content:code}));
cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+file],{stdio:'inherit'});
