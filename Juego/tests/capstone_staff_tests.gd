extends Node
var failures=[]
var checks=0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures.append(label);push_error(label)
func _ready(): run.call_deferred()
func run():
	var shell=preload("res://tests/capstone_staff_shell_fixture.gd").new();shell.name="TeacherDashboard";add_child(shell)
	await get_tree().process_frame
	var auth=shell.auth;var backend=auth.client
	check(shell.routed_to=="TeacherDashboard","Teacher login routes to panel using isolated auth fixture")
	var panel=shell.learning_panel;panel.shell=shell
	await panel.open()
	await panel.edit({})
	var form={"unit":"Prueba temporal Capstone","prompt":"Selecciona un lenguaje de consultas relacionales.","content":"SQL\nPNG\nCSS\nWAV","answer":"1","explanation":"SQL permite consultar relaciones."}
	for key in form: panel.fields[key].text=form[key]
	for child in shell.column.get_children():
		if child is CheckBox and child.text=="Publicada": child.button_pressed=true
	for button in shell.column.get_children():
		if button is Button and button.text=="GUARDAR": button.pressed.emit();break
	await get_tree().process_frame
	check(backend.activities.size()==1,"Actual teacher form creates temporary activity")
	var row: Dictionary=backend.activities.values()[0]
	check(row.created_by==backend.OTHER and row.subject_id==backend.SUBJECT,"Teacher ownership and assigned subject")
	row.prompt="Pregunta temporal editada"
	check(not (await panel.service.rpc("save_learning_activity",{"p_id":row.id,"p_data":row})).has("error"),"Teacher edits own activity")
	await panel.toggle(row)
	check(not backend.activities[row.id].active,"Teacher deactivates")
	await panel.toggle(backend.activities[row.id])
	check(backend.activities[row.id].active,"Teacher reactivates")
	await panel.preview(backend.activities[row.id])
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/capstone_capturas/06_panel_docente_fixture.png")
	auth.client.profiles[backend.TARGET].role="student";auth.sign_as(backend.TARGET)
	var service=preload("res://scripts/education/learning_activity_service.gd").new();service.auth=auth
	var q=await service.fetch(3,"teacher_challenge")
	check(q.get("id","")==row.id and not q.has("answer") and not q.has("explanation"),"Student sees published temporary edit without key")
	var result=await service.submit(q.id,0,"teacher_challenge")
	check(result.get("correct",false) and result.get("fixture_only",false),"Temporary answer evaluated by RPC model")
	check((await service.submit(q.id,0,"teacher_challenge")).has("error"),"RPC model rejects replay")
	check((await service.rpc("learning_staff_bank")).has("error"),"Student cannot read staff solutions in policy model")
	backend.fail_next=true
	check((await service.fetch(3,"teacher_challenge")).has("error"),"Temporary connection failure")
	check(not (await service.fetch(3,"teacher_challenge")).has("error"),"Recovery after temporary failure")
	auth.sign_as(backend.OTHER)
	var forbidden=row.duplicate(true);forbidden.subject_id=backend.UNASSIGNED
	check((await service.rpc("save_learning_activity",{"p_id":null,"p_data":forbidden})).has("error"),"Unassigned subject rejected by independent policy model")
	auth.sign_as(backend.ADMIN);shell._route()
	check(shell.routed_to=="AdminDashboard","Admin login routing")
	check((await shell.administration.set_teacher_subjects(backend.OTHER,[backend.SUBJECT,backend.UNASSIGNED])).get("ok",false),"Admin associates temporary teacher and subjects")
	check(not (await service.rpc("save_learning_activity",{"p_id":null,"p_data":forbidden})).has("error"),"Admin content management across subjects")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://reports/capstone_capturas/07_panel_admin_fixture.png")
	backend.activities.clear()
	check(backend.activities.is_empty(),"Only temporary in-memory records cleaned")
	var report={"checks":checks,"failures":failures,"environment":"Actual Godot panels and services against isolated in-memory auth/RPC policy model; not production or remote RLS proof","real_users_modified":0,"real_questions_deleted":0,"hard_delete_feature":"Not offered by current panel; activation/deactivation used"}
	var file=FileAccess.open("res://reports/capstone/staff_tests.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CAPSTONE_STAFF_DONE ",failures.size())
