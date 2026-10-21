extends Node
## Launch from MCP. Child tests use isolated saves and never register real users.
var finished := false
var results: Dictionary = {}
const SUITES = [
	["education_1_0","EDUCATION_1_0_RESULT"],
	["campaign_regression","CAMPAIGN_REGRESSION"],
	["inventory_regression","INVENTORY_REGRESSION_RESULT"],
	["gameplay_regression","GAMEPLAY_REGRESSION_RESULT"],
	["guardado_lectura","SAVE_READING_RESULT"],
	["nueva_partida","NEW_GAME_RESULT"],
	["student_phone","PHONE_RESULT"],
	["campus_vivo","CAMPUS_VIVO_RESULT"],
	["director_informatica_boss","DIRECTOR INFORMATICA: OK (0 fallos)"],
	["nexo_final","NEXO_FINAL_RESULT"],
	["organizacion_pisos","FLOOR_ORGANIZATION_RESULT"],
	["AcademicBossesCheck","ACADEMIC_BOSSES_RESULT"]
]

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	for suite in SUITES:
		var log_path: String = "res://tests/supabase_regression_"+suite[0]+".log"
		if FileAccess.file_exists(log_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(log_path))
		var args: PackedStringArray = ["--headless","--path",ProjectSettings.globalize_path("res://"),"--log-file",ProjectSettings.globalize_path(log_path)]
		var scene_suite: bool = suite[0] == "AcademicBossesCheck"
		if scene_suite: args.append("res://tests/AcademicBossesCheck.tscn")
		else: args.append_array(["--script","res://tests/"+suite[0]+".gd"])
		var pid := OS.create_process(OS.get_executable_path(),args,false)
		var started := Time.get_ticks_msec()
		var stopped_after_result := false
		while pid > 0 and OS.is_process_running(pid) and Time.get_ticks_msec()-started < 120000:
			await get_tree().create_timer(0.25,true,false,true).timeout
			if scene_suite and FileAccess.file_exists(log_path) and FileAccess.get_file_as_string(log_path).contains(suite[1]):
				OS.kill(pid)
				stopped_after_result = true
				break
		var timeout := pid > 0 and OS.is_process_running(pid) and not stopped_after_result
		if timeout: OS.kill(pid)
		var content := FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
		var found: bool = content.contains(suite[1])
		var failures := -1
		var count := -1
		for line in content.split("\n"):
			if not line.contains(suite[1]) or not line.contains("{"): continue
			var data = JSON.parse_string(line.substr(line.find("{")))
			if data is Dictionary:
				var failed = data.get("failures",data.get("failed",[]))
				if failed is Array: failures = failed.size()
				count = int(data.get("checks",data.get("tested",-1)))
		if suite[0] == "director_informatica_boss" and found: failures = 0
		results[suite[0]] = {"passed":found and failures == 0 and not timeout and not content.contains("SCRIPT ERROR"),"marker_found":found,"failures":failures,"checks":count,"timeout":timeout,"script_errors":content.contains("SCRIPT ERROR"),"stopped_after_result":stopped_after_result}
		var file := FileAccess.open("res://reports/supabase_regressions.json",FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(results,"\t"))
			file.close()
		print("SUPABASE_REGRESSION ",suite[0]," ",JSON.stringify(results[suite[0]]))
	finished = true
	print("SUPABASE_REGRESSIONS_FINISHED")
