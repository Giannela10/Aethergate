extends Node3D
var player: Node3D
var running:=false
func _ready() -> void: run.call_deferred()
func _process(delta: float) -> void:
	if running: player.body.animate(delta,Vector3(0,0,-2.5),true,false)
func run() -> void:
	seed(600)
	var out="res://reports/main_character_6_2/"
	var phase=FileAccess.get_file_as_string(out+"phase.txt").strip_edges()
	var campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	player=campaign.player
	for actor in campus.find_children("*","CharacterBody3D",true,false):
		actor.set_process(false)
		actor.set_physics_process(false)
	for layer in campus.find_children("*","CanvasLayer",true,false): layer.hide()
	campaign.set_process(false)
	campaign.manager.set_process(false)
	if phase=="before":
		var previous=player.body
		var model=preload("res://scripts/juego/main_character_visual_6.gd").new()
		model.scale=previous.scale
		model.punch_time=previous.punch_time
		player.add_child(model)
		player.body=model
		previous.get_parent().remove_child(previous)
		previous.free()
	player.body.apply_appearance(preload("res://scripts/juego/character_appearance.gd").normalize({"top":1,"bottom_style":1,"clothes":0,"pants":0,"shoes":6,"hair_color":1,"backpack":1,"backpack_color":5}))
	player.set_meta("important_scene",true)
	player.global_position=Vector3(8,0.14,-45)
	var camera=Camera3D.new()
	add_child(camera)
	camera.global_position=player.global_position+Vector3(1.8,1.7,-4.2)
	camera.look_at(player.global_position+Vector3.UP*1.4)
	camera.fov=45
	camera.make_current()
	running=true
	await get_tree().create_timer(3.0).timeout
	var samples=[]
	var last=Time.get_ticks_usec()
	for i in 180:
		await RenderingServer.frame_post_draw
		var now=Time.get_ticks_usec()
		samples.append({"frame_ms":float(now-last)/1000.0,"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"fps":Performance.get_monitor(Performance.TIME_FPS),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		last=now
	var f=FileAccess.open(out+phase+"_animated_performance.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"phase":phase,"warmup_seconds":3,"samples":samples,"method":"Animated walk-in-place in Main, fixed camera at campus entrance, real visual.animate() every frame, NPC physics/process frozen; 75Hz cap."},"\t"))
	f.close()
	print("ANIMATED_BENCHMARK62_DONE ",phase)
