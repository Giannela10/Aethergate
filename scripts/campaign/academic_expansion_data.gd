class_name AcademicExpansionData
extends RefCounted
# Stable IDs are save keys, never display names.
const BOSSES = {
	"profesor_datos":{"name":"Profesor de Bases de Datos","floor":3,"hp":500.0,"role":"DATOS","reward":"LlaveDeDatos","sector":"Informática · ala oeste","seeds":[[-45,-137],[-35,-137],[-52,-137]]},
	"profesor_algoritmos":{"name":"Profesor de Algoritmos y Programación","floor":3,"hp":525.0,"role":"ALGORITMOS","reward":"DepuradorPortatil","sector":"Informática · ala este","seeds":[[30,-130],[43,-132],[35,-140]]},
	"docente_enfermeria":{"name":"Docente de Enfermería","floor":4,"hp":475.0,"role":"ENFERMERIA","reward":"KitClinicoMejorado","sector":"Sector norte · salud","seeds":[[-45,-137],[-60,-137],[-25,-137]]},
	"docente_odontologia":{"name":"Docente de Odontología","floor":4,"hp":475.0,"role":"ODONTOLOGIA","reward":"ProtectorDental","sector":"Sector norte · salud","seeds":[[-25,-145],[-45,-156],[-60,-156]]},
	"coordinador_profesores":{"name":"Coordinador de Profesores","floor":4,"hp":500.0,"role":"COORDINADOR","reward":"MapaDocente","sector":"Sala de Profesores","seeds":[[48,-145],[52,-145],[58,-145]]},
	"profesor_matematicas":{"name":"Profesor de Matemáticas","floor":7,"hp":525.0,"role":"MATEMATICAS","reward":"CalculadoraAvanzada","sector":"Formación general · ala oeste","seeds":[[-52,-132],[-43,-132],[-35,-140]]}
}
const REWARDS = {
	"profesor_datos":["LlaveDeDatos","Llave de datos","Desbloquea una pista adicional en las pruebas informáticas del Director."],
	"profesor_algoritmos":["DepuradorPortatil","Depurador portátil","Reduce un 15% la duración de ralentizaciones tecnológicas y tinta."],
	"docente_enfermeria":["KitClinicoMejorado","Kit clínico mejorado","Los botiquines recuperan 5 puntos de vida adicionales."],
	"docente_odontologia":["ProtectorDental","Protector dental","Reduce un 10% el empuje al recibir impactos. No reduce daño."],
	"coordinador_profesores":["MapaDocente","Mapa docente","Añade al mapa y contactos sectores aproximados de docentes ya conocidos."],
	"profesor_ingles":["AudifonosDeTraduccion","Audífonos de traducción","Añade 2 segundos a actividades físicas de idioma y comunicación."],
	"profesor_etica":["InsigniaDeIntegridad","Insignia de integridad","Reduce un 10% adicional la duración de ralentizaciones tecnológicas y tinta."],
	"profesor_lenguaje":["InsigniaDeOratoria","Insignia de oratoria","Entrega una colación por cada misión de ayuda completada; una sola vez por misión."],
	"profesor_matematicas":["CalculadoraAvanzada","Calculadora avanzada","Muestra tiempo restante de preparación en ataques compatibles y pistas numéricas; no responde automáticamente."]
}
const ENGLISH_BANK = [
	{"q":"Yesterday I ___ to class.","a":["GO","WENT","GONE"],"correct":1},
	{"q":"She ___ a student.","a":["IS","ARE","AM"],"correct":0},
	{"q":"Choose a place to read.","a":["PENCIL","RUN","LIBRARY"],"correct":2},
	{"q":"The opposite of early is ___.","a":["LATE","SMALL","BLUE"],"correct":0},
	{"q":"We ___ English every week.","a":["STUDIES","STUDY","STUDIED YESTERDAY"],"correct":1},
	{"q":"Last night she ___ a book.","a":["READ","READS","READING"],"correct":0}
]
static func migrate(raw: Dictionary) -> Dictionary:
	var data := raw.duplicate(true)
	var state = data.get("academic_expansion",{})
	if not state is Dictionary: state = {}
	for key in ["flags","seen"]:
		if not state.get(key) is Dictionary: state[key] = {}
	state["version"] = 1
	var bosses = data.get("bosses",{})
	if bosses is Dictionary and bosses.get("director",false) == true:
		for flag in ["director_task_network","director_task_antivirus","director_task_config"]: state.flags[flag] = true
	var events = data.get("events",{})
	if events is Dictionary:
		for id in ["profesor_ingles","profesor_lenguaje","profesor_etica","profesor_algoritmos","profesor_matematicas","profesor_datos"]:
			if int(events.get("talk:"+id,0)) > 0: state.seen[id] = true
	data["academic_expansion"] = state
	return data
static func reward_owned(player: Node, item: String) -> bool:
	return player != null and player.inventory != null and player.inventory.has_item(item,1)
