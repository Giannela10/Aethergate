extends Node
## Additive quest definitions use the existing reward ledger and event persistence.
var catalog := preload("res://resources/education/incidents_v4.tres")
var CATALOG: Array = []

func _init() -> void: CATALOG=catalog.entries.duplicate(true)

func definition(id: String) -> Dictionary:
	for row in CATALOG:
		if row.id==id: return row
	return {}

func show_requests() -> void:
	var c: Node=platform.campaign
	var choices: Array=[]; var callbacks: Array=[]
	# Rotate the lead request on the game's fictional clock; reuse stable quest IDs.
	var shift := int(c.academics.current_time().minute/60)%maxi(1,catalog.requests.size())
	for offset in catalog.requests.size():
		var row: Dictionary=catalog.requests[(offset+shift)%catalog.requests.size()]
		if c.quests.definitions.has(row.quest_id) and c.quests.state(row.quest_id)!=2:
			choices.append(row.kind+" · "+c.quests.definitions[row.quest_id].title)
			callbacks.append(func():
				c.quests.start_quest(row.quest_id)
				c.ui.close_modal(); c.ui.notify("Solicitud registrada. Consulta M para seguir los objetivos; los premios no se repiten."))
	choices.append("VOLVER"); callbacks.append(c.ui.close_modal)
	c.ui.dialog("SOLICITUDES DEL CAMPUS","Incidentes del horario ficticio. Los encargos conservan sus IDs y recompensas existentes.",choices,callbacks,true)
var platform: Node
var state: Dictionary
var active_activity: RefCounted
var rescue_gate: StaticBody3D
var rescue_student: CharacterBody3D
var rescue_safe := Vector3(38,24.01,-147.3)
var rescue_contact := Vector3(38,24.01,-147)
var bugs: Array = []

func _ready() -> void:
	var c: Node = platform.campaign
	if not c.data.get("education_v4") is Dictionary: c.data["education_v4"] = {}
	state = c.data.education_v4
	if not state.get("mission_steps") is Dictionary: state["mission_steps"] = {}
	if not state.get("bug_hits") is Dictionary: state["bug_hits"]={}
	for row in CATALOG:
		c.quests._add(row.id,row.title,"Incidente NEXO · "+" → ".join(row.steps),false,"",[c.quests._req("education_task",row.id,"Resolver el incidente",row.steps.size())],{"xp":100,"credits":50})
		platform.safe_point(row.title,int(row.floor),Vector3(row.x,0,row.z),open.bind(row))
	c.quests.refresh()
	setup_rescue()
	platform.safe_point("Solicitudes del campus",1,Vector3(-35,0,-139),show_requests)
	var programming: Node=c.academic_expansion.actors.get("profesor_algoritmos")
	var positions: Array=programming.objective_positions if programming!=null else []
	for index in 3:
		if index>=positions.size(): continue
		var location = c.player.get_node("SeatController").safe_position(positions[index])
		if location==null: continue
		var bug := preload("res://scripts/education/mission_bug_v4.gd").new(); bug.missions=self; bug.bug_id="v4_bug_"+str(index)
		add_child(bug); bug.global_position=location; bugs.append(bug)

func setup_rescue() -> void:
	rescue_gate=StaticBody3D.new(); rescue_gate.name="NexoLab306Gate"; rescue_gate.collision_layer=0
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size=Vector3(2,3.3,0.15); mesh.mesh=box
	var material := StandardMaterial3D.new(); material.albedo_color=Color("1b779a"); mesh.material_override=material
	rescue_gate.add_child(mesh)
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size=box.size; collision.shape=shape; rescue_gate.add_child(collision)
	add_child(rescue_gate); rescue_gate.global_position=Vector3(38,25.77,-150.06)
	rescue_student=preload("res://scripts/education/escort_student_v4.gd").new(); rescue_student.mission=self; add_child(rescue_student)
	rescue_student.global_position=rescue_safe if int(state.mission_steps.get("v4_rescue",0))>=7 else Vector3(38,24.01,-156)
	platform.safe_point("Estudiante tras la puerta · Sala 306",3,rescue_contact,open.bind(definition("v4_rescue")))
	platform.safe_point("Panel de acceso · NEXO",3,Vector3(36,0,-147),open.bind(definition("v4_rescue")))
	platform.safe_point("Salida de seguridad del laboratorio",3,Vector3(38,0,-152.5),exit_lab)
	var label := Label3D.new(); label.text="ZONA SEGURA · PUNTO DE ENCUENTRO"; label.position=rescue_safe+Vector3.UP*2.8; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(label)

