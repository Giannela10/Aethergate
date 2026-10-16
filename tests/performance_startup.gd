extends SceneTree
## Medición de carga sin GPU. No equivale a un benchmark de FPS gráficos.
var started := Time.get_ticks_msec()
var scene: Node
var frames := 0

func _initialize() -> void:
	var packed := load("res://Main.tscn") as PackedScene
	print("PERF resource_load_ms=", Time.get_ticks_msec() - started)
	if packed == null:
		quit(1)
		return
	scene = packed.instantiate()
	# Benchmark startup without reading/writing the player's campaign or settings.
	scene.get_node("CampusCampaign").persist = false
	scene.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	print("PERF instantiate_ms=", Time.get_ticks_msec() - started)
	root.add_child.call_deferred(scene)

func _process(_delta: float) -> bool:
	frames += 1
	if frames == 120:
		print("PERF renderer=", ProjectSettings.get_setting("rendering/renderer/rendering_method"))
		print("PERF total_ms=", Time.get_ticks_msec() - started)
		print("PERF static_memory_mib=", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		print("PERF nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		print("PERF objects=", Performance.get_monitor(Performance.OBJECT_COUNT))
		print("PERF resources=", Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
		print("PERF physics_active_objects=", Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
		quit()
	return false
