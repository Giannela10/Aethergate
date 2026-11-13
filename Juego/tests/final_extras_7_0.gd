extends Node
var f: Node
var c: Node
var p: CharacterBody3D
var out: String
var rows=[]
func install(parent: Node) -> String:
	f=parent;c=f.campaign;p=f.player;out=f.out+"refined/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	parent.add_child(self);run.call_deferred();return "FINAL70_EXTRAS_STARTED"
func record(label: String, passed: bool, detail: Variant=null) -> void:
	rows.append({"test":label,"passed":passed,"detail":detail})
	var file=FileAccess.open(out+"extra_checks.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"\t"))
	print("FINAL70_EXTRA ",label," ",passed)
func run() -> void:
	record("talk_requirement_satisfied",c.quests.progress({"kind":"talk","id":"punto","amount":1})>=1,{"events":c.events.get("talk:punto",0),"note":"Requirement saturates at 1; repeat conversations may increment raw events"})
	await wall_check()
	await ramp()
	await f.shot("refined_auditorium_actual_interior",Vector3(64,13,-110),Vector3(47,10,-104.5))
	await f.shot("refined_auditorium_stage_to_seats",Vector3(48,11,-104.5),Vector3(67,13,-104.5))
	await f.shot("refined_basement_core_locked_overview",c.final_area.global_position+Vector3(0,3,-13),c.final_area.global_position+Vector3(0,1,0))
	await locomotion_measure()
	npc_inventory()
	await save_check()
	var file=FileAccess.open(out+"extras_done.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":rows.size(),"failures":rows.filter(func(r): return not r.passed)},"\t"))
	print("FINAL70_EXTRAS_DONE")
func wall_check() -> void:
	var duel=f.campus.get_node("Piso1/SalaAyudaEstudiantil/BossAyudaEstudiantil/BossDuelController")
	var target=duel.simulation.mentor
	var old_position=target.global_position
	target.global_position=duel.spawn_position
	p.global_position=target.global_position+Vector3(0,0,1.6)
	var scanner=p.get_node("InteractionController")
	await get_tree().physics_frame
	record("paired_capsule_does_not_block_mentor",scanner.can_reach_target(duel))
	var wall=StaticBody3D.new();f.add_child(wall)
	wall.global_position=target.global_position+Vector3(0,1.2,0.8)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(3,2.5,0.15);shape.shape=box;wall.add_child(shape)
	await get_tree().physics_frame;await get_tree().physics_frame
	record("solid_wall_still_blocks_mentor",not scanner.can_reach_target(duel))
	wall.queue_free();target.global_position=old_position
func ramp() -> void:
	var ray=PhysicsRayQueryParameters3D.create(Vector3(24.37,2,-124),Vector3(24.37,-15,-124))
	ray.exclude=[p.get_rid()]
	var hit=p.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty(): record("ramp_surface_found",false);return
	record("ramp_surface_found",true,{"position":str(hit.position),"collider":str(hit.collider.get_path())})
	var helper=f.get_children().filter(func(n): return n.get_script()!=null and n.get_script().resource_path.ends_with("final_probe_7_0.gd"))[0]
	var before=helper.rows.size()
	await helper.walk(hit.position+Vector3.UP*0.12,Vector3(24.37,-6,-138),"refined_ramp_from_actual_surface",10)
	if helper.rows.size()>before: record("ramp_actual_walk",helper.rows[-1].passed,helper.rows[-1].detail)
func locomotion_measure() -> void:
	c.ui.close_modal();p.busy=false;p.dead=false;p.body.show()
	p.global_position=Vector3(4,0.14,-48);p.velocity=Vector3.ZERO;p.cam_yaw=0
	p.set_process(true);p.set_physics_process(true)
	c.manager.cam_yaw=0;c.manager.cam.make_current();c.manager.set_process(true)
	await get_tree().create_timer(0.5).timeout
	var socket=p.body.weapon_socket
	var equipped=false
	for entry in p.inventory.entries:
		if p.inventory.equip_entry(entry.uid): equipped=true;break
	record("inventory_socket_identity",p.body.weapon_socket==socket and socket.is_inside_tree(),{"equipped":equipped})
	for state in ["walk","run"]:
		Input.action_press("move_forward")
		if state=="run": Input.action_press("run")
		var samples=[]
		for i in 40:
			await get_tree().create_timer(0.1).timeout
			var model=p.body.human62
			var shoe: MeshInstance3D=model.footwear63.mesh
			await RenderingServer.frame_post_draw
			var baked=shoe.bake_mesh_from_current_skeleton_pose()
			var box=shoe.global_transform*baked.get_aabb()
			var ray=PhysicsRayQueryParameters3D.create(box.get_center()+Vector3.UP,box.get_center()-Vector3.UP*3)
			ray.exclude=[p.get_rid()]
			var hit=p.get_world_3d().direct_space_state.intersect_ray(ray)
			var feet={}
			for side in ["l","r"]:
				var lowest=INF
				for surface in baked.get_surface_count():
					var vertices=baked.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
					var original=shoe.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
					for vertex in vertices.size():
						if (original[vertex].x>0)!=(side=="l"): continue
						lowest=minf(lowest,(shoe.global_transform*vertices[vertex]).y)
				var ankle=model.rig.global_transform*model.rig.get_bone_global_pose(model.rig.find_bone("foot_"+side)).origin
				var ground_ray=PhysicsRayQueryParameters3D.create(ankle+Vector3.UP*0.5,ankle-Vector3.UP*0.8);ground_ray.exclude=[p.get_rid()]
				var surface_hit=p.get_world_3d().direct_space_state.intersect_ray(ground_ray)
				feet[side]={"sole_y":lowest,"floor_y":surface_hit.position.y if not surface_hit.is_empty() else null,"render_y":preload("res://scripts/juego/character_ground_6_3.gd").height_at(model,ankle,surface_hit.position.y) if not surface_hit.is_empty() else null,"swing":cos(p.body.phase)*(1.0 if side=="l" else -1.0)>0}
			samples.append({"position":str(p.global_position),"speed":Vector2(p.velocity.x,p.velocity.z).length(),"state":p.body.visual_state,"lowest_sole_y":box.position.y,"ground_y":hit.position.y if not hit.is_empty() else null,"feet":feet,"socket_finite":socket.global_transform.is_finite()})
			if i%8==0: get_viewport().get_texture().get_image().save_png(out+"verified_"+state+"_%02d.png"%i)
		Input.action_release("move_forward");Input.action_release("run")
		record("continuous_4s_"+state,samples.all(func(s): return s.socket_finite),{"samples":samples,"note":"Real controller; finite sockets asserted. Sole clearance separately measured, not blanket approved."})
		await get_tree().create_timer(0.4).timeout
	p.set_process(false);p.set_physics_process(false);c.manager.set_process(false);p.body.hide();f.camera.make_current()
