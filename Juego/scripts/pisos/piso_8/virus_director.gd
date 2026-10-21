extends "res://scripts/juego/enemy.gd"
## Virus 3D: usa la IA, golpes y muerte del enemigo normal.
var director: Node3D

func _ready() -> void:
	super._ready()
	health = 50.0
	body.name = "VisualVirus"
	body.scale = Vector3.ONE * 0.7
	for mesh in body.find_children("*","MeshInstance3D",true,false):
		var mat := (mesh as MeshInstance3D).material_override as StandardMaterial3D
		if mat and mat.albedo_color.is_equal_approx(Color("a83232")):
			mat.albedo_color = Color("be183b")
	for child in get_children():
		if child is CollisionShape3D:
			child.shape.height = 1.26
			child.shape.radius = 0.21
			child.position.y = 0.63
	bar_root.position.y = 1.6
	alert_label.position.y = 2.0
	var label := Label3D.new()
	label.text = "VIRUS.sys"
	label.position.y = 1.85
	label.font_size = 28
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_update_bar()

func _update_bar() -> void:
	if not is_instance_valid(bar_fg):
		return
	var width := maxf(BAR_W * health / 50.0,0.001)
	var quad := bar_fg.mesh as QuadMesh
	quad.size.x = width
	quad.center_offset.x = -(BAR_W-width)*0.5

func _vision_amount() -> float:
	if not is_instance_valid(director) or director.get("dead") == true or not is_instance_valid(target):
		return 0.0
	if target.get("dead") == true or not director.call("inside_arena",target.global_position):
		return 0.0
	return 1.0 if _line_of_sight(global_position+Vector3.UP,target.global_position+Vector3.UP) else 0.0

func _do_patrol(_delta: float) -> Vector3:
	return Vector3.ZERO

func _do_search(_delta: float) -> Vector3:
	state = State.PATROL
	return Vector3.ZERO

func _do_chase(delta: float, vis: float) -> Vector3:
	if not is_instance_valid(director) or not is_instance_valid(target) or not director.call("inside_arena",target.global_position):
		state = State.PATROL
		return Vector3.ZERO
	var desired := super._do_chase(delta,vis)
	if not director.call("inside_arena",global_position + desired * delta):
		return Vector3.ZERO
	return desired

func take_hit(direction: Vector3, damage: float) -> void:
	super.take_hit(direction,maxf(damage,0.0))

func _physics_process(delta: float) -> void:
	if not is_instance_valid(director) or director.get("dead") == true:
		deactivate()
		return
	super._physics_process(delta)

func _on_punch_landed(side: int) -> void:
	if is_instance_valid(director) and not director.get("dead") and is_instance_valid(target) and director.call("inside_arena",target.global_position):
		super._on_punch_landed(side)

func deactivate() -> void:
	dead = true
	remove_from_group("enemy")
	collision_layer = 0
	queue_free()
