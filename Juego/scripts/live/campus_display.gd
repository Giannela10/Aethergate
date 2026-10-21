extends RefCounted
enum State { NORMAL, NOTICE, NEXO_GLITCH, EMERGENCY, RESTORED }
var pc: Node3D
var state := State.NORMAL
func _init(computer: Node3D) -> void:
	pc = computer
func show_state(value: int) -> void:
	if not is_instance_valid(pc): return
	state = value
	# Always derive the baseline from its current quest state, never a stale snapshot.
	pc._refresh()
	if pc.done: return
	match state:
		State.NOTICE: pc.screen_text.text += "\nCampus · Horario en celular"
		State.NEXO_GLITCH:
			pc.screen_text.text += "\nSeñal irregular"
			pc.screen_mat.emission = Color("8358a5")
		State.EMERGENCY: pc.screen_text.text += "\nAviso del campus"
		State.RESTORED: pc.screen_text.text += "\nSeñal estable"