func npc_inventory() -> void:
	var inventory=[]
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		var y=visual.global_position.y
		if not (absf(y)<4 or absf(y-12.058385849)<4 or absf(y+12.058385849)<4): continue
		if not visual.is_visible_in_tree(): continue
		var model=visual.get("human62")
		var adapter=visual.get("human_visual63")
		if model==null and adapter!=null: model=adapter.model
		inventory.append({"path":str(visual.get_path()),"position":str(visual.global_position),"scale":str(visual.global_basis.get_scale()),"policy_height":visual.get_meta("standard_human_height",null),"profile":visual.get_meta("appearance_profile",{}),"bones":model.rig.get_bone_count() if model!=null else 0})
	var file=FileAccess.open(out+"npc_selected_floors.json",FileAccess.WRITE);file.store_string(JSON.stringify(inventory,"\t"))
	record("npc_inventory_scoped",not inventory.is_empty(),{"count":inventory.size(),"note":"Visible runtime instances only; no exhaustive dialogue or floor contact assertion"})
func save_check() -> void:
	var expected={"credits":c.data.credits,"xp":c.data.xp,"quests":c.data.quests.duplicate(true),"collected":c.data.collected.duplicate(true)}
	var before_path=c.save_path
	c.save_path=out+"isolated_campaign_verified.json";c.persist=true;c.save_game();c.persist=false
	var restored=preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(c.save_path)
	var normalized=preload("res://scripts/live/save_migration.gd").migrate(restored)
	var actual={"credits":normalized.credits,"xp":normalized.xp,"quests":normalized.quests,"collected":normalized.collected}
	var valid=JSON.parse_string(JSON.stringify(expected))==JSON.parse_string(JSON.stringify(actual))
	record("save_semantic_roundtrip",valid,{"expected":expected,"actual":actual,"note":"Compare JSON values, allowing numeric deserialization; real local save writer, reader and migration"})
	var credits=normalized.credits;var xp=normalized.xp
	c.data=normalized;c.quests.refresh()
	record("reload_no_duplicate_rewards",c.data.credits==credits and c.data.xp==xp)
	c.save_path=before_path
func transition_checks() -> void:
	var helper=f.get_children().filter(func(n): return n.get_script()!=null and n.get_script().resource_path.ends_with("final_probe_7_0.gd"))[0]
	for route in [
		["stairs_minus1_to_1",Vector3(-21.8,-11.9,-127.8),Vector3(20.4,0,-127.8),0.0],
		["stairs_1_to_2",Vector3(-21.8,0.15,-127.8),Vector3(20.4,12.058385849,-127.8),12.058385849],
		["stairs_2_to_1",Vector3(20.4,12.2,-127.8),Vector3(-21.8,0,-127.8),0.0],
		["ramp_full_exit",Vector3(24.37,-11.9,-114),Vector3(24.37,0,-166),0.0]]:
		var count=helper.rows.size()
		await helper.walk(route[1],route[2],route[0],28)
		var reached=helper.rows.size()>count and helper.rows[-1].passed
		record(route[0]+"_arrival_height",reached and absf(p.global_position.y-route[3])<0.6,{"end":str(p.global_position),"expected_y":route[3],"route":helper.rows[-1] if helper.rows.size()>count else null})
	var file=FileAccess.open(out+"transitions_done.json",FileAccess.WRITE);file.store_string(JSON.stringify({"rows":rows.filter(func(r): return r.test.ends_with("_arrival_height"))},"\t"))
	print("FINAL70_TRANSITIONS_DONE")
