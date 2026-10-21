class_name AcademicRegressionRunner
extends Node
var results: Dictionary = {}
var finished := false
@export var extras_only := false
const SUITES = ["revision_scripts","campaign_regression","inventory_regression","gameplay_regression","guardado_lectura","nueva_partida","student_phone","academic_schedule","campus_vivo","balance_regression","chef_supremo_casino","director_informatica_boss","nexo_final","organizacion_pisos","performance_startup"]
func _ready() -> void:
	if extras_only: run_extra_scenes.call_deferred()
	else: run.call_deferred()
func run_extra_scenes() -> void:
	results = JSON.parse_string(FileAccess.get_file_as_string("res://reports/academic_regressions.json"))
	var scenes := ["res://tests/ElevatorBasementCheck.tscn","res://tests/BasementAccessCheck.tscn"]
	for index in scenes.size():
		var relative := "res://tests/academic3_extra_"+str(index)+".log"
		var log_path := ProjectSettings.globalize_path(relative)
		var pid := OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),scenes[index],"--fixed-fps","60","--log-file",log_path],false)
		var started := Time.get_ticks_msec()
		while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec()-started < 180000:
			await get_tree().create_timer(0.5,true,false,true).timeout
		var timeout: bool = pid > 0 and OS.is_process_running(pid)
		if timeout: OS.kill(pid)
		var content := FileAccess.get_file_as_string(relative)
		results[scenes[index]] = {"timeout":timeout,"tail":content.right(3000),"script_errors":content.contains("SCRIPT ERROR")}
		print("ACADEMIC_EXTRA ",scenes[index]," ",JSON.stringify(results[scenes[index]]))
		var file := FileAccess.open("res://reports/academic_regressions.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(results,"\t"))
	finished = true
	print("ACADEMIC_EXTRAS_FINISHED")
func run() -> void:
	for suite in SUITES:
		var relative: String = "res://tests/academic3_"+suite+".log"
		var log_path := ProjectSettings.globalize_path(relative)
		if FileAccess.file_exists(relative): DirAccess.remove_absolute(log_path)
		var pid := OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/"+suite+".gd","--log-file",log_path],false)
		var started := Time.get_ticks_msec()
		while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec()-started < 180000:
			await get_tree().create_timer(0.5,true,false,true).timeout
		var timeout: bool = pid > 0 and OS.is_process_running(pid)
		if timeout: OS.kill(pid)
		var content := FileAccess.get_file_as_string(relative) if FileAccess.file_exists(relative) else ""
		var tail := content.right(1800)
		results[suite] = {"pid":pid,"timeout":timeout,"tail":tail,"script_errors":content.contains("SCRIPT ERROR")}
		print("ACADEMIC_REGRESSION ",suite," ",JSON.stringify(results[suite]))
		var file := FileAccess.open("res://reports/academic_regressions.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(results,"\t"))
	finished = true
	print("ACADEMIC_REGRESSIONS_FINISHED")
