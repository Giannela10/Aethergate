extends Node3D
var area: Node3D
var link := false
var interaction_range := 2.4
var screen: MeshInstance3D
var caption: Label3D
var is_access := false
func _ready() -> void:
	add_to_group("campus_interactable")
	screen = area.box(self,Vector3(0.65,0.45,0.14),Vector3(0,1.15,0),area.cyan)
	area.box(self,Vector3(0.55,0.9,0.5),Vector3(0,0.45,0),area.dark)
	caption = area.label(self,"ACCESO AL NÚCLEO" if is_access else str(name),Vector3(0,1.85,0))
	refresh()
func interaction_priority() -> int: return -1
func context_action() -> String: return "button"
func interaction_text(_player: Node) -> String:
	if is_access:
		if area.completed(): return "[E] Revisar cierre de campaña"
		return "[E] Acceder al núcleo de NEXO" if area.can_access() else "[E] El acceso al núcleo está bloqueado."
	return "[E] Desactivar enlace" if link and area.actor.combat_active() else ""
func interact(player: Node3D) -> void:
	if player.dead or player.busy or player.global_position.distance_to(global_position) > interaction_range or not player._can_reach(self): return
	if is_access:
		if area.completed(): area.show_results()
		else: area.enter_core()
	elif link and area.actor.combat_active():
		link = false
		refresh()
		area.actor.link_disabled()
func refresh() -> void:
	if screen == null: return
	screen.material_override = area.cyan if (link or is_access and not area.completed()) else area.green
	if not is_access: caption.text = str(name)+("\nENLACE ACTIVO" if link else "\nSIN ENLACE")
