@tool
extends EditorPlugin
var guard: EditorExportPlugin

func _enter_tree() -> void:
	guard = preload("res://addons/education_export_guard/release_filter.gd").new()
	add_export_plugin(guard)

func _exit_tree() -> void:
	remove_export_plugin(guard)
