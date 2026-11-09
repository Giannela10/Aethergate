extends RefCounted
## Two generation journal. Only campaign data; never credentials or session tokens.
var directory := "user://pending_campaign_v4"

func _path(project: String, account: String) -> String:
	return directory.path_join((project + "\n" + account).sha256_text() + ".json")

func _read(path: String, project: String, account: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length()>6500000: return {}
	var text := file.get_as_text(); file.close()
	var parser := JSON.new()
	if parser.parse(text) != OK: return {}
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("body") is String: return {}
	if str(envelope.get("sha256", "")) != str(envelope.body).sha256_text(): return {}
	if parser.parse(envelope.body) != OK: return {}
	var body = parser.data
	if not body is Dictionary or body.get("project") != project or body.get("account") != account: return {}
	if not body.get("pending") is Dictionary or not body.get("operation") is Dictionary: return {}
	if not body.get("payload") is Dictionary or not _valid_revision(body.get("revision")): return {}
	for snapshot in [body.pending,body.payload]:
		if not snapshot.is_empty() and not preload("res://scripts/live/save_migration.gd").supported(snapshot): return {}
	if not body.operation.is_empty():
		var op: Dictionary = body.operation
		if not op.get("p_payload") is Dictionary or not _valid_revision(op.get("p_revision")) or not op.get("p_backup") is bool: return {}
		if not preload("res://scripts/live/save_migration.gd").supported(op.p_payload): return {}
		var pattern := RegEx.new(); pattern.compile("^[a-f0-9]{32}$")
		if not op.get("p_request_id") is String or pattern.search(op.p_request_id)==null: return {}
	return body

func _valid_revision(value: Variant) -> bool:
	return (value is int or value is float) and float(value)>=0 and float(value)==floorf(float(value))

func recover(project: String, account: String) -> Dictionary:
	var path := _path(project, account)
	var current := _read(path, project, account)
	return current if not current.is_empty() else _read(path + ".bak", project, account)

func write(project: String, account: String, state: Dictionary) -> bool:
	if project.is_empty() or account.is_empty(): return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return false
	var body := state.duplicate(true)
	body["project"] = project
	body["account"] = account
	var encoded := JSON.stringify(body)
	var path := _path(project, account)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"body":encoded,"sha256":encoded.sha256_text()}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or _read(temp, project, account).is_empty(): return false
	# Keep the previous valid generation while atomically promoting the new file.
	if not _read(path, project, account).is_empty():
		if FileAccess.file_exists(path + ".bak") and DirAccess.remove_absolute(path + ".bak") != OK: return false
		if DirAccess.rename_absolute(path, path + ".bak") != OK: return false
	elif FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
		return false
	return DirAccess.rename_absolute(temp, path) == OK
