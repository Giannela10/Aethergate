class_name AcademicSchedule
extends Node
## Horario opcional. Reutiliza tiempo jugado, CampaignUI, recompensas y guardado.
## Puede enlazarse a otro reloj mediante time_provider -> {day:int, minute:int}.
const CLASSES = [
	{"id":"programming","name":"Programación","minute":540,"duration":30,"room":"Sala 303 · Piso 3","floor":3,"x":39.4,"z":-128.0,"site":"technology"},
	{"id":"network","name":"Redes","minute":660,"duration":30,"room":"Laboratorio académico · Sala 303 · Piso 3","floor":3,"x":39.4,"z":-128.0,"site":"technology"},
	{"id":"english","name":"Inglés","minute":840,"duration":30,"room":"Punto académico · Piso 5","floor":5,"x":-20.0,"z":-140.0,"site":"general"}
]
const SECONDS_PER_MINUTE := 10.0
var campaign: Node
var state: Dictionary
var time_provider := Callable()
var timer := 0.0
var pending_course := ""
var points: Dictionary = {}

func _ready() -> void:
	state = campaign.data.academics
	if not state.get("records") is Dictionary:
		state.records = {}
	if not state.get("reminders") is Dictionary:
		state.reminders = {}
	for key in ["attended","missed"]:
		var raw = state.get(key,0)
		state[key] = maxi(0,int(raw)) if raw is int or raw is float else 0
	var origin = state.get("origin")
	if not (origin is float or origin is int):
		state.origin = float(campaign.data.stats.get("time_played",0))
	if not (state.get("cursor") is float or state.get("cursor") is int):
		state.cursor = 530
	_setup_points.call_deferred()

func current_time() -> Dictionary:
	if time_provider.is_valid():
		var supplied = time_provider.call()
		if supplied is Dictionary and (supplied.get("day") is int or supplied.get("day") is float) and (supplied.get("minute") is int or supplied.get("minute") is float):
			return {"day":clampi(int(supplied.day),0,9999),"minute":clampi(int(supplied.minute),0,1439)}
	var elapsed := maxf(0,float(campaign.data.stats.get("time_played",0))-float(state.origin))
	var absolute := 530+int(elapsed/SECONDS_PER_MINUTE)
	return {"day":mini(9999,int(absolute/1440)),"minute":absolute%1440}

func clock_text() -> String:
	var now := current_time()
	return "%02d:%02d" % [int(now.minute/60),int(now.minute)%60]

func _definition(id: String) -> Dictionary:
	for course in CLASSES:
		if course.id == id:
			return course
	return {}

func _key(day: int, id: String) -> String:
	return str(day)+":"+id

func _process(delta: float) -> void:
	if not campaign.ready_for_play:
		return
	timer -= delta
	if timer > 0:
		return
	timer = 1.0
	update_schedule()
	if pending_course.is_empty() or not _quiet():
		return
	var course := _definition(pending_course)
	var now := current_time()
	var until: int = int(course.minute)-int(now.minute)
	pending_course = ""
	if until < 0 or until > 10:
		return
	var notice: String = course.name+(" comienza ahora" if until == 0 else " comienza en %d minutos" % until)
	campaign.ui.notify(notice+" · P → Horario",6)

func _quiet() -> bool:
	if get_tree().paused or campaign.player.dead or campaign.player.busy or campaign.ui.modal or campaign.active_duel != null or campaign.manager.minigame.active or campaign.ui.toast_t > 0:
		return false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node3D and enemy.get("dead") != true and enemy.global_position.distance_squared_to(campaign.player.global_position) < 144:
			return false
	return true

func update_schedule() -> void:
	var now := current_time()
	var absolute: int = int(now.day)*1440+int(now.minute)
	var previous: int = int(state.cursor)
	if absolute < previous:
		return # Retroceder un reloj externo nunca borra asistencia ni genera faltas.
	var changed := false
	for course in CLASSES:
		var ending: int = course.minute+course.duration
		var first: int = maxi(0,floori(float(previous-ending)/1440.0)+1)
		var last: int = floori(float(absolute-ending)/1440.0)
		var missed := maxi(0,last-first+1)
		if missed > 0:
			for key in state.records:
				var pieces := str(key).split(":")
				if pieces.size() == 2 and pieces[1] == course.id and state.records[key] == "attended":
					var day := int(pieces[0])
					if day >= first and day <= last:
						missed -= 1
			state.missed += maxi(0,missed)
			changed = true
		var until: int = int(course.minute)-int(now.minute)
		var reminder_key := _key(int(now.day),course.id)
		if until >= 0 and until <= 10 and not state.reminders.has(reminder_key):
			state.reminders[reminder_key] = true
			pending_course = course.id
			changed = true
	state.cursor = absolute
	for dictionary in [state.records,state.reminders]:
		for key in dictionary.keys():
			if int(str(key).get_slice(":",0)) < int(now.day)-2:
				dictionary.erase(key)
	if changed:
		campaign.save_game()

