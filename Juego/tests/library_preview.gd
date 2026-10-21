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
	var cam=Camera3D.new()
	cam.fov=78
	campus.add_child(cam)
	cam.make_current()
	var views=[
		[Vector3(-52.5,16.5,-120),Vector3(-64,14,-113),"library_counter_updated.png"],
		[Vector3(-53,17,-105),Vector3(-74,14,-99),"library_reading_updated.png"],
		[Vector3(-57,19,-115),Vector3(-45,18,-98),"library_rooms_updated.png"]]
	if "--shelves-only" in OS.get_cmdline_user_args():
		views=[[Vector3(-53.5,18,-110),Vector3(-64,13.5,-94),"library_shelves_updated.png"]]
	for view in views:
		cam.position=view[0]
		cam.look_at(view[1])
		for i in range(15): await process_frame
		await RenderingServer.frame_post_draw
		var error=root.get_texture().get_image().save_png("res://reports/"+view[2])
		print("LIBRARY_PREVIEW ",view[2]," error=",error)
	quit()
