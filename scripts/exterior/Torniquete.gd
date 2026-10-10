@tool
extends Node3D
const CampusNodes = preload("res://scripts/organizacion/nodos_campus.gd")
@export var post_height := 1.0
@export var post_radius := 0.06
@export var arm_length := 1.2
@export var arm_height := 1.5
@export var arm_thickness := 0.05
@export var metal_color := Color(0.7,0.7,0.75)
@export var open_angle := 90.0
@export_tool_button("Regenerar Torniquete") var regenerar_btn: Callable = regenerar
var pivot: Node3D
var is_open := false
var occupants: Array[Node3D] = []
var animation: Tween
var close_generation := 0
var opening_direction := 1.0
func _ready() -> void:
	regenerar()
	if not Engine.is_editor_hint(): _setup_trigger()
func regenerar() -> void:
	for child in get_children():
		if child.name in ["Poste","PosteCuerpo","Pivote","Trigger"] or (child is StaticBody3D and str(child.name).begins_with("@")):
			child.free()
	var material := StandardMaterial3D.new()
	material.albedo_color = metal_color
	material.metallic = 0.9
	material.roughness = 0.2
	var post := CSGCylinder3D.new()
	post.name = "Poste"
	post.radius = post_radius
	post.height = post_height
	post.position.y = post_height*0.5
	post.material = material
	attach(self,post)
	var body := StaticBody3D.new()
	body.name = "PosteCuerpo"
	attach(self,body)
	var col := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = post_radius
	cylinder.height = post_height
	col.shape = cylinder
	col.position.y = post_height*0.5
	attach(body,col)
	pivot = Node3D.new()
	pivot.name = "Pivote"
	pivot.position.y = arm_height*0.5
	attach(self,pivot)
	var arm := CSGBox3D.new()
	arm.name = "Brazo"
	arm.size = Vector3(arm_length,arm_height,arm_thickness)
	arm.position.x = arm_length*0.5
	arm.material = material
	attach(pivot,arm)
	var panel := StaticBody3D.new()
	panel.name = "PanelCuerpo"
	attach(pivot,panel)
	var panel_col := CollisionShape3D.new()
	panel_col.name = "Colision"
	var shape := BoxShape3D.new()
	shape.size = arm.size
	panel_col.shape = shape
	panel_col.position.x = arm_length*0.5
	attach(panel,panel_col)
func attach(parent: Node, child: Node) -> void:
	parent.add_child(child)
	if Engine.is_editor_hint(): child.owner = get_tree().edited_scene_root
func _setup_trigger() -> void:
	var area := Area3D.new()
	area.name = "Trigger"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(arm_length+0.6,3.5,5.0)
	col.shape = shape
	col.position = Vector3(arm_length*0.5,1.75,0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"): return
	if occupants.is_empty(): opening_direction = 1.0 if to_local(body.global_position).z >= 0 else -1.0
	if not occupants.has(body): occupants.append(body)
	close_generation += 1
	set_open(true)
func _on_body_exited(body: Node3D) -> void:
	if not occupants.has(body): return
	occupants.erase(body)
	close_generation += 1
	var generation := close_generation
	await get_tree().create_timer(0.6).timeout
	if generation == close_generation and occupants.is_empty(): set_open(false)
func set_open(value: bool) -> void:
	is_open = value
	if animation and animation.is_valid(): animation.kill()
	var col := CampusNodes.obtener(pivot, "PanelCuerpo/Colision") as CollisionShape3D
	col.set_deferred("disabled",true)
	animation = create_tween()
	animation.tween_property(pivot,"rotation:y",deg_to_rad(open_angle)*opening_direction if value else 0.0,0.3)
	if not value:
		animation.tween_callback(func():
			if not is_open: col.set_deferred("disabled",false))

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or not is_open: return
	for body in occupants:
		if not is_instance_valid(body) or not body is CharacterBody3D: continue
		var local_position := to_local(body.global_position)
		var local_velocity: Vector3 = global_basis.inverse()*body.velocity
		if absf(local_position.z)>0.6 and local_position.z*local_velocity.z < -0.1:
			var direction := 1.0 if local_position.z > 0 else -1.0
			if direction != opening_direction:
				opening_direction = direction
				set_open(true)
			break