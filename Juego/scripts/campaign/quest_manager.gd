extends Node
const Quest = preload("res://scripts/campaign/quest.gd")
var campaign: Node
var definitions: Dictionary = {}
var updating := false

func _ready() -> void:
	_add("inicio","Primer día","Conoce el campus y supera los desafíos del primer piso.",true,"",[
		_req("talk","punto","Habla con Punto Estudiantil"),_req("collect","*","Recoge tu primer objeto"),_req("computer","pc_intro","Completa el computador inicial"),_req("boss","punto","Derrota al Encargado"),_req("boss","chef","Habla y vence al Chef")],{"credits":60,"xp":100,"unlock":"2"})
	_add("biblioteca","La guardiana del conocimiento","Busca tres libros y demuestra lo que sabes.",true,"inicio",[_req("floor","2","Visita la biblioteca"),_req("collect","LibroBiblioteca","Busca tres libros",3),_req("boss","bibliotecaria","Supera el duelo de preguntas")],{"credits":60,"xp":120,"unlock":"3"})
	for floor_number in [3,4,5]:
		var previous := "biblioteca" if floor_number == 3 else "academico%d" % (floor_number-1)
		_add("academico%d" % floor_number,"Etapa académica · Piso %d" % floor_number,"Completa la tarea del computador del piso.",true,previous,[_req("floor",str(floor_number),"Llega al piso %d" % floor_number),_req("computer","pc%d" % floor_number,"Resuelve el desafío académico")],{"credits":40,"xp":80,"unlock":str(floor_number+1)})
	_add("seguridad6","Práctica de Lenguaje","Supera la comprensión lectora del sexto piso.",true,"academico5",[_req("computer","pc6","Completa la actividad de Lenguaje")],{"credits":60,"xp":100,"unlock":"7"})
	_add("acceso7","Acceso restringido","Consigue la TarjetaAcceso mediante la entrega de documentos.",true,"seguridad6",[_req("door","acceso7","Abre el acceso restringido del Piso 7"),_req("computer","pc7","Completa el computador del Piso 7")],{"credits":80,"xp":120,"unlock":"8"})
	_add("direccion","Modo Administrador","Revisa el informe NEXO y enfrenta al Director.",true,"acceso7",[_req("computer","pc8","Organiza los documentos NEXO"),_req("boss","director","Habla y vence al Director")],{"credits":150,"xp":250,"unlock":"S"})
	_add("postgame","Archivos del subterráneo","Explora el subterráneo y encuentra el archivo secreto.",true,"direccion",[_req("secret","archivo_subterraneo","Encuentra el archivo del subterráneo")],{"credits":100,"xp":200})
	_add("nexo_final","El núcleo de Proyecto NEXO","El archivo revela el centro de control industrial del −1. Puedes prepararte antes del último duelo.",true,"postgame",[_req("door","nexo_core","Encuentra el núcleo de NEXO"),_req("boss","nexo","Desactiva NEXO")],{})
	_add("llaves","Las llaves perdidas","El auxiliar perdió sus llaves en otro piso.",false,"",[_req("deliver","llaves","Entrega las llaves al auxiliar")],{"credits":25,"xp":40,"items":{"Botiquin":1}})
	_add("cargador","El cargador","Encuentra el cargador y devuélvelo al estudiante.",false,"",[_req("deliver","cargador","Entrega el cargador")],{"credits":20,"xp":30,"items":{"BebidaEnergetica":1}})
	_add("documentos","Documentos importantes","Lleva los documentos del profesor al funcionario del Piso 5.",false,"",[_req("deliver","documentos","Entrega los documentos")],{"credits":40,"xp":70,"items":{"TarjetaAcceso":1}})
	_add("implementos","Implementos perdidos","Encuentra un balón, una paleta y una raqueta.",false,"",[_req("deliver","implementos","Devuelve los tres implementos")],{"credits":35,"xp":50,"items":{"PaletaPingPong":1}})
	_add("infectado","Computador infectado","Resuelve el minijuego Antivirus del Piso 3.",false,"",[_req("computer","pc3","Elimina los virus")],{"credits":30,"xp":50,"items":{"USBInfectado":1}})
	_add("casino","Ayuda en el casino","Habla con el Chef y acepta su desafío.",false,"",[_req("duel_started","chef","Inicia el duelo con el Chef")],{"credits":15,"xp":25})
	# Mismos IDs/recompensas/cadena; los computadores superiores son preparación.
	# Estados COMPLETED antiguos nunca se reabren ni pierden desbloqueos.
	for row in [["academico5","pc5","profesor_ingles","Profesor de Inglés"],["seguridad6","pc6","profesor_lenguaje","Profesor de Lenguaje"],["acceso7","pc7","profesor_etica","Profesor de Ética"],["direccion","pc8","director","Director"]]:
		var quest = definitions[row[0]]
		for requirement in quest.requirements:
			if requirement.kind == "computer" and requirement.id == row[1]:
				requirement["optional"] = true
				requirement.text += " (preparación opcional)"
		if row[0] != "direccion": quest.requirements.append(_req("boss",row[2],"Habla y vence al "+row[3]))
		quest.description = "Duelo de acción con "+row[3]+". El computador da una ventaja opcional."
	for task in [["director_task_network","PC sin conexión"],["director_task_antivirus","Equipo infectado"],["director_task_config","Configuración de red"]]:
		_add(task[0],task[1],"Resuelve la prueba informática señalizada del piso 8.",false,"",[_req("academic_task",task[0],task[1])],{})
		definitions.direccion.requirements.append(_req("academic_task",task[0],task[1]))
	# Preserve completed states and the existing reward/unlock chain.
	for id in ["academico5","seguridad6","acceso7"]:
		var quest = definitions[id]
		quest.requirements = quest.requirements.filter(func(r): return r.kind != "boss")
		if id == "academico5":
			quest.title = "Formación general · Piso 5"
			quest.description = "Explora el piso 5 y conoce sus servicios generales."
		if id == "seguridad6":
			quest.title = "Encuentro académico · Piso 6"
			quest.description = "Explora formación general. Inglés y Ética son desafíos opcionales."
			quest.requirements.append(_req("floor","6","Visita el piso 6"))
		if id == "acceso7":
			quest.description = "Abre el acceso con TarjetaAcceso y explora el piso 7. Sus duelos son opcionales."
			quest.requirements.append(_req("floor","7","Visita el piso 7"))
	definitions.academico3.requirements.append(_req("academic_any","piso3","Supera Bases de Datos o Algoritmos"))
	_add("ubicar_profesores","Ubicar profesores","Habla con Algoritmos (3), Inglés (6) y Matemáticas (7). No necesitas derrotarlos; regresa al coordinador.",false,"",[
		_req("talk","profesor_algoritmos","Localiza Algoritmos · piso 3 · Informática"),
		_req("talk","profesor_ingles","Localiza Inglés · piso 6 · formación general"),
		_req("talk","profesor_matematicas","Localiza Matemáticas · piso 7 · formación general"),
		_req("academic_return","coordinador","Regresa a Sala de Profesores · piso 4")],{})
	refresh()

