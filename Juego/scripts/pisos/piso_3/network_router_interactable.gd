class_name NetworkRouterInteractable
extends Node3D
enum RouterState { ACTIVE, DISABLED }
@export var interaction_range := 2.3
var state := RouterState.DISABLED
var boss: Node
var light_material: StandardMaterial3D
var indicator: Label3D

func _ready() -> void:
	add_to_group("campus_interactable")
	add_to_group("network_router_piso3")
	var device := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9,0.3,0.6)
	device.mesh = box
	device.position.y = 0.85
	var casing := StandardMaterial3D.new()
	casing.albedo_color = Color("273342")
	device.material_override = casing
	add_child(device)
	for x in [-0.32,0.32]:
		var antenna := MeshInstance3D.new()
		var rod := CylinderMesh.new()
		rod.top_radius = 0.025
		rod.bottom_radius = 0.025
		rod.height = 0.7
		antenna.mesh = rod
		antenna.position = Vector3(x,1.15,-0.22)
		add_child(antenna)
	var led := MeshInstance3D.new()
	var led_box := BoxMesh.new()
	led_box.size = Vector3(0.65,0.07,0.04)
	led.mesh = led_box
	led.position = Vector3(0,0.87,0.32)
	light_material = StandardMaterial3D.new()
	light_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	led.material_override = light_material
	add_child(led)
	indicator = Label3D.new()
	indicator.position.y = 1.8
	indicator.pixel_size = 0.005
	indicator.font_size = 32
	indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(indicator)
	set_active(false)

func set_active(enabled: bool) -> void:
	state = RouterState.ACTIVE if enabled else RouterState.DISABLED
	if light_material:
		light_material.albedo_color = Color("13e8e3") if enabled else Color("727983")
	if indicator:
		indicator.text = str(name)+"\n"+("ACTIVO · [E] Desconectar" if enabled else "DESCONECTADO")
		indicator.modulate = Color("50ffff") if enabled else Color("a3abb6")

func interaction_text(_player: Node) -> String:
	return "[E] Desconectar Router" if state == RouterState.ACTIVE and is_instance_valid(boss) and boss.combat_active() else ""

func interaction_priority() -> int:
	# Prioridad frente al jefe durante combate; los objetos clave conservan su flujo.
	return -1

func interact(player: CharacterBody3D) -> void:
	if not is_instance_valid(boss) or not boss.combat_active() or state != RouterState.ACTIVE:
		return
	if player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(self):
		return
	set_active(false)
	boss.router_disconnected(self)