func exit_lab() -> void:
	platform.campaign.player.global_position=rescue_contact
	platform.campaign.player.velocity=Vector3.ZERO
	platform.campaign.ui.notify("Salida segura. Puedes volver a intentar la actividad sin perder progreso.")

func _process(_delta: float) -> void:
	if rescue_gate==null: return
	var active: bool=platform.campaign.quests.state("v4_rescue")==1 and int(state.mission_steps.get("v4_rescue",0))<6
	rescue_gate.visible=active
	rescue_gate.collision_layer=1 if active else 0

func open(row: Dictionary) -> void:
	var c: Node = platform.campaign
	if c.active_duel != null: return
	var step := int(state.mission_steps.get(row.id,0))
	if step >= row.steps.size():
		c.ui.dialog(row.title,"Gracias por ayudar. Este incidente ya está resuelto y no vuelve a entregar premios.",["CONTINUAR"],[c.ui.close_modal],true)
		return
	c.quests.start_quest(row.id)
	var detail := "Paso %d/%d: %s\n" % [step+1,row.steps.size(),row.steps[step]]
	if row.id == "v4_emergency": detail += "Ejercicio educativo ficticio. No es una instrucción de atención clínica.\n"
	detail += "La actividad académica requiere contenido publicado por un docente en la asignatura y piso correspondientes." if step == row.academic else "Inspecciona este punto del incidente y confirma para continuar."
	c.ui.dialog(row.title,detail,["REALIZAR ACTIVIDAD" if step == row.academic else "INSPECCIONAR Y CONTINUAR","AHORA NO"],[perform.bind(row,step),c.ui.close_modal],true)

func perform(row: Dictionary, expected_step: int) -> void:
	var c: Node = platform.campaign
	if int(state.mission_steps.get(row.id,0)) != expected_step: return
	if row.id=="v4_bugs" and expected_step==0:
		c.ui.close_modal(); c.ui.notify("Busca y elimina los tres Bugs digitales junto al área de Programación del piso 3. Tus armas funcionan contra ellos."); return
	if row.id=="v4_rescue":
		if expected_step<6 and c.player.global_position.distance_to(rescue_contact)>5:
			c.ui.close_modal(); c.ui.notify("Busca la puerta y el panel de la sala 306, al norte del piso 3."); return
		if expected_step==6:
			c.ui.close_modal(); c.ui.notify("Acompaña al estudiante hasta el pasillo seguro. Camina despacio y espera si se retrasa."); return
	if expected_step == row.academic:
		active_activity = preload("res://scripts/education/learning_activity_service.gd").new()
		active_activity.auth = c.get_node("/root/AuthManager")
		c.ui.dialog("CONSULTANDO ACTIVIDAD","Buscando actividad autorizada del piso…",[],[],true)
		var activity: Dictionary = await active_activity.fetch(int(row.floor),"mission")
		if activity.has("error"):
			c.ui.dialog("ACTIVIDAD PENDIENTE",activity.error,["VOLVER"],[open.bind(row)],true)
			return
		c.ui.dialog(row.title,"",[],[],true)
		var view := preload("res://scripts/education/learning_activity_view.gd").new()
		view.activity = activity
		view.answered.connect(func(answer): evaluate(row,expected_step,activity,answer))
		c.ui.column.add_child(view)
	else:
		advance(row,expected_step)

func evaluate(row: Dictionary, step: int, activity: Dictionary, answer: Variant) -> void:
	var c: Node = platform.campaign
	c.ui.dialog("VALIDANDO","Validación académica del servidor…",[],[],true)
	var result: Dictionary = await active_activity.submit(str(activity.id),answer,"mission")
	if result.has("error"):
		c.ui.dialog("SIN VALIDACIÓN",result.error,["REINTENTAR"],[open.bind(row)],true)
		return
	preload("res://scripts/education/academic_progress.gd").record(c.data,activity,result,"mission")
	if result.get("verified",false) and (result.get("correct",false)==true or result.get("reflection",false)):
		advance(row,step)
	else:
		c.save_game()
		c.ui.dialog("SIGUE APRENDIENDO",str(result.get("explanation","")),["REINTENTAR","AHORA NO"],[open.bind(row),c.ui.close_modal],true)

func advance(row: Dictionary, expected_step: int) -> void:
	if int(state.mission_steps.get(row.id,0)) != expected_step: return
	state.mission_steps[row.id] = expected_step+1
	platform.campaign.event("education_task",row.id)
	if expected_step+1 == row.steps.size(): state["reputation"] = int(state.get("reputation",0))+1
	platform.campaign.save_game()
	open(row)
