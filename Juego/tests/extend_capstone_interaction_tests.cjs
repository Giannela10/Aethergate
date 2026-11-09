const fs=require('fs'),path=require('path'),cp=require('child_process');const file='Juego/tests/capstone_education_tests.gd';
let code=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
code=code.replace('\t\tduel.interact(player)\n\t\tawait get_tree().process_frame',`		if id=="profesor_datos":
			player.set_physics_process(false)
			var wall=StaticBody3D.new();var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(0.4,2,0.4);col.shape=shape;wall.add_child(col);add_child(wall)
			wall.global_position=(player.global_position+target.global_position)*0.5+Vector3.UP*1.2
			await get_tree().physics_frame;await get_tree().physics_frame
			check(not player.get_node("InteractionController").can_reach_target(duel),"Wall still blocks educational interaction")
			wall.queue_free();await get_tree().physics_frame;await get_tree().physics_frame
			check(player.get_node("InteractionController").can_reach_target(duel),"Reach recovers after temporary wall removed")
			player.set_physics_process(true)
		duel.interact(player)
		await get_tree().process_frame`);
const old='\t\tcampaign.ui.close_modal();duel.decline()\n\t\tteacher_rows.append';
if(!code.includes(old))throw Error('Expected span missing');
code=code.replace(old,`		campaign.ui.close_modal();duel.decline()
		var old_position=target.global_position
		var old_player_position=player.global_position
		var moved=player.get_node("SeatController").safe_position(old_position+Vector3(6,0,0))
		if moved!=null and absf(moved.y-old_position.y)<0.5:
			target.global_position=moved
			var approach=player.get_node("SeatController").safe_position(moved+Vector3(0,0,2))
			if approach!=null: player.global_position=approach
		duel.defeated=true;duel.state=duel.DuelState.DEFEATED
		check(not duel.interaction_text(player).is_empty(),"Completed teacher retains education prompt "+id)
		player.get_node("InteractionController").scan()
		check(player.get_node("InteractionController").selected==duel,"Visible mentor selected after relocation "+id)
		duel.interact(player);await get_tree().process_frame
		check(press("ACTIVIDAD DEL DOCENTE") or press("ACTIVIDAD DE REDES"),"Practice available after completed simulation "+id)
		await get_tree().process_frame
		campaign.ui.close_modal();duel.decline();duel.defeated=false
		target.global_position=old_position;player.global_position=old_player_position
		teacher_rows.append`);
const job=path.join(__dirname,'extend_capstone_interaction_tests.json');fs.writeFileSync(job,JSON.stringify({file_path:'res://tests/capstone_education_tests.gd',content:code}));cp.execFileSync(process.execPath,[path.join(__dirname,'visual_mcp_5.cjs'),'script_write','@'+job],{stdio:'inherit'});
