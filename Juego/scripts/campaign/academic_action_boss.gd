class_name AcademicActionBoss
extends "res://scripts/campaign/academic_boss.gd"
var objectives: Array[Node3D] = []
var objective_positions: Array[Vector3] = []
var activity := ""
var remaining := 0.0
var activity_cooldown := 9.0
var expected: Array[String] = []
var sequence_index := 0
var vulnerability := 0.0
var activity_count := 0
var last_question := -1
var question_bank: Array = []
var activity_label: Label3D
var pulse_t := 0.0
var pulses := 0
var remembered := ""
var bonus_choice := ""
var point_failures: Array[String] = []
func _ready() -> void:
	super._ready()
	question_bank = config.questions.duplicate(true) if not config.questions.is_empty() else load("res://scripts/campaign/academic_expansion_data.gd").ENGLISH_BANK.duplicate(true)
	activity_label = Label3D.new()
	activity_label.position.y = 3.2
	activity_label.font_size = 38
	activity_label.pixel_size = 0.006
	activity_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(activity_label)
func _physics_process(delta: float) -> void:
	if not combat_active(): return
	vulnerability = maxf(0,vulnerability-delta)
	if vulnerability > 0:
		stun_t = maxf(stun_t,0.2)
		attack_timer = maxf(attack_timer,0.3)
	if not activity.is_empty():
		remaining -= delta
		if activity == "listen":
			pulse_t -= delta
			if pulse_t <= 0 and pulses < 2:
				pulses += 1
				pulse_t = 1.6
				zone("PULSO "+str(pulses),global_position,1.3,0.8,0.25,8)
				activity_label.text = "PULSO "+str(pulses)
			if pulses == 2 and remaining < 4 and objectives.is_empty(): create_points(["IZQUIERDA","DERECHA"],"walk")
		if activity == "loop":
			pulse_t -= delta
			if pulse_t <= 0:
				pulse_t = 2.2
				zone("BUCLE · ACTIVA BREAK",home,1.7,1.0,0.3,8)
		if remaining <= 0: finish_activity(false)
	else:
		activity_cooldown -= delta
		if activity_cooldown <= 0 and vulnerability <= 0 and inside_arena(target.global_position):
			begin_activity()
	super._physics_process(delta)
func select_attack() -> void:
	if vulnerability > 0: return
	if phase == 3 and config.role == "ALGORITMOS": attack_timer = minf(attack_timer,2.8)
	if not activity.is_empty() and activity != "loop":
		start_attack(light_pattern())
		return
	if config.role in ["INGLES","ETICA"]: super.select_attack(); return
	var patterns: Array = {
		"DATOS":["REGISTRO CORRUPTO","DATOS DUPLICADOS","ERROR DE CONEXIÓN"],
		"ALGORITMOS":["BUG","ERROR DE SINTAXIS","STACK OVERFLOW"],
		"ENFERMERIA":["PRESIÓN","EMERGENCIA"],
		"ODONTOLOGIA":["TALADRO","ENJUAGUE"],
		"COORDINADOR":["CARPETAZO","DOCUMENTOS","HORARIO CAMBIADO"],
		"LENGUAJE":["RUIDO","INTERRUPCIÓN","MENSAJE CONFUSO"],
		"MATEMATICAS":["SUMA VECTORIAL","ÁNGULO","SECUENCIA"]
	}.get(config.role,["REGISTRO CORRUPTO"]).duplicate()
	patterns.erase(last_attack)
	start_attack(patterns.pick_random())
func light_pattern() -> String:
	return {"INGLES":"WORD SHOT","ETICA":"DUDA","LENGUAJE":"RUIDO","DATOS":"REGISTRO CORRUPTO","ALGORITMOS":"BUG","ENFERMERIA":"PRESIÓN","ODONTOLOGIA":"TALADRO","COORDINADOR":"DOCUMENTOS","MATEMATICAS":"SUMA VECTORIAL"}.get(config.role,"BUG")
