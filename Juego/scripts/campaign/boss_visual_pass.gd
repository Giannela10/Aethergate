extends RefCounted
## Visual layer for existing duel actors. Never writes statistics, collision or AI.
const STATES := ["BOSS_IDLE","BOSS_INTRO","BOSS_MELEE","BOSS_RANGED","BOSS_SPECIAL","BOSS_HIT","BOSS_PHASE","BOSS_DEATH"]
var body: Node3D
var activity: RefCounted
var boss_id := ""
var last_phase := -1
var phase_time := 0.0
var visual_state := "BOSS_IDLE"
var gesture_time := 0.0
var signature_prop: Node3D

func setup(actor: Node3D, id: String) -> void:
	boss_id = id
	for property in ["body","_visual","visual"]:
		var candidate = actor.get(property)
		if candidate is Node3D and candidate.get("head_pivot") != null:
			body = candidate
			break
	if body == null or id == "nexo":
		return
	activity = preload("res://scripts/juego/character_activity_visual.gd").new(body)
	var work := "INSPECT"
	var prop := "FOLDER"
	match id:
		"chef": work = "REPAIR"; prop = "NONE"
		"bibliotecaria","profesor_lenguaje": work = "READ"; prop = "BOOK"
		"profesor_ingles": work = "INSPECT"; prop = "TABLET"
		"profesor_etica": work = "WRITE"; prop = "FOLDER"
		"profesor_redes": work = "INSPECT"; prop = "NONE" # Existing tablet.
		"profesor_programacion": work = "TYPE"; prop = "TABLET"
		"director": work = "TYPE"; prop = "TABLET"
		"maestro_soldadura","jefe_taller": work = "INSPECT"; prop = "TOOL"
		"punto": work = "INSPECT"; prop = "NONE"
	activity.set_activity(work,prop)
	if id == "chef":
		signature_prop = body._box(body.hand_l,Vector3(0.38,0.025,0.25),Vector3(0,-0.025,-0.08),Color("9baeb7"))
	elif id == "punto":
		body._box(body.chest,Vector3(0.08,0.1,0.018),Vector3(-0.09,0.05,-0.15),Color("ece3ba"))
		for side in [-1,1]:
			body._box(body.chest,Vector3(0.016,0.20,0.015),Vector3(side*0.13,0.1,-0.135),Color("d6cfdf"))
		signature_prop = body._ball(body.hand_l,0.10,Vector3(0,-0.06,-0.04),Color("c7833d"))
	body.set_meta("boss_animation_states",STATES)
	body.set_meta("neutral_work",work)
	body.set_expression("NEUTRAL")

func update(delta: float, duel_state: int, phase: int) -> void:
	if not is_instance_valid(body) or boss_id == "nexo":
		return
	body.update_visual_lod(delta)
	if body.lod_level == 2 and duel_state not in [2,3,4]:
		if is_instance_valid(activity.prop): activity.prop.hide()
		return
	if is_instance_valid(signature_prop):
		signature_prop.visible = duel_state in [0,1]
	# Punto's current actor animates only in physics, disabled before the duel.
	if boss_id == "punto" and duel_state in [0,1,2]:
		body.animate(delta,Vector3.ZERO,true,false)
	phase_time = maxf(0,phase_time-delta)
	if phase != last_phase:
		if last_phase >= 0: phase_time = 0.6
		last_phase = phase
	visual_state = "BOSS_IDLE"
	if duel_state == 2: visual_state = "BOSS_INTRO"
	elif duel_state == 4: visual_state = "BOSS_DEATH"
	elif duel_state == 3:
		visual_state = "BOSS_PHASE" if phase_time > 0 else ("BOSS_HIT" if body.hurt_t > 0 else ("BOSS_MELEE" if body.is_punching() else "BOSS_IDLE"))
		var actor := body.get_parent()
		for key in ["charge","blue_charge","connection_charge"]:
			if actor.get(key) != null and float(actor.get(key)) > 0: visual_state = "BOSS_SPECIAL"
		for key in ["digital_pending","packet_pending"]:
			if actor.get(key) == true: visual_state = "BOSS_RANGED"
	body.set_meta("boss_visual_state",visual_state)
	if body.has_method("request_visual_state") and visual_state != "BOSS_IDLE": body.request_visual_state(visual_state,0.15)
	body.set_expression("ALERT" if duel_state in [2,3] else "NEUTRAL")
	activity.apply(delta,duel_state in [0,1])
	if duel_state == 2:
		var weight := minf(1.0,delta*8)
		body.shoulder_l.rotation.x = lerpf(body.shoulder_l.rotation.x,0.65,weight)
		body.elbow_l.rotation.x = lerpf(body.elbow_l.rotation.x,1.2,weight)
