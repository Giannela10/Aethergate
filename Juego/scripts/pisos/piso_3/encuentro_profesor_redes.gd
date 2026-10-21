class_name EncuentroProfesorRedes
extends Node3D
const Boss = preload("res://scripts/pisos/piso_3/profesor_redes_boss.gd")
const Router = preload("res://scripts/pisos/piso_3/network_router_interactable.gd")
const Reward = preload("res://scripts/pisos/piso_3/router_portatil_item.gd")
var boss: CharacterBody3D
var placement_valid := false

func _enter_tree() -> void:
	# Piso3 entra antes de GameplayManager: el objeto existe antes de cargar mochila.
	preload("res://scripts/inventory/item_catalog.gd").register_item(Reward.new())

func _ready() -> void:
	boss = Boss.new()
	boss.name = "ProfesorRedes"
	add_child(boss)
	for i in 3:
		var router := Router.new()
		router.name = ["Router_A","Router_B","Router_C"][i]
		router.boss = boss
		add_child(router)
		router.position = [Vector3(-6,0,-1),Vector3(4,0,-1),Vector3(0,0,3)][i]
		boss.routers.append(router)
	call_deferred("_settle")

func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var world := get_world_3d().direct_space_state
	var excluded: Array[RID] = [boss.get_rid()]
	for player in get_tree().get_nodes_in_group("player"):
		if player is CollisionObject3D:
			excluded.append(player.get_rid())
	placement_valid = true
	for node in [boss]+boss.routers:
		var ray := PhysicsRayQueryParameters3D.create(node.global_position+Vector3.UP*1.0,node.global_position+Vector3.DOWN*1.2)
		ray.exclude = excluded
		var floor_hit := world.intersect_ray(ray)
		var valid: bool = not floor_hit.is_empty() and floor_hit.normal.y > 0.9
		if valid:
			node.global_position.y = floor_hit.position.y+0.04
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.48
			capsule.height = 2.7
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform.origin = node.global_position+Vector3.UP*1.4
			query.exclude = excluded
			var blockers := world.intersect_shape(query,4)
			valid = blockers.is_empty()
			if not valid:
				print("REDES_PLACEMENT ",node.name," ",node.global_position," blockers=",blockers.map(func(hit): return str(hit.collider.get_path())))
		node.set_meta("network_placement_valid",valid)
		placement_valid = placement_valid and valid
	boss.home = boss.global_position
	boss.patrol_target = boss.home
	boss.get_node("BossDuelController").spawn_position = boss.home
	if not placement_valid:
		push_warning("Piso3: revisar suelo y espacio libre del Profesor de Redes y routers; desafío deshabilitado.")
