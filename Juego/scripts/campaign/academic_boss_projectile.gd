extends "res://scripts/pisos/piso_8/proyectil_error_sistema.gd"
## Conserva barrido, paredes y daño del proyectil existente.
var word := "WORD"
var homing := false
var homing_time := 0.7
func _damage_victim(_victim: Node) -> void:
	shooter.hit_player(damage)
func _ready() -> void:
	super._ready()
	for child in get_children():
		if child is Label3D: child.text = word
	model.scale = Vector3(0.75,0.25,1.2) if word in ["HOJA","LIBRO"] else Vector3.ONE*0.7
func _physics_process(delta: float) -> void:
	if not is_instance_valid(shooter) or not shooter.combat_active(): queue_free(); return
	if homing and age < homing_time and is_instance_valid(shooter.target):
		var direction: Vector3 = global_position.direction_to(shooter.target.global_position+Vector3.UP)
		velocity = velocity.lerp(direction*velocity.length(),minf(delta*0.8,0.08))
	super._physics_process(delta)