func start_attack(pattern: String) -> void:
	super.start_attack(pattern)
	if not combat_active(): return
	match pattern:
		"ERROR DE CONEXIÓN","ENJUAGUE":
			zone(pattern,global_position,2.4,1.3,0.3,12)
		"ERROR DE SINTAXIS","TALADRO","INTERRUPCIÓN","CARPETAZO","ÁNGULO":
			zone(pattern,global_position,0.8 if pattern != "ÁNGULO" else 1.6,1.2,0.3,14,"damage",6.0,aim)
		"STACK OVERFLOW":
			zone(pattern+" · 1",aim_point,0.9,1.2,0.3,10)
			zone(pattern+" · 2",aim_point,1.8,2.2,0.3,10)
		"EMERGENCIA","HORARIO CAMBIADO":
			zone(pattern,aim_point,1.2,1.3,0.3,12)
			zone(pattern,aim_point+Vector3(3,0,0),0.9,1.8,0.3,12)
		"MENSAJE CONFUSO":
			zone("SEÑAL FALSA · SIN DAÑO",home+Vector3(3,0,0),1,0.4,1,0)
func resolve_attack() -> void:
	var pattern := current_attack
	super.resolve_attack()
	if not combat_active(): return
	match pattern:
		"REGISTRO CORRUPTO","BUG","DOCUMENTOS","RUIDO":
			shoot(pattern,aim,7.0,10)
		"DATOS DUPLICADOS":
			shoot("CORRUPTO",aim,7,12)
			shoot("COPIA FALSA",aim.rotated(Vector3.UP,0.35),6,0)
		"SUMA VECTORIAL","SECUENCIA":
			for angle in [-0.35,0.35]: shoot(pattern,aim.rotated(Vector3.UP,angle),7,10)
	if not activity.is_empty(): attack_timer = maxf(attack_timer,3.7)
