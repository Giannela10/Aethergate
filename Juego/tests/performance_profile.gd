extends "res://tests/upper_campus_check.gd"
## Repeat the original rendered fixture; diagnostic ablations are restored immediately.
var profile: Dictionary = {}

func _ready() -> void:
	super._ready()
	profile_run.call_deferred()

func sample_window(seconds: float = 4.0) -> Dictionary:
	await get_tree().create_timer(2.0).timeout
	var samples: Array = []
	for i in range(int(seconds)):
		await get_tree().create_timer(1.0).timeout
		samples.append({"fps":Performance.get_monitor(Performance.TIME_FPS),
			"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,
			"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	return {"samples":samples}

func profile_run() -> void:
	while not finished:
		await get_tree().process_frame
	preview_boss("profesor_ingles")
	profile = {"fixture":"UpperCampusCheck: two Main loads, preview_boss profesor_ingles", "classification":"DESCONOCIDO", "gpu_ms":null}
	profile.baseline = await sample_window()
	var meshes := c.get_parent().find_children("*","MeshInstance3D",true,false)
	var lights := c.get_parent().find_children("*","Light3D",true,false)
	var materials: Dictionary = {}
	var signatures: Dictionary = {}
	var shadows := 0
	var processing := 0
	var physics_processing := 0
	for node in c.get_parent().find_children("*","Node",true,false):
		if node.is_processing(): processing += 1
		if node.is_physics_processing(): physics_processing += 1
	for light in lights:
		if light.shadow_enabled: shadows += 1
	for mesh in meshes:
		var mat = mesh.material_override
		if mat != null:
			materials[mat.get_instance_id()] = true
			if mat is StandardMaterial3D:
				var key := str([mat.albedo_color,mat.roughness,mat.metallic,mat.albedo_texture,mat.emission_enabled])
				signatures[key] = int(signatures.get(key,0))+1
	profile.census = {"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"meshes":meshes.size(),"lights":lights.size(),"shadow_lights":shadows,"navigation_agents":c.get_parent().find_children("*","NavigationAgent3D",true,false).size(),"animation_trees":c.get_parent().find_children("*","AnimationTree",true,false).size(),"skeletons":c.get_parent().find_children("*","Skeleton3D",true,false).size(),"gpu_particles":c.get_parent().find_children("*","GPUParticles3D",true,false).size(),"cpu_particles":c.get_parent().find_children("*","CPUParticles3D",true,false).size(),"unique_override_materials":materials.size(),"approx_material_signatures":signatures.size()}
	profile.census.processing_callbacks = processing
	profile.census.physics_callbacks = physics_processing
	profile.census.character_activity = c.live.floor_activity.counts.duplicate()
	profile.census.chairs = get_tree().get_nodes_in_group("campus_chair").size()
	profile.environment = {"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"viewport":str(get_viewport().get_visible_rect().size),"quality":c.live.settings.data.quality,"shadow_distance":c.get_parent().get_node("SistemasCompartidos/LuzExterior").directional_shadow_max_distance}
	# Disable only character idle visual callers; do not change gameplay or save data.
	var stopped: Array = []
	for node in c.get_parent().find_children("*","Node",true,false):
		if node.is_processing() and (node.get_script() != null) and str(node.get_script().resource_path) in ["res://scripts/campaign/npc.gd","res://scripts/juego/enemy.gd","res://scripts/campaign/academic_boss.gd","res://scripts/campaign/boss_duel_controller.gd"]:
			stopped.append(node)
			node.set_process(false)
	profile.visual_callers_disabled = stopped.size()
	profile.without_character_idle = await sample_window()
	for node in stopped: node.set_process(true)
	var shadow_state: Array = []
	for light in lights:
		shadow_state.append(light.shadow_enabled)
		light.shadow_enabled = false
	profile.without_light_shadows = await sample_window()
	for i in lights.size(): lights[i].shadow_enabled = shadow_state[i]
	var hidden: Array = []
	for mesh in meshes:
		if mesh.visible:
			hidden.append(mesh)
			mesh.hide()
	profile.without_mesh_rendering = await sample_window()
	for mesh in hidden: mesh.show()
	profile.restored = await sample_window()
	var file := FileAccess.open("res://reports/performance_current.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(profile,"\t"))
	print("PERFORMANCE_PROFILE_RESULT ",JSON.stringify(profile))
	await combat_profiles()

func combat_profiles() -> void:
	var results := {}
	for id in ["profesor_ingles","profesor_lenguaje","profesor_etica","director"]:
		var duel = get_tree().get_nodes_in_group("boss_duel").filter(func(d): return d.boss_id == id)[0]
		var actor = duel.actor
		duel.defeated = false; duel.reset_duel(); c.ui.close_modal()
		c.restore_player([actor.home.x+4,actor.home.y,actor.home.z+2],100)
		c.player.set_physics_process(false); c.manager.set_process(false)
		c.manager.cam.global_position = actor.home+Vector3(0,3,7)
		c.manager.cam.look_at(actor.home+Vector3.UP)
		duel.intro_duration = 0.02; duel.interact(c.player); await duel.accept()
		actor.set_physics_process(false)
		actor.target = c.player
		actor.phase = 3
		var timer := Timer.new(); timer.wait_time = 0.8
		timer.timeout.connect(func(): stress_patterns(actor,id))
		add_child(timer); timer.start(); stress_patterns(actor,id)
		results[id] = await sample_window()
		results[id].note = "Synthetic repeated patterns every 0.8 s; not a human duel or before/after comparison"
		timer.stop(); timer.queue_free(); duel.reset_duel()
	var file := FileAccess.open("res://reports/performance_boss_patterns.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("PERFORMANCE_BOSS_RESULT ",JSON.stringify(results))

func stress_patterns(actor: Node, id: String) -> void:
	c.player.health = 10000 # Diagnostic fixture only; no production statistics change.
	if id == "director":
		actor._director_zone("FIREWALL",actor.home,0.8,7)
		actor._director_zone("ACCESO DENEGADO",c.player.global_position,1.5)
		actor._activate_security()
	else:
		var patterns := ["VOCABULARY STORM","WORD RUSH"] if id == "profesor_ingles" else (["TORMENTA DE PÁGINAS","TINTA"] if id == "profesor_lenguaje" else ["DILEMA"])
		for pattern in patterns:
			actor.start_attack(pattern); actor.resolve_attack()
		if id == "profesor_etica" and not actor.choice_started:
			actor.choice_started = true; actor.choices_remaining = 6
			actor.zone("A",actor.home+Vector3(-3,0,0),1.35,0,6,0,"choice",0,Vector3.FORWARD,"A")
			actor.zone("B",actor.home+Vector3(3,0,0),1.35,0,6,0,"choice",0,Vector3.FORWARD,"B")