func attendance_text() -> String:
	var total: int = int(state.attended)+int(state.missed)
	return "ASISTENCIA: %s\nAsistidas: %d · Perdidas: %d" % [("%d%%" % roundi(100.0*state.attended/total)) if total > 0 else "sin registros",state.attended,state.missed]

func _page(title: String, text: String, choices: Array, actions: Array) -> void:
	campaign.ui.dialog(title,text,choices,actions,true)
	campaign.ui.page = "phone:schedule"
	campaign.phone.view.present()

func show_schedule() -> void:
	update_schedule()
	var now := current_time()
	var text := "LUNES · Jornada %d · %s\n%s\n\nClases opcionales: faltar no bloquea la campaña." % [int(now.day)+1,clock_text(),attendance_text()]
	var choices: Array = []
	var actions: Array = []
	for course in CLASSES:
		choices.append("%02d:%02d · %s" % [int(course.minute/60),int(course.minute)%60,course.name])
		actions.append(show_class.bind(course.id))
	choices.append("Volver al celular")
	actions.append(campaign.phone.open)
	_page("HORARIO",text,choices,actions)

func show_site(site: String) -> void:
	var now := current_time()
	for course in CLASSES:
		if course.site == site and int(now.minute) >= course.minute-10 and int(now.minute) < course.minute+course.duration:
			show_class(course.id)
			return
	show_schedule()

func show_class(id: String) -> void:
	var course := _definition(id)
	if course.is_empty():
		return
	update_schedule()
	var now := current_time()
	var record: String = str(state.records.get(_key(int(now.day),id),""))
	var status := "Asistencia registrada" if record == "attended" else ("Aviso ignorado" if record == "ignored" else "Opcional")
	var text := "%s\n%02d:%02d · %d minutos\n%s\n\n%s\nAcércate al punto de clase a la hora indicada para registrar asistencia." % [course.name,int(course.minute/60),int(course.minute)%60,course.duration,course.room,status]
	_page(course.name.to_upper(),text,["ASISTIR","IGNORAR AVISO","Volver al horario"],[attend.bind(id),ignore.bind(id),show_schedule])

func attend(id: String) -> bool:
	var course := _definition(id)
	if course.is_empty() or campaign.player.dead or campaign.active_duel != null or campaign.manager.minigame.active:
		return false
	var now := current_time()
	var key := _key(int(now.day),id)
	if int(now.day)*1440+int(now.minute) < int(state.cursor):
		campaign.ui.notify("El reloj debe sincronizarse antes de registrar asistencia")
		return false
	if state.records.get(key) == "attended":
		campaign.ui.notify("La asistencia ya está registrada")
		return false
	if int(now.minute) < course.minute or int(now.minute) >= course.minute+course.duration:
		campaign.ui.notify("La clase no está en horario")
		return false
	var point: Node3D = points.get(course.site)
	if not is_instance_valid(point) or campaign.player.global_position.distance_to(point.global_position) > 3.0 or not campaign.player._can_reach(point):
		campaign.ui.notify("Debes estar en "+course.room)
		return false
	update_schedule()
	state.records[key] = "attended"
	state.reminders[key] = true
	if pending_course == id:
		pending_course = ""
	state.attended += 1
	campaign.grant_reward({"xp":25,"credits":10},"academic_attendance:"+id)
	campaign.save_game()
	show_class(id)
	campaign.ui.notify("Asistencia registrada · "+course.name)
	return true

func ignore(id: String) -> void:
	if _definition(id).is_empty():
		return
	var now := current_time()
	var key := _key(int(now.day),id)
	if state.records.get(key) != "attended":
		state.records[key] = "ignored"
	state.reminders[key] = true
	if pending_course == id:
		pending_course = ""
	campaign.save_game()
	show_schedule()

func _setup_points() -> void:
	var heights: Array = preload("res://scripts/campaign/campus_content.gd").HEIGHTS
	for course in CLASSES:
		if points.has(course.site):
			continue
		var point = preload("res://scripts/campaign/academic_class_point.gd").new()
		point.name = "Clase_"+course.site
		point.schedule = self
		point.site = course.site
		campaign.add_child(point)
		point.global_position = Vector3(course.x,float(heights[course.floor-1])+0.15,course.z)
		points[course.site] = point