func begin_activity() -> void:
	if not combat_active() or objective_positions.size() < 4: return
	clear_objectives()
	sequence_index = 0
	activity_count += 1
	remaining = 8.0
	pulses = 0
	pulse_t = 1.5
	var text := ""
	var tokens: Array = []
	var mode := "walk"
	match config.role:
		"DATOS":
			if phase == 1:
				activity = "duplicate"; tokens = ["REGISTRO VÁLIDO","DUPLICADO","DUPLICADO"]; expected.assign(["0"]); mode = "destroy"
				text = "DATOS DUPLICADOS · golpea REGISTRO VÁLIDO"
			elif activity_count % 2 == 0:
				activity = "join"; tokens = ["CLIENTE","PEDIDO","PRODUCTO"]; expected.assign(["0","1"]); mode = "use"; remaining = 12
				text = "JOIN · activa CLIENTE + PEDIDO con E"
			else:
				activity = "select"; tokens = ["CLIENTES","VENTAS","PRODUCTOS"]; expected.assign(["1"])
				text = "RELACIONES ACTIVADAS · busca el registro de VENTAS"
			if phase == 3: text = "CONSULTA FINAL · "+text
		"ALGORITMOS":
			if phase >= 2 and activity_count % 2 == 0:
				activity = "loop"; tokens = ["BREAK"]; expected.assign(["0"]); mode = "use"; remaining = 10
				text = "BUCLE INFINITO · activa BREAK con E"
			else:
				activity = "sequence"; tokens = ["INICIO","PROCESO","DECISIÓN","FIN"]; expected.assign(["0","1","2","3"]); remaining = 16
				text = ("DEBUG MODE · " if phase == 3 else "")+"ORDENA EL ALGORITMO: INICIO → PROCESO → DECISIÓN → FIN"
		"ENFERMERIA":
			if activity_count % 2 == 0:
				activity = "sequence"; tokens = ["DISPOSITIVO A","DISPOSITIVO B"]; expected.assign(["0","1"]); mode = "use"; remaining = 12
				text = "SIGNOS VITALES · activa A y B · simulación ficticia"
			else:
				activity = "sequence"; tokens = ["ROJO","AMARILLO","VERDE"]; expected.assign(["0","1","2"]); remaining = 14
				text = ("EMERGENCIA TOTAL · " if phase == 3 else "")+"TRIAJE SIMULADO: ROJO → AMARILLO → VERDE · ficción"
		"ODONTOLOGIA":
			activity = "plaque"; tokens = ["PLACA 1","PLACA 2","PLACA 3"]; expected.assign(["0","1","2"]); mode = "destroy"; remaining = 16
			text = "ELIMINA LA PLACA · golpea tres objetivos ficticios"
		"COORDINADOR":
			activity = "select"; tokens = ["301","405","602"]; expected.assign(["2"])
			text = "CAMBIO DE SALA · Profesor de Inglés → Sala 602"
		"INGLES":
			activity = "answer"
			var choices: Array = range(question_bank.size())
			choices.erase(last_question)
			last_question = choices.pick_random()
			var q: Dictionary = question_bank[last_question]
			tokens = ["A: "+q.a[0],"B: "+q.a[1],"C: "+q.a[2]]
			expected.assign([str(q.correct)])
			text = "ANSWER THIS · "+q.q
		"ETICA":
			activity = "decision"; tokens = ["PROTEGER","PERSEGUIR"]; expected.assign(["0","1"])
			text = "DECISIÓN DE JUEGO · protege el objetivo (defensa) o persigue (daño)"
		"LENGUAJE":
			if activity_count % 2 == 0:
				activity = "listen"; expected.assign(["0"]); remembered = "IZQUIERDA"; remaining = 8
				text = "ESCUCHA ACTIVA · después del segundo pulso ve a IZQUIERDA"
			else:
				activity = "sequence"; tokens = ["MAÑANA","TENEMOS","EXPOSICIÓN"]; expected.assign(["0","1","2"]); remaining = 13
				text = ("COMUNICA BAJO PRESIÓN · " if phase == 3 else "")+"MENSAJE CLARO: MAÑANA → TENEMOS → EXPOSICIÓN"
		"MATEMATICAS":
			activity = "select"
			if phase == 3 and activity_count % 2 == 0:
				activity = "geometry"; tokens = ["CÍRCULO SEGURO"]; expected.assign(["0"]); remaining = 7
				text = "GEOMETRÍA · entra al círculo azul antes de terminar el aviso"
			elif activity_count % 2 == 0:
				tokens = ["24","32","34"]; expected.assign(["1"]); text = "PATRÓN: 2, 4, 8, 16, ?"
			else:
				var bank: Array = [["6 × 4",["18","24","30"],1,"Suma 6 cuatro veces"],["12 ÷ 3",["3","4","6"],1,"Busca cuatro grupos de tres"],["9 + 7",["16","14","18"],0,"Completa diez y suma el resto"],["15 − 6",["8","10","9"],2,"Resta cinco y después uno"]]
				var q: Array = bank[(activity_count/2) as int % bank.size()]
				tokens = q[1]; expected.assign([str(q[2])]); text = "OPERACIÓN: "+q[0]
				if load("res://scripts/campaign/academic_expansion_data.gd").reward_owned(target,"CalculadoraAvanzada"): text += " · Pista: "+q[3]
			if phase == 3: text = "ECUACIÓN FINAL · "+text
	if activity.is_empty(): activity_cooldown = 12; return
	if config.role in ["INGLES","LENGUAJE"] and target.inventory.has_item("AudifonosDeTraduccion",1): remaining += 2
	activity_label.text = text
	duel.campaign.ui.notify(text,4)
	if not tokens.is_empty(): create_points(tokens,mode)
func create_points(tokens: Array, mode: String) -> void:
	for i in tokens.size():
		var objective = load("res://scripts/campaign/academic_objective.gd").new()
		objective.boss = self
		objective.token = str(i)
		objective.caption = str(tokens[i])
		objective.mode = mode
		get_parent().add_child(objective)
		objective.global_position = objective_positions[i]
		objectives.append(objective)
