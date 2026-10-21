extends SceneTree
## Carga todos los scripts propios y recursos de texto sin ejecutar herramientas de edición.
var failures: Array[String] = []
var checked := 0

func _initialize() -> void:
	call_deferred("run")

func scan(path: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.get_extension() in ["gd", "tres", "gdshader"]:
			var full_path := path.path_join(file)
			var resource := load(full_path)
			checked += 1
			if resource == null or (resource is GDScript and not resource.can_instantiate()):
				failures.append(full_path)
	for directory in DirAccess.get_directories_at(path):
		if directory.begins_with(".") or directory in ["addons", "tests"]:
			continue
		scan(path.path_join(directory))

func run() -> void:
	scan("res://")
	print("SCRIPT_REVIEW "+JSON.stringify({"checked":checked,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
