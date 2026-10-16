extends CharacterBody3D
@export var patrol_points: Array[Vector3] = []
@export var desk_mode := false
var model: Node3D
var waypoint := 0
var greeting: Label3D
var greeting_time := 0.0
var cooldown := 0.0
var patrol_origin: Vector3
func _ready() -> void:
	add_to_group("campus_guard")
	patrol_origin = global_position
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.5
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 2.7
	col.shape = shape
	col.position.y = 1.35
	add_child(col)
	model = load("res://scripts/juego/humanoid.gd").new()
	var identity := preload("res://scripts/juego/character_visual_presets.gd").create(str(get_path()),"GUARDIA")
	model.skin_color = Color(preload("res://scripts/juego/character_appearance.gd").SKIN[identity.skin])
	model.hair_color = Color(preload("res://scripts/juego/character_appearance.gd").HAIR[identity.hair_color])
	model.scale = Vector3.ONE*1.5
	model.shirt_color = Color(0.06,0.075,0.09)
	model.pants_color = Color(0.08,0.1,0.13)
	add_child(model)
	if desk_mode: model.rotation.y = PI
	vest_part(Vector3(0.34,0.32,0.27),Vector3(0,0.11,0),Color(0.87,0.025,0.035),false)
	for z in [-0.14,0.14]:
		vest_part(Vector3(0.34,0.035,0.01),Vector3(0,0.005,z),Color(0.92,0.94,0.87),true)
		for x in [-0.09,0.09]: vest_part(Vector3(0.035,0.28,0.01),Vector3(x,0.13,z),Color(0.92,0.94,0.87),true)
	greeting = Label3D.new()
	greeting.text = "Buenos días"
	greeting.font_size = 48
	greeting.position.y = 3.1
	greeting.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	greeting.visible = false
	add_child(greeting)
func vest_part(size_value: Vector3, p: Vector3, color: Color, reflective: bool) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size_value
	mesh.mesh = box
	mesh.position = p
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.2 if reflective else 0.8
	material.metallic = 0.7 if reflective else 0.0
	mesh.material_override = material
	model.chest.add_child(mesh)
func _physics_process(delta: float) -> void:
	cooldown = maxf(0,cooldown-delta)
	greeting_time = maxf(0,greeting_time-delta)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if is_instance_valid(player) and global_position.distance_to(player.global_position)<4.5 and cooldown<=0:
		greeting_time = 3.0
		cooldown = 15.0
	greeting.visible = greeting_time>0
	model.look_controller.target = player if greeting.visible and model.secondary_animation_enabled else null
	var direction := Vector3.ZERO
	if greeting_time>0 and is_instance_valid(player) and not desk_mode:
		var to_player := player.global_position-global_position
		if Vector2(to_player.x,to_player.z).length()>0.1: model.rotation.y = lerp_angle(model.rotation.y,atan2(-to_player.x,-to_player.z),delta*5)
	elif not patrol_points.is_empty():
		var target := patrol_points[waypoint]
		direction = Vector3(target.x-global_position.x,0,target.z-global_position.z)
		if direction.length()<0.2:
			waypoint = (waypoint+1)%patrol_points.size()
			direction = Vector3.ZERO
		else:
			direction = direction.normalized()
			model.rotation.y = lerp_angle(model.rotation.y,atan2(-direction.x,-direction.z),delta*5)
	velocity.x = direction.x*1.1
	velocity.z = direction.z*1.1
	if not is_on_floor(): velocity.y -= 14.0*delta
	move_and_slide()
	model.animate(delta,velocity,is_on_floor(),false)
	if desk_mode:
		model.rotation.y = PI
		model.shoulder_l.rotation.x = 0.55
		model.shoulder_r.rotation.x = 0.55
		model.elbow_l.rotation.x = 1.25+sin(Time.get_ticks_msec()*0.004)*0.04
		model.elbow_r.rotation.x = 1.25+cos(Time.get_ticks_msec()*0.004)*0.04
