class_name AppearanceMenu
extends Node
const Profile = preload("res://scripts/juego/character_appearance.gd")
const LABELS = {"skin":"Tono de piel","hair":"Cabello","hair_color":"Color de cabello","top":"Prenda superior","bottom_style":"Tipo de pantalón","shoe_style":"Tipo de calzado","backpack_color":"Color de mochila","head_accessory":"Accesorio de cabeza","clothes":"Color de ropa","pants":"Color de pantalón","shoes":"Color de calzado","backpack":"Mochila","accessory":"Accesorio","outfit":"Cosmético"}
var campaign: Node
var working := {}
var allowed := {}
var preview: Node3D
var starting := false
var selectors: Dictionary = {}

func open(new_game: bool = false) -> void:
	starting = new_game
	Profile.unlock_from_progress(campaign.data.bosses,campaign.data.cosmetics)
	allowed = {} if starting else campaign.data.cosmetics.duplicate()
	working = Profile.normalize({} if starting else campaign.data.appearance,allowed)
	campaign.ui.dialog("PERSONALIZACIÓN","Solo apariencia: no cambia estadísticas. Arrastra el control para rotar.",["Confirmar apariencia","Cancelar"],[_confirm,_cancel],true)
	var column: VBoxContainer = campaign.ui.column
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(520,210)
	container.stretch = true
	column.add_child(container)
	column.move_child(container,2)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(520,210)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	preview = preload("res://scripts/juego/student_visual.gd").new()
	viewport.add_child(preview)
	preview.rotation.y = PI
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0,1.25,3.2)
	camera.look_at(Vector3(0,0.95,0))
	camera.current = true
	camera.fov = 35
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-30,0)
	viewport.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("172938")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var rotation_slider := HSlider.new()
	rotation_slider.min_value = -180
	rotation_slider.max_value = 180
	rotation_slider.step = 1
	rotation_slider.tooltip_text = "Rotar personaje"
	rotation_slider.value_changed.connect(func(value: float): if is_instance_valid(preview): preview.rotation_degrees.y = 180+value)
	column.add_child(rotation_slider)
	column.move_child(rotation_slider,3)
	var zoom := HSlider.new()
	zoom.min_value = 2.2
	zoom.max_value = 4.8
	zoom.value = 3.2
	zoom.step = 0.05
	zoom.tooltip_text = "Zoom del personaje"
	zoom.value_changed.connect(func(value: float):
		if is_instance_valid(camera):
			camera.position.z = value
			camera.look_at(Vector3(0,0.95,0)))
	column.add_child(zoom)
	column.move_child(zoom,4)
	var remove := Button.new()
	remove.text = "Quitar accesorios, mochila y cosmético"
	remove.pressed.connect(func():
		for key in ["accessory","head_accessory","backpack","outfit"]:
			_select(0,key)
			selectors[key].select(0))
	column.add_child(remove)
	selectors.clear()
	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)
	column.move_child(grid,5)
	for key in Profile.OPTIONS:
		var label := Label.new()
		label.text = LABELS[key]
		grid.add_child(label)
		var selector := OptionButton.new()
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for index in Profile.OPTIONS[key].size():
			var lock: String = Profile.LOCKS.get(key+":"+str(index),"")
			var locked: bool = not lock.is_empty() and allowed.get(lock,false) != true
			selector.add_item(Profile.OPTIONS[key][index]+(" (bloqueado)" if locked else ""))
			selector.set_item_disabled(index,locked)
		selector.select(working[key])
		selector.item_selected.connect(_select.bind(key))
		selectors[key] = selector
		grid.add_child(selector)
	preview.apply_appearance(working)

func _select(index: int, key: String) -> void:
	working[key] = index
	working = Profile.normalize(working,allowed)
	if is_instance_valid(preview):
		preview.apply_appearance(working)

func _confirm() -> void:
	if starting:
		campaign.pending_appearance = working.duplicate()
		campaign.new_game()
	else:
		campaign.data.appearance = Profile.normalize(working,allowed)
		campaign.player.body.apply_appearance(campaign.data.appearance)
		campaign.save_game()
		campaign.ui.close_modal()
		campaign.ui.notify("Apariencia guardada")

func _cancel() -> void:
	if starting:
		campaign.show_start_menu()
	else:
		campaign.show_pause()
