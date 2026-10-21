class_name AcademicScheduleRegression
extends SceneTree
var now := {"day":0,"minute":530}
var failures: Array[String] = []
var checks := 0
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok:
		failures.append(title)
		push_error(title)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://Main.tscn").instantiate()
	var campaign = scene.get_node("CampusCampaign")
	campaign.persist = false
	campaign.set_meta("test_mode",true)
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	root.add_child(scene)
	while not campaign.ready_for_play or campaign.academics.points.size() < 2:
		await process_frame
	campaign.ui.close_modal()
	var academic = campaign.academics
	var player = campaign.player
	player.set_physics_process(false)
	check(academic.clock_text() == "08:50","Horario nuevo comienza a las 08:50")
	academic.time_provider = func(): return now
	var inventory = player.inventory.snapshot_data()
	academic.update_schedule()
	check(academic.pending_course == "programming","Aviso diez minutos antes")
	academic.update_schedule()
	check(academic.state.reminders.size() == 1,"No duplicar aviso")
	check(not academic.attend("programming"),"No registrar antes de hora")
	now.minute = 540
	check(not academic.attend("programming"),"No asistir desde otro piso")
	var point: Node3D = academic.points.technology
	var seating = player.get_node("SeatController")
	for candidate_point in academic.points.values():
		var usable := false
		for offset in [Vector3(0,0,1.0),Vector3(0,0,-1.0),Vector3(1.0,0,0),Vector3(-1.0,0,0)]:
			var safe = seating.safe_position(candidate_point.global_position+offset)
			if safe != null:
				player.global_position = safe
				var interaction = player.get_node("InteractionController")
				interaction.scan()
				if interaction.selected == candidate_point:
					usable = true
					break
		check(usable,"Punto de clase seleccionable con E: "+str(candidate_point.site))
	var approach = null
	for offset in [Vector3(0,0,1.0),Vector3(0,0,-1.0),Vector3(1.0,0,0),Vector3(-1.0,0,0),Vector3.ZERO]:
		var safe = seating.safe_position(point.global_position+offset)
		if safe != null:
			player.global_position = safe
			if player._can_reach(point):
				approach = safe
				break
	print("ACADEMIC_POINT ",point.global_position," approach=",approach)
	check(approach != null,"Punto de Sala 303 accesible con suelo real")
	if approach == null:
		scene.queue_free()
		await process_frame
		quit(1)
		return
	var xp: int = campaign.data.xp
	var credits: int = campaign.data.credits
	check(academic.attend("programming"),"Registrar asistencia presencial")
	check(academic.state.attended == 1,"Contar asistida")
	check(campaign.data.xp == xp+25 and campaign.data.credits == credits+10,"Premio inicial usa sistema existente")
	check(not academic.attend("programming"),"No duplicar asistencia")
	check(academic.pending_course.is_empty(),"Asistir descarta aviso pendiente")
	campaign.ui.close_modal()
	academic.ignore("network")
	check(academic.state.records["0:network"] == "ignored","Ignorar es opcional")
	campaign.ui.close_modal()
	now.minute = 700
	academic.update_schedule()
	check(academic.state.missed == 1,"Registrar clase perdida al terminar")
	academic.update_schedule()
	check(academic.state.missed == 1,"No duplicar faltas")
	check(academic.attendance_text().contains("50%"),"Porcentaje usa clases registradas")
	now.minute = 900
	academic.update_schedule()
	check(academic.state.missed == 2,"Contar Inglés perdido")
	check(campaign.data.bosses.is_empty(),"Faltar no bloquea ni cambia bosses")
	now.day = 1
	now.minute = 540
	academic.update_schedule()
	check(academic.attend("programming"),"Nueva jornada permite asistir otra vez")
	check(academic.state.attended == 2,"Acumular asistencia entre jornadas")
	check(campaign.data.xp == xp+25 and campaign.data.credits == credits+10,"No farmear recompensa al repetir materia")
	campaign.ui.close_modal()
	campaign.phone.app("schedule")
	check(campaign.ui.page == "phone:schedule" and campaign.phone.view.root.visible,"Horario dentro del teléfono")
	campaign.phone.toggle()
	check(not paused and not player.busy,"P cierra horario y devuelve controles")
	check(player.inventory.snapshot_data() == inventory,"No modificar inventario")
	campaign.save_path = "res://tests/academic_temporary.json"
	campaign.persist = true
	campaign.save_game()
	campaign.persist = false
	var stored = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary(campaign.save_path)
	check(stored.academics.attended == 2 and stored.academics.missed == 2,"Guardar asistencia en campaña existente")
	check(stored.academics.records["1:programming"] == "attended","Guardar registro de jornada")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(campaign.save_path))
	print("ACADEMIC_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	scene.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
