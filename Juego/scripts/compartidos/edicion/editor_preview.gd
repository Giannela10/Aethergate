@tool
extends RefCounted

static func camera() -> Camera3D:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return null
	var editor := Engine.get_singleton("EditorInterface")
	var viewport: SubViewport = editor.call("get_editor_viewport_3d", 0)
	return viewport.get_camera_3d() if viewport != null else null
