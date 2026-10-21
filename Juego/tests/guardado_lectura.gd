extends SceneTree
const Reader = preload("res://scripts/compartidos/lectura_guardado.gd")
const DIRECTORY := "res://tests/guardado_lectura_temporal"
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	var path := DIRECTORY.path_join("partida.json")
	for content in ["", "{incompleto", "null", "[]", "\ufeff{\"credits\":75}", "{\"credits\":75}"]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(content)
		file.close()
		var result := Reader.read_dictionary(path)
		check(result.get("credits",0) == (75 if content.contains("credits") else 0), "Lectura: "+content)
		check(FileAccess.get_file_as_bytes(path) == content.to_utf8_buffer(), "No modifica el guardado al leer")
	var backups := 0
	for name in DirAccess.get_files_at(DIRECTORY):
		if name.ends_with(".bak"):
			backups += 1
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DIRECTORY.path_join(name)))
	check(backups == 4, "Respalda los cuatro archivos inválidos")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIRECTORY))
	print("SAVE_READING_RESULT "+JSON.stringify({"failures":failures}))
	quit(0 if failures.is_empty() else 1)