func _req(kind: String, id: String, text: String, amount: int = 1) -> Dictionary:
	return {"kind":kind,"id":id,"text":text,"amount":amount}

func _add(id: String, title: String, text: String, main: bool, prerequisite: String, requirements: Array, reward: Dictionary) -> void:
	var quest := Quest.new()
	quest.quest_id = id
	quest.title = title
	quest.description = text
	quest.main_quest = main
	quest.prerequisite = prerequisite
	quest.requirements.assign(requirements)
	quest.reward = reward
	definitions[id] = quest
	if not campaign.data.quests.has(id):
		campaign.data.quests[id] = {"state":Quest.State.NOT_STARTED}

func state(id: String) -> int:
	return int(campaign.data.quests.get(id,{}).get("state",0))

func start_quest(id: String) -> void:
	if definitions.has(id) and state(id) == Quest.State.NOT_STARTED:
		campaign.data.quests[id].state = Quest.State.ACTIVE
		campaign.ui.notify("Misión iniciada: "+definitions[id].title)
		refresh()
		campaign.save_game()

func progress(requirement: Dictionary) -> int:
	if requirement.kind == "academic_any":
		return 1 if campaign.data.bosses.get("profesor_datos",false) or campaign.data.bosses.get("profesor_algoritmos",false) else 0
	if requirement.kind == "academic_task":
		return 1 if campaign.data.academic_expansion.flags.get(requirement.id,false) else 0
	if requirement.kind == "academic_return":
		return 1 if campaign.data.academic_expansion.flags.get("coordinator_returned",false) else 0
	# Permitir continuar partidas anteriores con el boss o computador ya resuelto.
	if requirement.kind == "talk" and campaign.data.bosses.get(requirement.id,false):
		return mini(1,int(requirement.amount))
	if requirement.kind == "computer" and campaign.data.computers.get(requirement.id,false):
		return mini(1,int(requirement.amount))
	if requirement.kind == "boss" and campaign.data.bosses.get(requirement.id,false):
		return mini(1,int(requirement.amount))
	if requirement.id == "*":
		var total := 0
		for key in campaign.events:
			if str(key).begins_with(requirement.kind+":"):
				total += int(campaign.events[key])
		return mini(total,requirement.amount)
	return mini(int(campaign.events.get(requirement.kind+":"+requirement.id,0)),int(requirement.amount))

