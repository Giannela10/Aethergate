const fs=require('fs'),path=require('path'),cp=require('child_process');const file='Juego/tests/capstone_education_tests.gd';
let code=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
code=code.replace('if safe!=null and absf(safe.y-target.global_position.y)<0.7: break','if safe!=null and absf(safe.y-target.global_position.y)<0.7:\n\t\t\t\tplayer.global_position=safe;player.velocity=Vector3.ZERO\n\t\t\t\tawait get_tree().physics_frame\n\t\t\t\tif player.get_node("InteractionController").can_reach_target(duel): break\n\t\t\tsafe=null');
code=code.replace('var reachable=player._can_reach(target)','var reachable=player.get_node("InteractionController").can_reach_target(duel)');
code=code.replaceAll('press("ACTIVIDAD DEL DOCENTE") or press("EVALUACIÓN INTEGRADORA")','press("ACTIVIDAD DEL DOCENTE") or press("EVALUACIÓN INTEGRADORA") or press("ACTIVIDAD DE REDES")');
const job=path.join(__dirname,'fix_capstone_teacher_test.json');fs.writeFileSync(job,JSON.stringify({file_path:'res://tests/capstone_education_tests.gd',content:code}));cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
