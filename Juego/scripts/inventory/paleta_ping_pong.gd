extends "res://scripts/juego/weapon.gd"
## Conserva la API y durabilidad de weapon.gd.
func _ready() -> void:
	kind = "paleta_ping_pong"
	weapon_name = "Paleta de ping-pong"
	damage = 20.0
	reach = 1.85
	durability = 22
	set_meta("max_durability",22)
	set_meta("rarity_name","POCO COMÚN")
	swing_time = 0.48
	model = Node3D.new()
	add_child(model)
	_cyl(model,0.022,0.025,0.22,Vector3(0,-0.04,0),Color("ba8855"))
	var paddle := CylinderMesh.new()
	paddle.top_radius = 0.15
	paddle.bottom_radius = 0.15
	paddle.height = 0.025
	var face := _mesh(model,paddle,Vector3(0,-0.27,0),Color("c42d3d"))
	face.rotation.x = PI/2
	_build_marker()
	put_down()