func objective_selected(token: String, objective: Node3D) -> void:
	if not combat_active() or activity.is_empty() or not objectives.has(objective): return
	if activity == "listen" and pulses < 2: return
	if activity == "decision":
		bonus_choice = "PROTEGER" if token == "0" else "PERSEGUIR"
		finish_activity(true)
		return
	if activity == "plaque":
		if not expected.has(token): return
		expected.erase(token)
		objective.retire()
		if expected.is_empty():
			clear_objectives()
			activity = "caries"
			expected.assign(["0"])
			create_points(["CARIES · PUNTO DÉBIL"],"destroy")
			activity_label.text = "GOLPEA CARIES · abre una ventana de ataque"
		return
	if expected.is_empty(): return
	if token != expected[sequence_index]:
		if activity in ["sequence","join"]:
			sequence_index = 0
			for point in objectives:
				if is_instance_valid(point): point.enabled = true; point.show()
			duel.campaign.ui.notify("Secuencia reiniciada · vuelve al primer punto",2)
			zone("ERROR · SAL DEL AVISO",target.global_position,0.9,1.3,0.3,6)
		else: finish_activity(false)
		return
	sequence_index += 1
	objective.enabled = false
	objective.hide()
	if sequence_index >= expected.size(): finish_activity(true)
func finish_activity(success: bool) -> void:
	var previous := activity
	clear_objectives()
	activity = ""
	remaining = 0
	activity_cooldown = 12 if phase == 1 else 10
	if success:
		vulnerability = 5.0
		charge = 0; current_attack = ""; attack_timer = 5
		stun_t = 5
		activity_label.text = "APERTURA · 5 SEGUNDOS"
		if config.role == "INGLES":
			var combat = target.get_node("CombatExtensions")
			combat.stamina = minf(combat.max_stamina,combat.stamina+10)
	else:
		activity_label.text = "CONTINÚA EL COMBATE"
		if previous == "geometry": zone("FUERA DEL CÍRCULO",target.global_position,0.9,1.5,0.3,8)
		else: shoot("PRESIÓN ADICIONAL",global_position.direction_to(target.global_position),5,6)
func clear_objectives() -> void:
	for point in objectives:
		if is_instance_valid(point): point.retire()
	objectives.clear()
func take_hit(direction: Vector3, damage: float) -> void:
	var factor := 1.1 if bonus_choice == "PERSEGUIR" else 1.0
	super.take_hit(direction,damage*factor)
func phase_title(default_text: String) -> String:
	var titles: Array = {
			"DATOS":["RELACIONES ACTIVADAS","CONSULTA FINAL"],
			"ALGORITMOS":["ORDENA EL ALGORITMO","DEBUG MODE"],
			"ENFERMERIA":["TRIAJE SIMULADO","EMERGENCIA TOTAL"],
			"ODONTOLOGIA":["ELIMINA LA PLACA","LIMPIEZA FINAL"],
			"COORDINADOR":["CAMBIO DE SALA","HORARIO CAMBIADO"],
			"LENGUAJE":["MENSAJE CLARO","COMUNICA BAJO PRESIÓN"],
			"MATEMATICAS":["OPERACIÓN","GEOMETRÍA"]
		}.get(config.role,[])
	return titles[phase-2] if not titles.is_empty() else default_text
func hit_player(damage: float) -> void:
	super.hit_player(damage*(0.9 if bonus_choice == "PROTEGER" else 1.0))
func clear_academic_effects() -> void:
	clear_objectives()
	activity = ""; remaining = 0; vulnerability = 0; bonus_choice = ""
	if is_instance_valid(activity_label): activity_label.text = ""
	super.clear_academic_effects()
func reset_academic_duel() -> void:
	super.reset_academic_duel()
	activity_cooldown = 9; sequence_index = 0; activity_count = 0; last_question = -1