func refresh() -> void:
	if updating:
		return
	updating = true
	for id in definitions:
		var quest = definitions[id]
		if quest.main_quest and state(id) == Quest.State.NOT_STARTED and (quest.prerequisite.is_empty() or state(quest.prerequisite) == Quest.State.COMPLETED):
			campaign.data.quests[id].state = Quest.State.ACTIVE
		if state(id) != Quest.State.ACTIVE:
			continue
		var complete := true
		for requirement in quest.requirements:
			if requirement.get("optional",false): continue
			complete = complete and progress(requirement) >= requirement.amount
		if complete:
			campaign.data.quests[id].state = Quest.State.COMPLETED
			campaign.grant_reward(quest.reward,"quest:"+id)
			campaign.ui.notify("Misión completada: "+quest.title)
	updating = false
	campaign.save_game()

func objective_text() -> String:
	for id in definitions:
		if state(id) == Quest.State.ACTIVE and definitions[id].main_quest:
			for requirement in definitions[id].requirements:
				if requirement.get("optional",false): continue
				if progress(requirement) < requirement.amount:
					return definitions[id].title+"\n"+requirement.text+" (%d/%d)" % [progress(requirement),requirement.amount]
	return "Explora el campus y busca misiones secundarias."

func describe() -> String:
	var text := "MISIÓN PRINCIPAL\n"
	for main in [true,false]:
		if not main:
			text += "\nMISIONES SECUNDARIAS\n"
		for id in definitions:
			var quest = definitions[id]
			if quest.main_quest != main:
				continue
			text += "\n%s · %s\n%s\n" % [quest.title,["Sin iniciar","Activa","Completada","Fallida"][state(id)],quest.description]
			for requirement in quest.requirements:
				text += "  %s: %d/%d\n" % [requirement.text,progress(requirement),requirement.amount]
			text += "Recompensa: %s\n" % str(quest.reward)
	return text
func fail_quest(id: String) -> void:
	if definitions.has(id) and state(id) == Quest.State.ACTIVE:
		campaign.data.quests[id].state = Quest.State.FAILED
		campaign.ui.notify("Misión fallida: "+definitions[id].title)
		campaign.save_game()
