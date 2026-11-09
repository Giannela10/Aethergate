extends SceneTree
var scene: Node
var c: Node
var samples: Array = []
var phase := 0
var frame := 0
var measurements: Array = []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	scene=load("res://Main.tscn").instantiate(); c=scene.get_node("CampusCampaign"); c.persist=false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	root.add_child(scene); current_scene=scene
	while not c.ready_for_play: await process_frame
	c.ui.close_modal(); c.player.global_position=Vector3(0,0.2,-140); c.player.set_physics_process(false)
	c.live.director.enabled=false
	c.set_process(false)
	c.get_node("DuocGames4").routines.set_process(false)
	for actor in c.get_node("DuocGames4").routines.actors: actor.set_physics_process(false)
	c.manager.cam.global_position=Vector3(0,3.5,-135)
	c.manager.cam.look_at(Vector3(0,1.5,-140),Vector3.UP)
	c.manager.set_process(false)
	c.get_node("DuocGames4").performance.set_enabled(false)
	var runs: Array=[]
	for enabled in [false,true,true,false,false,true]:
		c.get_node("DuocGames4").performance.set_enabled(enabled)
		for warmup in 60: await process_frame
		samples.clear()
		for sample in 90:
			await process_frame
			samples.append({"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)})
		var cpu := 0.0; var calls := 0.0
		for item in samples: cpu+=item.cpu_ms; calls+=item.draw_calls
		runs.append({"optimization":enabled,"cpu_process_ms":cpu/90,"draw_calls":calls/90,"static_memory_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,"renderer":DisplayServer.get_name(),"resolution":str(root.size),"position":[0,0.2,-140]})
	for enabled in [false,true]:
		var selected: Array=runs.filter(func(item): return item.optimization==enabled)
		var aggregate: Dictionary=selected[0].duplicate(true)
		for key in ["cpu_process_ms","draw_calls","static_memory_mib"]:
			var total := 0.0
			for item in selected: total+=float(item[key])
			aggregate[key]=total/selected.size()
		measurements.append(aggregate)
	var report := {"checks":6,"failures":[],"measurements":measurements,"runs":runs,"fps_claim":false,"batched_meshes":c.get_node("DuocGames4").performance.batched_meshes,"scope":"Three A/B pairs with camera, civilian routes and game clock frozen; not an original-project baseline or a constant FPS guarantee"}
	var file := FileAccess.open("res://reports/v4_performance.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t")); file.close()
	if DisplayServer.get_name()!="headless": root.get_texture().get_image().save_png("res://reports/v4_campus.png")
	print("PERFORMANCE_V4_RESULT ",JSON.stringify(report)); quit()
