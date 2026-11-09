extends Node
var campaign: Node
var lab: Node3D
var activities: Array = []
var issues: Array[String] = []
var missions: Node
var routines: Node
var story: Node
var accessibility := preload("res://scripts/education/accessibility_v4.gd").new()
var summary := preload("res://scripts/education/academic_summary_v4.gd").new()
var sound: Node
var performance: Node
var feedback: Node3D
var laboratories: Dictionary = {}
var published_mentors: Dictionary = {}
var credential_tick := 0.0

func update_credentials() -> void:
	var state: Dictionary=campaign.data.education_v4
	if not state.get("credentials") is Dictionary: state["credentials"]={}
	if campaign.quests.state("ubicar_profesores")==2 and not state.credentials.get("coordinacion",false):
		state.credentials["coordinacion"]=true
		campaign.ui.notify("Coordinación entrega la credencial académica del directorio.")
		campaign.save_game()

func _process(delta: float) -> void:
	credential_tick-=delta
	if credential_tick<=0: credential_tick=1.0; update_credentials()

func load_mentor_catalog() -> void:
	var auth := get_node("/root/AuthManager")
	if auth.dev_session or not auth.session_valid(): return
	var owner_id: String=auth.user_id
	var result: Dictionary=await auth.client.request_json("/rest/v1/learning_activities?select=mentor_id&active=eq.true",HTTPClient.METHOD_GET,{},auth.access_token)
	if auth.user_id!=owner_id or not result.get("ok",false) or not result.get("data") is Array: return
	for row in result.data:
		if not str(row.get("mentor_id","")).is_empty(): published_mentors[str(row.mentor_id)]=true

func safe_point(title: String, floor_number: int, preferred: Vector3, action: Callable) -> Node3D:
	var height: float = preload("res://scripts/campaign/campus_content.gd").HEIGHTS[8 if floor_number == -1 else floor_number-1]
	preferred.y = height+0.12
	var seats: Node = campaign.player.get_node("SeatController")
	var position_value = seats.safe_position(preferred)
	if position_value == null or absf(position_value.y-height)>0.5:
		issues.append("Punto sin suelo/espacio: "+title)
		return null
	var point := preload("res://scripts/education/campus_point_v4.gd").new()
	point.title = title; point.action = action
	add_child(point); point.global_position = position_value
	return point

func learn(floor_number: int, mentor_id: String = "") -> void:
	var activity := preload("res://scripts/education/mentor_activity_v4.gd").new()
	activity.campaign = campaign; activity.floor_number = floor_number
	activity.mentor_id=mentor_id
	activities.append(activity)
	activity.open()

func _ready() -> void:
	# Measured footprints preserve the existing 303 and the occupied 304 frontage.
	lab = preload("res://scenes/education/TeachingLab.tscn").instantiate()
	add_child(lab); lab.global_position = Vector3(-34,24.12,-106)
	laboratories["301"]=lab
	for row in [["302","Bases de Datos",-64],["304-B","Ciberseguridad",-52],["305","Hardware y Soporte",-40],["306","Laboratorio General",38],["TÉCNICA","Servidores",50]]:
		var room := preload("res://scenes/education/TeachingLab.tscn").instantiate()
		room.room_number=row[0]; room.topic=row[1]
		add_child(room); room.global_position=Vector3(row[2],24.12,-154); room.rotation.y=PI
		laboratories[row[0]]=room
		safe_point(str(row[0])+" · "+str(row[1]),3,Vector3(row[2],0,-154),learn.bind(3,"profesor_datos" if row[0]=="302" else ""))
	laboratories["303"]=campaign.get_parent().get_node("Piso3/SalaDetrasLocal/Sala303")
	laboratories["303"].set_meta("education_topic","Redes y Telecomunicaciones")
	safe_point("301 · Practicar Programación",3,Vector3(-34,0,-106),learn.bind(3,"profesor_algoritmos"))
	safe_point("303 · Redes y Telecomunicaciones",3,Vector3(28,0,-128),learn.bind(3,"profesor_redes"))
	safe_point("Directorio académico · horarios ficticios",4,Vector3(48,0,-145),directory)
	missions = preload("res://scripts/education/educational_missions_v4.gd").new()
	missions.platform = self
	add_child(missions)
	routines = preload("res://scripts/education/campus_routines_v4.gd").new()
	routines.platform = self
	add_child(routines)
	story = preload("res://scripts/education/nexo_story_v4.gd").new()
	story.platform = self
	add_child(story)
	accessibility.platform = self
	accessibility.apply()
	summary.platform = self
	sound = preload("res://scripts/education/campus_audio_v4.gd").new(); sound.platform=self; add_child(sound)
	performance = preload("res://scripts/education/sector_performance_v4.gd").new(); performance.platform=self; add_child(performance)
	feedback = preload("res://scripts/education/combat_feedback_v4.gd").new(); feedback.platform=self; add_child(feedback)
	load_mentor_catalog.call_deferred()

func directory() -> void:
	var text := "Directorio ficticio del juego. No representa horarios ni datos personales reales.\n"
	var rooms := {"profesor_datos":"302 · Bases de Datos","profesor_algoritmos":"301 · Programación","profesor_redes":"303 · Redes","coordinador_profesores":"Sala de Profesores · sector docente","director":"Dirección de Informática · piso 8"}
	for id in campaign.academic_expansion.actors:
		var actor: Node = campaign.academic_expansion.actors[id]
		var sector := "ala oeste" if actor.global_position.x<0 else "ala este"
		if id in ["docente_enfermeria","docente_odontologia"]: sector="sector norte de Salud"
		elif id=="coordinador_profesores": sector="sector docente"
		text += "\n%s\nUbicación aproximada: piso %s · %s\nSala asociada: %s\nAtención del juego: 09:00–17:00\n" % [actor.config.display_name,actor.config.floor_number,sector,rooms.get(id,"Punto académico; sala numerada aún no asignada")]
	campaign.ui.dialog("DIRECTORIO ACADÉMICO",text,["VOLVER"],[campaign.ui.close_modal],true)
