extends SceneTree
func _initialize() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var coordination = scene.get_node("Piso1/InteriorCoordinacion")
	var floor_node = coordination.get_node("PisoCoordinacion")
	var ceiling_node = coordination.get_node("TechoCoordinacion")
	var floor_transform = floor_node.transform
	var ceiling_transform = ceiling_node.transform
	var floor_mesh = floor_node.mesh
	var ceiling_mesh = ceiling_node.mesh
	var floor_material = floor_node.material_override
	var ceiling_material = ceiling_node.material_override
	coordination.set_script(load("res://interior_coordinacion_referencia.gd"))
	print(coordination.build())
	assert(floor_node == coordination.get_node("PisoCoordinacion") and floor_node.transform == floor_transform and floor_node.mesh == floor_mesh and floor_node.material_override == floor_material)
	assert(ceiling_node == coordination.get_node("TechoCoordinacion") and ceiling_node.transform == ceiling_transform and ceiling_node.mesh == ceiling_mesh and ceiling_node.material_override == ceiling_material)
	print("COORDINACION_SUELO_TECHO_CONSERVADOS=true")
	var front = scene.get_node("Piso1/coodinacion")
	front.hide()
	for c in front.find_children("*","CollisionShape3D",true,false):
		c.disabled = true
	for title in ["CartelCoordinacion","IndicacionCoordinacion"]:
		var sign = scene.get_node_or_null("Piso1/AcabadosPasilloCoordinacion/"+title)
		if sign:
			sign.hide()
	# La ampliación del auditorio tenía bloques macizos hasta la planta baja.
	# Conserva sus caras superiores y deja libre el volumen bajo el techo existente.
	var auditorium = scene.get_node("Piso2/AuditorioPiso2e/AuditorioAmpliado")
	var room := AABB(Vector3(33,0,-122.5),Vector3(50.7,4.94,29.0))
	for mesh_node in auditorium.find_children("*","MeshInstance3D",true,false):
		if not mesh_node.mesh is BoxMesh:
			continue
		var bounds: AABB = mesh_node.transform * mesh_node.get_aabb()
		if not bounds.intersects(room) or bounds.end.y <= 4.94:
			continue
		if bounds.position.y >= 4.94:
			continue
		var adjusted: BoxMesh = mesh_node.mesh.duplicate()
		adjusted.size.y = bounds.end.y-4.94
		mesh_node.position.y = (bounds.end.y+4.94)*0.5
		mesh_node.mesh = adjusted
		for collider in mesh_node.find_children("*","CollisionShape3D",true,false):
			if collider.shape is BoxShape3D:
				var shape := BoxShape3D.new()
				shape.size = adjusted.size
				collider.shape = shape
		print("AUDITORIO_VOLUMEN_LIBERADO=",mesh_node.name)
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	if error == OK:
		error = ResourceSaver.save(packed,"res://Main.tscn")
	print("COORDINACION_SAVE=",error)
	scene.free()
	quit(error)
