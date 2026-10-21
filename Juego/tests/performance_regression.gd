extends SceneTree
## Compare captured rendered windows, never headless FPS against rendered FPS.
func _initialize() -> void:
	var failures: Array = []
	var before = JSON.parse_string(FileAccess.get_file_as_string("res://reports/performance_before.json"))
	var after = JSON.parse_string(FileAccess.get_file_as_string("res://reports/performance_after.json"))
	if not before is Dictionary or not after is Dictionary:
		print("PERFORMANCE_REGRESSION_RESULT ",JSON.stringify({"failures":["Missing rendered captures"]})); quit(1); return
	if before.fixture != after.fixture: failures.append("Different fixture")
	var before_draws := 0.0; var after_draws := 0.0
	var before_fps := 0.0; var after_fps := 0.0
	for row in before.baseline.samples:
		before_draws += row.draw_calls; before_fps += row.fps
	for row in after.baseline.samples:
		after_draws += row.draw_calls; after_fps += row.fps
	before_draws /= before.baseline.samples.size(); before_fps /= before.baseline.samples.size()
	after_draws /= after.baseline.samples.size(); after_fps /= after.baseline.samples.size()
	if after_draws >= before_draws: failures.append("Shadow submission did not improve in captures")
	if after_fps < before_fps: failures.append("Captured FPS regressed")
	if after.census.meshes != before.census.meshes: failures.append("Geometry count changed")
	if after.census.shadow_lights != 1: failures.append("Important shadow light removed")
	if after.census.character_activity.SLEEP <= 0: failures.append("No distant visual sleep")
	print("PERFORMANCE_REGRESSION_RESULT ",JSON.stringify({"captured_windows_only":true,"checks":6,"failures":failures,"before_fps_mean":before_fps,"after_fps_mean":after_fps,"draw_calls_before":before_draws,"draw_calls_after":after_draws}))
	quit(0 if failures.is_empty() else 1)
