extends Node3D
var hub: Node
var source: Node3D
var kind := ""
var token := ""
var held := false
var resolved := false
var interaction_range := 2.5
var label: Label3D
var prop_visual: MeshInstance3D
func _ready() -> void:
	add_to_group("campus_interactable")
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 26
	label.pixel_size = 0.003
	label.position.y = 1.8
	add_child(label)
	if kind == "objeto_caido":
		prop_visual = MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22,0.025,0.3)
		prop_visual.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("93755a")
		prop_visual.material_override = material
		prop_visual.position.y = 0.08
		add_child(prop_visual)
func interaction_text(_player: Node) -> String:
	if resolved: return ""
	match kind:
		"objeto_caido": return "[E] Devolver carpeta" if held else "[E] Recoger carpeta"
		"orientar": return "[E] Orientar hacia las salas"
		"fallo_breve": return "[E] Ayudar a revisar la pantalla"
	return "[E] Aceptar agradecimiento"
func context_action() -> String:
	return "pickup" if kind == "objeto_caido" and not held else "talk"
func interact(player: Node3D) -> void:
	if resolved or hub.director.locked() or hub.director.in_combat() or player.global_position.distance_to(global_position) > interaction_range: return
	if kind == "objeto_caido" and not held:
		held = true
		if is_instance_valid(prop_visual):
			prop_visual.reparent(player.body.item_socket,false)
			prop_visual.position = Vector3(0,0,-0.06)
		label.text = "La carpeta pertenece a la persona de al lado."
		return
	resolved = true
	label.text = "¡Gracias por la ayuda!"
	if hub.events.reward_once(token) and kind == "pausa_positiva":
		hub.campaign.grant_reward({"items":{"Bebida":1}},"live:gift:"+token)
	if is_instance_valid(prop_visual): prop_visual.queue_free()
	hub.events.finish()

func _exit_tree() -> void:
	if is_instance_valid(prop_visual): prop_visual.queue_free()
