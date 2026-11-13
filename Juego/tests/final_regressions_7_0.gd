extends Node
var fixture: Node
var results=[]
func install(parent: Node) -> String:
	fixture=parent;parent.add_child(self);run.call_deferred();return "FINAL70_REGRESSIONS_STARTED"
func run() -> void:
	for suite in ["inventory_regression","gameplay_regression","guardado_lectura","main_character_regression_6"]:
		var log_path=fixture.out+"regression_"+suite+".log"
		var pid=OS.create_process(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--script","res://tests/"+suite+".gd","--log-file",ProjectSettings.globalize_path(log_path)],false)
		var began=Time.get_ticks_msec()
		while pid>0 and OS.is_process_running(pid) and Time.get_ticks_msec()-began<90000:
			await get_tree().create_timer(0.3,true,false,true).timeout
		var timeout=pid>0 and OS.is_process_running(pid)
		if timeout: OS.kill(pid)
		var log=FileAccess.get_file_as_string(log_path)
		results.append({"suite":suite,"started":pid>0,"timeout":timeout,"script_errors":log.contains("SCRIPT ERROR"),"tail":log.right(3500),"note":"Fresh local tests, no remote Supabase evaluation"})
		var file=FileAccess.open(fixture.out+"regressions.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"))
		print("FINAL70_REGRESSION ",suite," timeout=",timeout)
	print("FINAL70_REGRESSIONS_DONE")
