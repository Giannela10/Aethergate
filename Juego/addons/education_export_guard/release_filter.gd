@tool
extends EditorExportPlugin
var debug_export := false

func _get_name() -> String:
	return "DuocGamesEducationExportGuard"

func _export_begin(_features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	debug_export = is_debug

func _export_file(path: String, _type: String, _features: PackedStringArray) -> void:
	if path == "res://config/auth_config.json" or path.begins_with("res://supabase/") or (not debug_export and (path == "res://resources/education/demo_questions.json" or path.begins_with("res://tests/"))):
		skip()
