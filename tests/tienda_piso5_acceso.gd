extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var campus := load("res://Main.tscn").instantiate() as Node3D
	campus.get_node("GameplayManager").free()
	root.add_child(campus)
	await physics_frame
	await physics_frame
	var failures: Array[String] = []
	var store := campus.get_node("Piso5/TiendaEsquinaPiso5") as Node3D
	var space := campus.get_world_3d().direct_space_state
	for x in [-3.5, -1.5, 0.5, 2.5]:
		var ray := PhysicsRayQueryParameters3D.create(store.to_global(Vector3(x, 1.4, 1.8)), store.to_global(Vector3(x, 1.4, 1)))
		var hit := space.intersect_ray(ray)
		if not hit.is_empty():
			failures.append("Acceso bloqueado en X local=%s: %s" % [x, hit.collider.get_path()])
	for x in [-3.5, -1.5, 0.5, 2.5, 3.7]:
		var ray := PhysicsRayQueryParameters3D.create(store.to_global(Vector3(x, 0.5, 2)), store.to_global(Vector3(x, -1, 2)))
		if space.intersect_ray(ray).is_empty():
			failures.append("Falta suelo ante la tienda en X local=%s" % x)
	for x in [-1.5, 0.5]:
		var ray := PhysicsRayQueryParameters3D.create(store.to_global(Vector3(x, 1, 1)), store.to_global(Vector3(x, 1, -1.5)))
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or not str(hit.collider.get_path()).contains("TiendaEsquinaPiso5/MostradorFrontal"):
			failures.append("Falta colisión del mostrador en X local=%s" % x)
	if store.global_position.distance_to(Vector3(-28.751, 47.975, -144.517)) > 0.15:
		failures.append("La tienda debe estar al norte, junto al desembarco")
	if store.global_basis.z.normalized().dot(Vector3.BACK) < 0.99:
		failures.append("El mostrador debe mirar al acceso junto a emergencia (+Z)")
	if store.find_children("Vitrina*", "MeshInstance3D", true, false).size() != 2:
		failures.append("Deben existir dos vitrinas")
	print("TIENDA_PISO5_ACCESS ", JSON.stringify({"tested": 14, "failures": failures}))
	var result := 0 if failures.is_empty() else 1
	campus.free()
	quit(result)
