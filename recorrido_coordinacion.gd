extends Node3D

# Recorrido independiente: no modifica la cámara ni la partida de Main.
var stops: Array = [
	["Entrada frente a la escalera", Vector3(71, 2.1, -126), Vector3(71, 1.6, -118), 7.0],
	["Secretaría y recepción", Vector3(71, 2.1, -120), Vector3(64, 1.4, -116), 8.0],
	["Sala de espera", Vector3(57, 2.2, -116.5), Vector3(49, 1.4, -119.5), 8.0],
	["Oficinas alrededor del pasillo", Vector3(45.5, 2.2, -114), Vector3(38, 1.4, -111), 8.0],
	["Puestos de los coordinadores", Vector3(46, 2.3, -113.5), Vector3(56, 1.4, -105), 9.0],
	["Sala de reuniones", Vector3(74.5, 2.2, -106), Vector3(75, 1.3, -98.8), 8.0],
	["Auditorio: entrada 1", Vector3(72, 13.8, -118.5), Vector3(65, 13, -116), 8.0],
	["Escenario hacia la biblioteca", Vector3(66, 14.2, -104.4), Vector3(44, 10, -104.4), 10.0],
	["Auditorio: entrada 2", Vector3(72, 13.8, -90.5), Vector3(65, 13, -94), 8.0],
	["Escenario ampliado y pantalla", Vector3(50, 10.2, -104.4), Vector3(43.4, 12.4, -104.4), 8.0],
	["Piso 2: pasillo y ascensores", Vector3(12, 14.5, -138), Vector3(-24, 15, -145), 10.0],
	["Terraza del piso 5: sombrillas y carretes", Vector3(75, 50.5, -101), Vector3(32, 50, -109), 10.0],
	["Terraza: mesas de café y césped", Vector3(53, 50.2, -109), Vector3(43, 49.3, -115), 9.0],
	["Patio posterior: cancha y estacionamientos", Vector3(72, 16, -251), Vector3(-25, 5, -204), 10.0],
	["Acceso posterior: portón y caseta", Vector3(-87, 4, -251), Vector3(-70, 2, -236), 10.0],
	["Ascensor: interior inoxidable y vista al patio", Vector3(-10, 1.7, -158), Vector3(-10, 1.5, -215), 10.0],
	["Escalera central: madera clara y peldaños oscuros", Vector3(-25, 14.1, -127.8), Vector3(-4, 18, -127.8), 10.0],
	["Casino: entrada lateral", Vector3(-25, 2.3, -116.5), Vector3(-40, 2.2, -116.5), 9.0],
	["Ascensores: acabado en todos los pisos", Vector3(18, 14.4, -139), Vector3(-7, 14.1, -149.4), 10.0],
	["Biblioteca: entrada desde el pasillo", Vector3(-26, 14.4, -130), Vector3(-39, 14, -122.7), 10.0],
	["Biblioteca: seis boxes junto a la escalera", Vector3(-72, 16, -113), Vector3(-43, 14, -96), 10.0]
]
var cam: Camera3D
var caption: Label
var index := 0
var elapsed := 0.0
var paused := false
var origin: Vector3
var origin_target: Vector3
var target: Vector3

func _ready() -> void:
	var manager := get_node_or_null("Campus/GameplayManager")
	if manager:
		manager.process_mode = Node.PROCESS_MODE_DISABLED
		manager.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.08
	add_child(cam)
	cam.make_current()
	var ui := CanvasLayer.new()
	add_child(ui)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.06, 0.11, 0.9)
	panel.position = Vector2(20, 20)
	panel.size = Vector2(750, 95)
	ui.add_child(panel)
	caption = Label.new()
	caption.position = Vector2(38, 30)
	caption.add_theme_font_size_override("font_size", 22)
	ui.add_child(caption)
	cam.position = stops[0][1]
	target = stops[0][2]
	set_stop(0)

func set_stop(value: int) -> void:
	index = posmod(value, stops.size())
	elapsed = 0.0
	origin = cam.position
	origin_target = target
	caption.text = "%d / %d — %s\nEspacio: pausa   →: siguiente   ←: anterior   R: repetir" % [index + 1, stops.size(), stops[index][0]]

func _process(delta: float) -> void:
	if paused:
		return
	elapsed += delta
	var duration: float = stops[index][3]
	var t := smoothstep(0.0, 1.0, minf(elapsed / 3.5, 1.0))
	cam.position = origin.lerp(stops[index][1], t)
	target = origin_target.lerp(stops[index][2], t)
	cam.look_at(target)
	if elapsed >= duration:
		if index == stops.size() - 1:
			paused = true
			caption.text += "\nRecorrido terminado. Presiona R para volver a verlo."
		else:
			set_stop(index + 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_SPACE:
		paused = not paused
	elif event.keycode == KEY_RIGHT:
		paused = false
		set_stop(index + 1)
	elif event.keycode == KEY_LEFT:
		paused = false
		set_stop(index - 1)
	elif event.keycode == KEY_R:
		paused = false
		cam.position = stops[0][1]
		target = stops[0][2]
		set_stop(0)
