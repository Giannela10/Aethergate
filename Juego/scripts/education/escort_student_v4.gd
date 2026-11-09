extends CharacterBody3D
var mission: Node
var visual: Node3D
func _ready() -> void:
	collision_layer=0; collision_mask=1
	var shape := CapsuleShape3D.new(); shape.radius=0.4; shape.height=2.5
	var collision := CollisionShape3D.new(); collision.shape=shape; collision.position.y=1.25; add_child(collision)
	visual=preload("res://scripts/juego/student_visual.gd").new(); add_child(visual)
	var presets=preload("res://scripts/juego/character_visual_presets.gd"); presets.apply(visual,presets.create("v4_rescued_student","ESTUDIANTE"))
	add_to_group("campus_civilian")
	var label := Label3D.new(); label.text="ESTUDIANTE · NECESITO AYUDA"; label.position.y=2.8; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(label)
func _physics_process(delta: float) -> void:
	var step := int(mission.state.mission_steps.get("v4_rescue",0))
	if step!=6: return
	var player: Node3D=mission.platform.campaign.player
	var offset: Vector3=player.global_position-global_position; offset.y=0
	velocity=offset.normalized()*2.5 if offset.length()>1.8 else Vector3.ZERO
	velocity.y=-8
	move_and_slide()
	visual.animate(delta,velocity,is_on_floor(),false)
	if Vector2(global_position.x-mission.rescue_safe.x,global_position.z-mission.rescue_safe.z).length()<2 and absf(global_position.y-mission.rescue_safe.y)<1:
		mission.advance(mission.definition("v4_rescue"),6)
func take_hit(_direction: Vector3,_damage: float) -> void:
	pass # Civilian is never damageable or in the enemy group.
