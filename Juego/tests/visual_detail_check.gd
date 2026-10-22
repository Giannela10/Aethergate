extends SceneTree
var failures: Array[String] = []
var captures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://reports/detail_"+name_value+".png"
	var error := root.get_texture().get_image().save_png(path)
	if error != OK: failures.append("Cannot capture "+name_value)
	else: captures.append(path)

func run() -> void:
	DisplayServer.window_set_size(Vector2i(1152,648))
	var shell = load("res://tests/roles_shell_fixture.gd").new()
	shell.name = "Login"
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shell)
	await capture("login")
	shell._account_form(true)
	await capture("registration")
	shell.preview_resolution(800,600)
	await capture("registration_800x600")
	var card = shell.find_child("MenuCard",true,false)
	if card != null and card.get_global_rect().end.x > root.size.x:
		failures.append("Registration card exceeds viewport width")
	shell.preview_resolution(1152,648)
	shell.auth.sign_as(shell.auth.client.ADMIN)
	shell._route()
	await capture("admin_dashboard")
	shell.auth.sign_as(shell.auth.client.OTHER)
	shell._route()
	await capture("teacher_dashboard")
	shell.queue_free()
	await process_frame
	var campus = load("res://Main.tscn").instantiate()
	for node in campus.find_children("*","",true,false):
		if node.get_script() != null: node.set_script(null)
	campus.set_script(null)
	root.add_child(campus)
	for camera_node in campus.find_children("*","Camera3D",true,false):
		camera_node.current = false
	var camera := Camera3D.new()
	campus.add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 50
	# Remove upper floors from the diagnostic view, without saving any changes.
	for index in range(3,9): campus.get_node("Piso"+str(index)).hide()
	var library = campus.get_node("Piso2/Biblioteca")
	for node in library.find_children("*","GeometryInstance3D",true,false):
		if "Cielo" in str(node.name) or "Techo" in str(node.name): node.hide()
	camera.global_position = Vector3(-65,23,-104)
	camera.look_at(Vector3(-65,12,-104),Vector3.FORWARD)
	await capture("library_overview")
	var stations: Array = []
	for pc in library.get_node("PuestosComputadores").get_children():
		stations.append({"name":str(pc.name),"position":str(pc.global_position),"facing":str((pc.get_node("Monitor").global_position-pc.get_node("Silla").global_position).normalized())})
	print("LIBRARY_CURRENT_STATIONS ",JSON.stringify(stations))
	campus.get_node("Piso2").hide()
	var office = campus.get_node("Piso1/InteriorCoordinacion")
	for node in office.find_children("*","GeometryInstance3D",true,false):
		if "Cielo" in str(node.name) or "Techo" in str(node.name): node.hide()
	camera.size = 55
	camera.global_position = Vector3(59,10,-107)
	camera.look_at(Vector3(59,0,-107),Vector3.FORWARD)
	await capture("coordination_overview")
	print("VISUAL_DETAIL_RESULT ",JSON.stringify({"failures":failures,"captures":captures,"backend":"in-memory fixtures; no real session used"}))
	quit(0 if failures.is_empty() else 1)
