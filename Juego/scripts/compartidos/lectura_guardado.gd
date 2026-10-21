extends RefCounted
## JSON.parse devuelve un estado sin emitir errores de motor por datos inválidos.
static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("No se pudo leer el guardado %s (error %d)." % [path, FileAccess.get_open_error()])
		return {}
	var content := file.get_as_text().trim_prefix("\ufeff")
	file.close()
	var parser := JSON.new()
	var error := parser.parse(content)
	if error == OK and parser.data is Dictionary:
		return parser.data
	# Conservar el original antes de que el autoguardado pueda reemplazarlo.
	var backup := path + ".invalid-" + str(Time.get_ticks_usec()) + ".bak"
	var backup_error := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup))
	var reason := "Se esperaba un objeto JSON" if error == OK else parser.get_error_message()
	if backup_error == OK:
		push_warning("Guardado inválido en %s: %s. Se conserva una copia en %s; se usarán valores iniciales para este archivo." % [path, reason, backup])
	else:
		push_warning("Guardado inválido en %s: %s. No se pudo crear el respaldo (error %d)." % [path, reason, backup_error])
	return {}
