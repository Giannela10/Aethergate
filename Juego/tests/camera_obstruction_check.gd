extends SceneTree
const CameraCollision = preload("res://scripts/juego/camera_obstruction.gd")
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2,3,0.2)
	collider.shape = shape
	wall.add_child(collider)
	scene.add_child(wall)
	wall.position = Vector3(0,1.4,2.5)
	await physics_frame
	await physics_frame
	var pivot := Vector3(0,1.4,0)
	var desired := Vector3(0,1.4,5)
	var result := CameraCollision.resolve(root.world_3d.direct_space_state,pivot,desired,[])
	check(result.z < 2.2 and result.z > 1.9,"Camera sphere stops before wall")
	wall.position.x = 0.28
	shape.size.x = 0.2
	await physics_frame
	await physics_frame
	var ray := PhysicsRayQueryParameters3D.create(pivot,desired)
	check(root.world_3d.direct_space_state.intersect_ray(ray).is_empty(),"Center ray misses railing edge fixture")
	result = CameraCollision.resolve(root.world_3d.direct_space_state,pivot,desired,[])
	check(result.z < 2.4,"Camera volume still catches railing edge")
	wall.position.x = 5
	await physics_frame
	await physics_frame
	result = CameraCollision.resolve(root.world_3d.direct_space_state,pivot,desired,[])
	check(result.is_equal_approx(desired),"Camera restores full distance in open space")
	check(CameraCollision.resolve(root.world_3d.direct_space_state,pivot,pivot,[]) == pivot,"Zero-length query is safe")
	print("CAMERA_OBSTRUCTION_RESULT ",JSON.stringify({"checks":5,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
