extends "res://scripts/juego/game_files.gd"
## Variantes de la clasificación existente; no añaden IDs de minijuego.
const PROFILES := {
	"pc4": {"title":"Organización docente", "help":"Clasifica los documentos de la oficina de profesores.", "categories":["Evaluación","Horario","Material","Solicitud"], "hints":["pruebas y rúbricas","clases y reuniones","guías y lecturas","permisos y reservas"], "cards":[["Rúbrica del semestre",0],["Prueba de unidad",0],["Calendario de clases",1],["Agenda de reuniones",1],["Guía de estudio",2],["Lectura para la clase",2],["Reserva de sala",3],["Permiso de ausencia",3]]},
	"pc5": {"title":"Inglés: vocabulario", "help":"Clasifica cada palabra en inglés según su significado.", "categories":["Personas","Lugares","Acciones","Objetos"], "hints":["people","places","actions","objects"], "cards":[["Teacher",0],["Student",0],["Library",1],["Classroom",1],["Read",2],["Write",2],["Book",3],["Pencil",3]]},
	"pc6": {"title":"Comunicación: comprensión lectora", "help":"Texto: Ana estudia en la biblioteca. Consulta dos libros y prepara su exposición.\nClasifica cada fragmento según la información que aporta.", "categories":["Quién","Dónde","Qué hace","Para qué"], "hints":["persona","lugar","acción","propósito"], "cards":[["Ana",0],["La estudiante Ana",0],["En la biblioteca",1],["La biblioteca del campus",1],["Consulta dos libros",2],["Estudia",2],["Para preparar su exposición",3],["Para exponer ante su curso",3]]},
	"pc7": {"title":"Ética: decisiones cotidianas", "help":"Relaciona cada decisión con el valor que expresa.\nLee las categorías antes de responder.", "categories":["Honestidad","Respeto","Solidaridad","Responsabilidad"], "hints":["decir la verdad","escuchar y cuidar","ayudar a otros","cumplir compromisos"], "cards":[["Reconocer un error propio",0],["Devolver una billetera encontrada",0],["Escuchar sin interrumpir",1],["Cuidar el espacio compartido",1],["Ayudar a quien se perdió",2],["Compartir apuntes con un ausente",2],["Entregar el trabajo a tiempo",3],["Cumplir una tarea acordada",3]]},
	"pc8": {"title":"NEXO: revisión de documentos", "help":"Organiza la información del informe NEXO.\nEs una revisión documental previa al encuentro con el Director.", "categories":["Antecedente","Observación","Acción","Seguimiento"], "hints":["historia del proyecto","hechos registrados","pasos propuestos","comprobar resultados"], "cards":[["NEXO nació como proyecto del campus",0],["El informe reúne registros previos",0],["Se registraron anomalías en el campus",1],["El archivo está en el taller del −1",1],["Consultar al Director de Carrera",2],["Revisar el archivo de mantención",2],["Verificar la restauración del campus",3],["Registrar el resultado de la revisión",3]]}
}

static func title_for(profile: String) -> String:
	return str(PROFILES.get(profile,{}).get("title",""))

func start() -> void:
	super.start()
	file_label.add_theme_font_size_override("font_size",24)

func configure_activity(profile: String) -> void:
	var definition: Dictionary = PROFILES[profile]
	instructions = definition.help
	category_hint = "Selecciona la categoría que corresponde"
	progress_caption = "Respuestas correctas"
	wrong_answer = "Revisa el significado y las pistas de las categorías."
	all_files = definition.cards.duplicate(true)
	for i in folders.size():
		folders[i] = folders[i].duplicate()
		folders[i].name = definition.categories[i]
		folders[i].hint = definition.hints[i]
