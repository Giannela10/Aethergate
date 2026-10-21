extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,900)
	root.position=Vector2i(-32000,-32000)
	var campus=load("res://Main.tscn").instantiate()
	for n in campus.find_children("*","",true,false):
		if n.get_script()!=null: n.set_script(null)
	campus.set_script(null)
	root.add_child(campus)
	var door=campus.get_node("Piso1/InteriorCoordinacion/SalaReuniones/PuertaVidrio")
	door.get_node("HojaIzquierda").position.x=-2.05
	door.get_node("HojaDerecha").position.x=2.05
	var cam=Camera3D.new()
	cam.fov=76
	campus.add_child(cam)
	cam.make_current()
	var views=[
		[Vector3(70.2,2.8,-107),Vector3(78,2,-101),"coordinacion_meeting_room.png"],
		[Vector3(69.5,3,-101.6),Vector3(48,1.8,-101),"coordinacion_open_office.png"]]
	for view in views:
		cam.position=view[0]
		cam.look_at(view[1])
		for i in range(15): await process_frame
		await RenderingServer.frame_post_draw
		var error=root.get_texture().get_image().save_png("res://reports/"+view[2])
		print("COORD_PREVIEW ",view[2]," error=",error)
	quit()
