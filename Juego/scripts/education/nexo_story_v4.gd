extends Node
var platform: Node
var state: Dictionary
var elapsed := 0.0
const CHAPTERS := [
	["I · La interrupción","Durante una jornada de clases, el sistema experimental NEXO bloquea accesos y altera las simulaciones. Punto Estudiantil solicita ayuda. Los docentes serán tus aliados."],
	["II · Aprender para reparar","La biblioteca revela los primeros registros. En Informática, Bases de Datos, Algoritmos y Redes enseñan a identificar el origen de los errores. Practica antes de activar una simulación."],
	["III · El campus responde","Los incidentes alcanzan Salud, los sectores docentes y formación general. Ayuda a tus compañeros, consulta el directorio y reúne herramientas sin atacar a personas."],
	["IV · La evaluación integradora","El Director de Informática reúne las pruebas de conexión, antivirus y configuración. Su simulación final prepara el acceso al núcleo industrial."],
	["V · El núcleo NEXO","El archivo del subterráneo revela la fuente del incidente. NEXO permanece como enemigo final. Puedes prepararte y volver a intentarlo desde tus checkpoints."],
	["EPÍLOGO · El instituto vuelve a encontrarse","NEXO ha sido desactivado. Estudiantes y docentes recuperan el campus. El conocimiento y la colaboración permitieron resolver el incidente. Puedes continuar explorando."]
]
func _ready() -> void:
	var c: Node = platform.campaign
	state = c.data.education_v4
	var legacy_started: bool=c.loaded_save and (float(c.data.stats.get("time_played",0))>5 or c.data.bosses.values().any(func(value): return value==true))
	if not state.get("story") is Dictionary: state["story"] = {"intro_seen":legacy_started,"chapter":chapter()}
	c.gameplay_event.connect(_event)
func chapter() -> int:
	var c: Node = platform.campaign
	if c.data.bosses.get("nexo",false): return 5
	if c.data.bosses.get("director",false): return 4
	if c.floor_unlocked("8"): return 3
	if c.data.bosses.get("profesor_datos",false) or c.data.bosses.get("profesor_algoritmos",false): return 2
	if c.data.bosses.get("bibliotecaria",false): return 1
	return 0
func _event(_kind: String, _id: String, _amount: int) -> void:
	var next := chapter()
	if next>int(state.story.chapter):
		state.story.chapter = next
		platform.campaign.ui.notify("EL INCIDENTE NEXO\n"+str(CHAPTERS[next][0]),6)
func _process(delta: float) -> void:
	var c: Node = platform.campaign
	if not c.persist or c.has_meta("test_mode") or c.save_path!="user://campus_campaign_v1.json" or get_tree().get_meta("education_v4_suppress_story",false) or state.story.intro_seen: return
	elapsed += delta
	if elapsed<3 or c.ui.modal or c.player.busy or c.active_duel!=null: return
	state.story.intro_seen = true
	c.save_game()
	show_chapter(0)
func show_chapter(index: int = -1) -> void:
	if index<0: index = chapter()
	platform.campaign.ui.dialog("DUOCGAMES: EL INCIDENTE NEXO\n"+str(CHAPTERS[index][0]),str(CHAPTERS[index][1]),["CONTINUAR","CRÉDITOS Y ESTADÍSTICAS"],[platform.campaign.ui.close_modal,credits],true)
func credits() -> void:
	var c: Node = platform.campaign
	var text := "DuocGames · Proyecto educativo en desarrollo\nPersonajes y horarios ficticios. Los resultados del juego no son notas oficiales.\n\nExploración, programación, aprendizaje y colaboración.\nRecursos procedurales propios y recursos existentes conservados.\n\n"
	text += "Tiempo jugado: %d minutos\nMisiones completadas: %d\nSimulaciones y desafíos: %d\n" % [int(float(c.data.stats.get("time_played",0))/60),c.data.quests.values().filter(func(q): return int(q.get("state",0))==2).size(),c.data.bosses.values().filter(func(v): return v==true).size()]
	text += "Preguntas respondidas: %s · Correctas: %s · Incorrectas: %s" % [c.data.academic_progress.answered,c.data.academic_progress.correct,c.data.academic_progress.incorrect]
	c.ui.dialog("CRÉDITOS · ESTADÍSTICAS DEL JUEGO",text,["VOLVER"],[show_chapter],true)
