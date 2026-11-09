extends Node3D
const OUT := "res://reports/characters_6_0"
func _ready() -> void: run.call_deferred()
func run() -> void:
	var campus = load("res://Main.tscn").instantiate()
	var campaign = campus.get_node("CampusCampaign")
	campaign.persist=false
	campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	campaign.ui.close_modal()
	for actor in campus.find_children("*","CharacterBody3D",true,false): actor.process_mode=Node.PROCESS_MODE_DISABLED
	var layer_states := {}
	for layer in campus.find_children("*","CanvasLayer",true,false):
		layer_states[layer]=layer.visible
		layer.hide()
	campaign.manager.set_process(false)
	var camera := Camera3D.new()
	camera.fov=60
	camera.near=0.03
	add_child(camera)
	camera.make_current()
	var rows: Array = []
	for visual in get_tree().get_nodes_in_group("campus_character_visual"):
		var row := {"path":str(campus.get_path_to(visual)),"visible":visual.is_visible_in_tree(),"script":visual.get_script().resource_path,"profile":visual.get_meta("appearance_profile",{}),"meshes":visual.find_children("*","MeshInstance3D",true,false).size()}
		if visual.is_visible_in_tree():
			var target: Vector3 = visual.head_pivot.global_position+Vector3(0,0.1,0)
			camera.global_position=target-visual.global_basis.z.normalized()*0.95+Vector3(0,0.06,0)
			camera.look_at(target)
			await get_tree().create_timer(0.12).timeout
			await RenderingServer.frame_post_draw
			var filename: String = "campus_"+str(rows.size())+".png"
			get_viewport().get_texture().get_image().save_png(OUT+"/"+filename)
			row["capture"]=filename
		rows.append(row)
	var equipment := {"collected":false,"personal_saves_used":false}
	for weapon in get_tree().get_nodes_in_group("weapon_pickup"):
		if weapon.get("durability") == null or weapon.durability<=0: continue
		if campaign.player.inventory.collect_weapon(weapon,true):
			for i in 20: campaign.player.body.animate(0.016,Vector3.ZERO,true,false)
			var hand: Vector3=campaign.player.body.hand_r.global_position
			camera.global_position=hand+Vector3(0.8,0.3,-0.8)
			camera.look_at(hand)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(OUT+"/campus_equipped_hand.png")
			equipment.collected=true
			equipment["socket_parent"]=str(campaign.player.weapon.get_parent().get_path())
			break
	var equipment_file := FileAccess.open(OUT+"/equipment_check.json",FileAccess.WRITE)
	equipment_file.store_string(JSON.stringify(equipment,"\t"));equipment_file.close()
	# Normal gameplay view and the real menu reuse their existing cameras/viewport.
	campaign.manager.cam.make_current()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"/campus_game_camera.png")
	for layer in layer_states: layer.visible=layer_states[layer]
	campaign.show_personalization()
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+"/campus_personalization.png")
	var file := FileAccess.open(OUT+"/campus_census.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(rows,"\t"))
	file.close()
	print("CHARACTERS60_CAMPUS_DONE ",rows.size())
