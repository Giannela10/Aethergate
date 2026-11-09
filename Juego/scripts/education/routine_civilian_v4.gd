extends CharacterBody3D
var platform: Node
var npc_id := ""
var floor_number := 1
var route: Array = []
var destination := 1
var sleeping := true
var activity := "WALK"
var visual: Node3D
var interaction_range := 3.0
func _ready() -> void:
	collision_layer = 2; collision_mask = 1
	var shape := CapsuleShape3D.new(); shape.radius = 0.38; shape.height = 2.5
	var collision := CollisionShape3D.new(); collision.shape = shape; collision.position.y = 1.25; add_child(collision)
	visual = preload("res://scripts/juego/student_visual.gd").new()
	add_child(visual)
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	presets.apply(visual,presets.create(npc_id,"ESTUDIANTE"))
	add_to_group("campus_interactable"); add_to_group("campus_civilian")
func interaction_text(_player: Node) -> String: return "[E] Conversar · estudiante"
func interaction_target() -> Node3D: return self
func interaction_priority() -> int: return 0
func interact(_player: CharacterBody3D) -> void:
	platform.campaign.ui.dialog("ESTUDIANTE DEL CAMPUS","Los docentes nos ayudan a detener NEXO. Consulta el directorio en el sector docente del piso 4.\nMi horario es ficticio y solo pertenece al juego.",["CONTINUAR"],[platform.campaign.ui.close_modal],true)
func _physics_process(delta: float) -> void:
	if sleeping: return
	velocity = Vector3.ZERO
	if activity == "WALK" and route.size()>1:
		var offset: Vector3 = route[destination]-global_position
		offset.y = 0
		if offset.length()<0.25: destination = 1-destination
		else:
			velocity = offset.normalized()*1.4
			rotation.y = atan2(-velocity.x,-velocity.z)
	velocity.y = -8 if not is_on_floor() else 0
	move_and_slide()
	visual.set_visual_activity("PHONE" if activity=="PHONE" else ("TALK" if activity=="TALK" else ""))
	visual.animate(delta,velocity,is_on_floor(),false)
