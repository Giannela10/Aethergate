extends RefCounted
var platform: Node
func show_progress() -> void:
	var c: Node = platform.campaign
	var progress: Dictionary = c.data.academic_progress
	var text := "Indicadores del juego; no son notas oficiales. Las prácticas locales se distinguen de los resultados validados por el servidor.\n\n"
	text += "Asignaturas visitadas: %d\nPreguntas: %d\nCorrectas: %d\nIncorrectas: %d\nXP educativo de acceso: %d\nMisiones educativas completadas: %d/6\n" % [progress.subjects.size(),progress.answered,progress.correct,progress.incorrect,int(progress.get("educational_xp",0)),c.get_node("DuocGames4").missions.CATALOG.filter(func(row): return int(c.data.quests.get(row.id,{}).get("state",0))==2).size()]
	text += "\nActividades completadas: %d\nRespuestas validadas: %d · Prácticas locales: %d · Reflexiones: %d\n" % [progress.get("completed_activities",{}).size(),int(progress.get("verified_answers",0)),int(progress.get("practice_answers",0)),int(progress.get("reflections",0))]
	text += "\nDesafíos de acceso pendientes: "
	for floor_number in [3,4,5,6,7,8,-1]:
		if not c.data.academic_floor_unlocks.get(str(floor_number),false): text += str(floor_number)+" "
	c.ui.dialog("MI PROGRESO ACADÉMICO",text,["CREDENCIALES ACADÉMICAS","VOLVER"],[show_credentials,c.phone.open],true)
	var bar := ProgressBar.new(); bar.max_value=maxi(1,int(progress.answered)); bar.value=int(progress.correct); bar.custom_minimum_size.y=28
	c.ui.column.add_child(bar)
	var label := Label.new(); label.text="%d correctas de %d respuestas" % [progress.correct,progress.answered]; c.ui.column.add_child(label)

func show_credentials() -> void:
	var c: Node = platform.campaign
	var text := "Registro de simulaciones completadas. Conserva victorias de partidas anteriores; no son títulos oficiales.\n"
	text += "\nCredencial de Coordinación: "+("OBTENIDA" if c.data.education_v4.get("credentials",{}).get("coordinacion",false) else "Completa Ubicar profesores")+"\n"
	for duel in c.get_tree().get_nodes_in_group("boss_duel"):
		text += "\n%s · %s" % ["✓ COMPLETADA" if c.data.bosses.get(duel.boss_id,false) else "○ PENDIENTE",duel.boss_name]
	c.ui.dialog("CREDENCIALES ACADÉMICAS",text,["VOLVER"],[show_progress],true)
