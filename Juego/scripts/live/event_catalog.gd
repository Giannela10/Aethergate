extends RefCounted
const EventData = preload("res://scripts/live/event_data.gd")
static func build() -> Array[Resource]:
	var result: Array[Resource] = []
	var rows := [
		["entrada","Movimiento en la entrada",["1"],"npc","INSPECT","FOLDER"],
		["casino_almuerzo","Hora de almuerzo",["1"],"casino","EAT","COFFEE"],
		["biblioteca_estudio","Grupo de estudio",["2"],"biblioteca","READ","BOOK"],
		["tecnico_sistema","Técnico investigando el sistema",["3"],"computer","INSPECT","TABLET"],
		["docentes_reunion","Reunión de profesores",["4"],"teachers","READ","FOLDER"],
		["evaluacion","Evaluación en curso",["5","6","7","8"],"academic","WRITE","FOLDER"],
		["trabajo_grupo","Trabajo en grupo",["3","5","6","7","8"],"academic","TYPE","TABLET"],
		["profesor_salida","Profesor saliendo de clase",["5","6","7","8"],"academic","INSPECT","FOLDER"],
		["taller_inspeccion","Revisión visual de piezas",["-1"],"workshop","INSPECT","TOOL"],
		["ascensor_espera","Esperando el ascensor",["1","2","3","4","5","6","7","8","-1"],"elevator","PHONE","PHONE"],
		["descuento_raro","Descuento temporal del campus",["1","4","8"],"vendor","INSPECT","NONE"],
		["objeto_caido","Una carpeta en el suelo",["1","2","3","5","6","7","8"],"npc","INSPECT","FOLDER"],
		["orientar","¿Dónde queda la sala?",["1","2","3","5","6","7","8"],"npc","INSPECT","FOLDER"],
		["fallo_breve","Revisión breve del computador",["3"],"computer","REPAIR","TABLET"],
		["pausa_positiva","Un pequeño agradecimiento",["1","2"],"npc","INSPECT","NONE"],
		["rumor_raro","Alguien vio algo extraño",["3","8"],"npc","PHONE","PHONE"],
		["primer_fallo","Primer fallo NEXO",["3"],"computer","INSPECT","TABLET"],
		["interferencia_nexo","Interferencia en una pantalla",["1","2","3","4","5","6","7","8","-1"],"computer","INSPECT","NONE"],
		["pulso_nexo","Pulso de interferencia",["1","2","3","4","5","6","7","8","-1"],"computer","INSPECT","NONE"],
		["discusion_docente","Dos profesores comparan notas",["4"],"teachers","READ","FOLDER"]]
	for row in rows:
		var event := EventData.new()
		event.event_id = row[0]; event.title = row[1]
		event.floors.assign(row[2]); event.anchor = row[3]; event.action = row[4]; event.prop = row[5]
		event.duration = 120
		if event.event_id == "casino_almuerzo": event.minute_start = 720; event.minute_end = 840
		if event.event_id in ["docentes_reunion","discusion_docente"]: event.sector = "teachers"
		if event.event_id in ["primer_fallo","tecnico_sistema","discusion_docente","rumor_raro"]: event.unique = true
		if event.event_id in ["pulso_nexo","rumor_raro","descuento_raro"]: event.rare = true
		if event.event_id in ["primer_fallo","pulso_nexo"]:
			event.minimum_anomaly = 1; event.nexo = true
		if event.event_id == "interferencia_nexo": event.minimum_anomaly = 2; event.nexo = true
		if event.event_id == "profesor_salida": event.minute_start = 660; event.minute_end = 1080
		if event.event_id in ["objeto_caido","orientar","pausa_positiva","fallo_breve"]: event.situation = event.event_id
		result.append(event)
	return result
