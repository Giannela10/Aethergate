extends SceneTree
var checks := 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var c = scene.get_node("CampusCampaign")
	c.persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene); current_scene = scene
	while not c.ready_for_play: await process_frame
	await physics_frame
	check(c.get_node("DuocGames4").lab.get_child_count()>25,"Furnished laboratory")
	check(scene.has_node("Piso3/SalaDetrasLocal/Sala303"),"Existing 303 identity preserved")
	check(c.get_node("DuocGames4").issues.is_empty(),"Educational interaction positions have space and ground")
	check(c.get_node("DuocGames4").laboratories.size()==7,"Six learning laboratories and server room; 304 identity preserved as 304-B")
	var capsule := CharacterBody3D.new(); capsule.collision_mask=1; capsule.collision_layer=0
	var shape := CapsuleShape3D.new(); shape.radius=0.45; shape.height=2.7
	var collision := CollisionShape3D.new(); collision.shape=shape; collision.position.y=1.35; capsule.add_child(collision); root.add_child(capsule)
	for number in ["301","302","304-B","305","306","TÉCNICA"]:
		var room: Node3D=c.get_node("DuocGames4").laboratories[number]
		capsule.global_position=room.to_global(Vector3(0,0.15,-6.5))
		var target: Vector3=room.global_position
		for step in 240:
			await physics_frame
			var offset := target-capsule.global_position; offset.y=0
			if offset.length()<0.4: break
			capsule.velocity=offset.normalized()*4; capsule.velocity.y=-8; capsule.move_and_slide()
		check(Vector2(capsule.global_position.x-target.x,capsule.global_position.z-target.z).length()<0.5,"Walk through lab doorway "+number)
	capsule.queue_free()
	var missions: Node=c.get_node("DuocGames4").missions
	c.player.set_physics_process(false); c.ui.close_modal()
	missions.state.mission_steps["v4_rescue"]=6
	c.events["education_task:v4_rescue"]=6
	c.quests.start_quest("v4_rescue")
	c.player.global_position=missions.rescue_safe
	for frame in 800:
		await physics_frame
		if int(missions.state.mission_steps.get("v4_rescue",0))==7: break
	check(int(missions.state.mission_steps.get("v4_rescue",0))==7,"Student physically exits lab and reaches safe zone")
	check(not missions.rescue_student.is_in_group("enemy"),"Rescued student remains civilian")
	var credits: int=c.data.credits
	missions.advance(missions.CATALOG[0],6)
	check(c.data.credits==credits,"Escort completion cannot repeat reward")
	c.ui.close_modal()
	check(missions.bugs.size()==3,"Three digital mission Bugs placed safely")
	c.quests.start_quest("v4_bugs")
	for bug in missions.bugs:
		bug._refresh(); bug.take_hit(Vector3.ZERO,100)
	check(int(missions.state.mission_steps.get("v4_bugs",0))==1,"Eliminating three digital Bugs advances the mission once")
	c.ui.close_modal()
	while get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await process_frame
	c.player.global_position=c.academic_expansion.actors["profesor_algoritmos"].home
	var zone_view := preload("res://scripts/education/learning_activity_view.gd").new()
	zone_view.activity={"kind":"physical_zone","prompt":"Pregunta de prueba","content":{"options":["Zona uno","Zona dos"]}}
	root.add_child(zone_view)
	var selections: Array=[]; zone_view.answered.connect(func(value): selections.append(value))
	var zones := preload("res://scripts/education/learning_zones_v4.gd").new(); c.add_child(zones)
	check(zones.begin(c,zone_view,zone_view.activity),"Physical answer zones use existing safe arena points")
	zones.pick(1)
	check(selections==[1],"Movement submits only an option, never a client correctness claim")
	zone_view.queue_free()
	var class_student: Node=c.get_node("DuocGames4").routines.actors[-1]
	c.get_node("DuocGames4").routines.set_process(false)
	class_student.sleeping=false; class_student.activity="CLASS"
	for frame in 1000:
		await physics_frame
		if class_student.route_index==3: break
	check(class_student.route_index==3,"Civilian physically enters classroom and reaches chair")
	await physics_frame
	check(class_student.visual.contextual_pose.seated,"Classroom routine uses real procedural seated pose")
	c.data.quests.ubicar_profesores.state=2
	c.get_node("DuocGames4").update_credentials()
	check(c.data.education_v4.credentials.get("coordinacion",false),"Coordinator mission grants an academic credential without requiring another physical duel")
	for duel in get_nodes_in_group("boss_duel"):
		if duel.is_educational_simulation():
			check(duel.simulation != null,"Mentor adapter "+duel.boss_id)
			duel.simulation.begin()
			check(duel.simulation.mentor.is_in_group("educational_mentor") and not duel.simulation.mentor.is_in_group("enemy"),"Mentor never an enemy "+duel.boss_id)
			duel.simulation.reset()
			check(duel.interaction_target()==duel.simulation.mentor,"Teacher conversation targets the mentor, not the hidden simulation actor "+duel.boss_id)
	print("CAMPUS_V4_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"escort_position":str(missions.rescue_student.global_position),"routine_actors":c.get_node("DuocGames4").routines.actors.size(),"audio_streams":c.get_node("DuocGames4").sound.samples.size()}))
	quit(0 if failures.is_empty() else 1)
