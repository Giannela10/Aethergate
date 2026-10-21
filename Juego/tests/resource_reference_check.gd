extends SceneTree
var checked := 0
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func scan(folder: String) -> void:
	for name in DirAccess.get_files_at(folder):
		if name.get_extension() != "tscn": continue
		var target := folder.path_join(name)
		checked += 1
		if load(target) == null: failures.append(target)
	for child in DirAccess.get_directories_at(folder):
		if child.begins_with(".") or child == "addons": continue
		scan(folder.path_join(child))

func run() -> void:
	scan("res://")
	var result := {"checked_scenes":checked,"failures":failures}
	var file := FileAccess.open("res://reports/scene_reference_check.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(result,"\t"))
	print("SCENE_REFERENCE_RESULT ",JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
