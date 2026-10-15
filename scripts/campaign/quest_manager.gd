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
	_add("seguridad6","Práctica avanzada","Supera el desafío del sexto piso.",true,"academico5",[_req("computer","pc6","Completa el desafío de seguridad")],{"credits":60,"xp":100,"unlock":"7"})
	_add("acceso7","Acceso restringido","Consigue la TarjetaAcceso mediante la entrega de documentos.",true,"seguridad6",[_req("door","acceso7","Abre el acceso restringido del Piso 7"),_req("computer","pc7","Completa el computador del Piso 7")],{"credits":80,"xp":120,"unlock":"8"})
	_add("direccion","Modo Administrador","Completa el desafío tecnológico y enfrenta al Director.",true,"acceso7",[_req("computer","pc8","Resuelve el desafío tecnológico"),_req("boss","director","Habla y vence al Director")],{"credits":150,"xp":250,"unlock":"S"})
	_add("postgame","Archivos del subterráneo","Explora el subterráneo y encuentra el archivo secreto.",true,"direccion",[_req("secret","archivo_subterraneo","Encuentra el archivo del subterráneo")],{"credits":100,"xp":200})
	_add("llaves","Las llaves perdidas","El auxiliar perdió sus llaves en otro piso.",false,"",[_req("deliver","llaves","Entrega las llaves al auxiliar")],{"credits":25,"xp":40,"items":{"Botiquin":1}})
	_add("cargador","El cargador","Encuentra el cargador y devuélvelo al estudiante.",false,"",[_req("deliver","cargador","Entrega el cargador")],{"credits":20,"xp":30,"items":{"BebidaEnergetica":1}})
	_add("documentos","Documentos importantes","Lleva los documentos del profesor al funcionario del Piso 5.",false,"",[_req("deliver","documentos","Entrega los documentos")],{"credits":40,"xp":70,"items":{"TarjetaAcceso":1}})
	_add("implementos","Implementos perdidos","Encuentra un balón, una paleta y una raqueta.",false,"",[_req("deliver","implementos","Devuelve los tres implementos")],{"credits":35,"xp":50,"items":{"PaletaPingPong":1}})
	_add("infectado","Computador infectado","Resuelve el minijuego Antivirus del Piso 3.",false,"",[_req("computer","pc3","Elimina los virus")],{"credits":30,"xp":50,"items":{"USBInfectado":1}})
	_add("casino","Ayuda en el casino","Habla con el Chef y acepta su desafío.",false,"",[_req("duel_started","chef","Inicia el duelo con el Chef")],{"credits":15,"xp":25})
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
	# Permitir continuar partidas anteriores con el boss o computador ya resuelto.
	if requirement.kind == "talk" and campaign.data.bosses.get(requirement.id,false):
		return mini(1,int(requirement.amount))
	if requirement.kind == "computer" and campaign.data.computers.get(requirement.id,false):
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
