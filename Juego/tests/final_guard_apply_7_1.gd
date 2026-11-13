extends Node
func install(f: Node) -> String:
	var front=f.campus.get_node("Piso5/TerrazaPicnic/CercaVidrio/Frente")
	front.set_script(load("res://scripts/pisos/piso_5/terrace_guard_collision_7_1.gd"));front._ready()
	return "FRONT_PANE_BOXES_INSTALLED"
