extends Control

const CATALOG = preload("res://scripts/inventory/item_catalog.gd")
const AVATAR = preload("res://scripts/juego/main_character_visual_6_2.gd")
const GOLD := Color("#ffd326")
const BLUE := Color("#2799f6")
const INK := Color(0.025, 0.063, 0.125, 0.94)
const PALE := Color("#f3f8ff")
const MAP_CENTER := Vector2(72, 568)
const MAP_SCALE := 0.34

var campaign: Node
var ui: CanvasLayer
var avatar: Node3D
var portrait: SubViewport
var portrait_profile := {}
var weapon := "Puños"
var reward_title := ""
var reward_credits := 0
var reward_time := 0.0
var reward_queue: Array[Dictionary] = []
var font: Font = ThemeDB.fallback_font
var unit := 1.0
var width := 1152.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait = SubViewport.new()
	portrait.size = Vector2i(144, 144)
	portrait.own_world_3d = true
	portrait.transparent_bg = true
	add_child(portrait)
	avatar = AVATAR.new()
	portrait.add_child(avatar)
	avatar.rotation.y = PI
	var camera := Camera3D.new()
	portrait.add_child(camera)
	camera.position = Vector3(0, 1.58, 4)
	camera.look_at(Vector3(0, 1.58, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.68
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-23, -24, 0)
	portrait.add_child(light)
	campaign.player.weapon_changed.connect(func(value: String): weapon = value)
	campaign.player._emit_weapon()

func complete(title: String, credits: int) -> void:
	reward_queue.append({"title": title, "credits": credits})

func _process(delta: float) -> void:
	var inventory_ui: CanvasLayer = campaign.player.inventory_ui
	var inventory_open: bool = is_instance_valid(inventory_ui) and inventory_ui.panel.visible
	visible = campaign.ready_for_play and not ui.modal and not ui.intro.visible and not campaign.player.dead and not inventory_open
	if not visible:
		return
	reward_time = maxf(0, reward_time - delta)
	if reward_time <= 0.0 and not reward_queue.is_empty():
		var reward: Dictionary = reward_queue.pop_front()
		reward_title = reward.title
		reward_credits = reward.credits
		reward_time = 4.5
	if portrait_profile != campaign.data.appearance:
		portrait_profile = campaign.data.appearance.duplicate()
		avatar.apply_appearance(portrait_profile)
		avatar.animate(0.016, Vector3.ZERO, true, false)
		portrait.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()

func _draw() -> void:
	if portrait == null or not campaign.ready_for_play:
		return
	unit = minf(size.x / 1152.0, size.y / 648.0)
	width = size.x / unit
	var height := size.y / unit
	draw_set_transform(Vector2(0, height * unit - 648 * unit), 0, Vector2.ONE * unit)
	_minimap()
	_progress()
	_quick_slots()
	if reward_time > 0.0:
		_reward()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * unit)
	_status()
	if not ui.boss_box.visible:
		_mission()
	_context()

func _panel(rect: Rect2, edge: Color, fill: Color = INK, corner: float = 9.0) -> void:
	var a := rect.position
	var b := rect.end
	var polygon := PackedVector2Array([a + Vector2(corner, 0), Vector2(b.x-corner, a.y), Vector2(b.x, a.y+corner), b-Vector2(0,corner), b-Vector2(corner,0), Vector2(a.x+corner,b.y), Vector2(a.x,b.y-corner), a+Vector2(0,corner)])
	draw_colored_polygon(polygon, fill)
	polygon.append(polygon[0])
	draw_polyline(polygon, edge, 1.8, true)

func _text(value: String, at: Vector2, points: int, color: Color = PALE, max_width: float = -1) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, max_width, points, color)

func _center(value: String, at: Vector2, points: int, color: Color = PALE) -> void:
	_text(value, at - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, points).x * 0.5, 0), points, color)

func _status() -> void:
	_panel(Rect2(68, 16, 172, 25), BLUE)
	_panel(Rect2(69, 37, 301, 57), BLUE)
	_panel(Rect2(77, 94, 191, 26), BLUE)
	var data: Dictionary = campaign.data
	var auth := get_node_or_null("/root/AuthManager")
	var display := str(auth.get("display_name")).strip_edges() if auth != null else ""
	var student := "Nicolás" if display.is_empty() else display.get_slice(" ", 0)
	_text(student, Vector2(109, 35), 18, PALE, 77)
	_text("Nivel %d" % (1 + int(data.xp / 150)), Vector2(185, 34), 12)
	_text("♥", Vector2(108, 61), 21, Color("#ff3865"))
	_text("Vida", Vector2(134, 59), 16)
	var player: CharacterBody3D = campaign.player
	_text("%d / %d" % [ceili(player.health), ceili(player.max_health)], Vector2(287, 59), 15)
	var fraction := clampf(player.health / maxf(1.0, player.max_health), 0, 1)
	for i in 12:
		var rect := Rect2(109 + 20.0*i, 68, 18.6, 15)
		draw_rect(rect, Color("#1f4426"))
		var fill := clampf(fraction * 12.0 - i, 0, 1)
		if fill > 0:
			draw_rect(Rect2(rect.position, Vector2(rect.size.x*fill, rect.size.y)), Color("#46de2c"))
			draw_rect(Rect2(rect.position, Vector2(rect.size.x*fill, 3)), Color("#c5ff9c"))
	_text("Arma: " + weapon, Vector2(112, 112), 14, PALE, 149)
	var combat: Node = player.get_node_or_null("CombatExtensions")
	if combat != null and combat.stamina < combat.max_stamina - 0.5:
		draw_rect(Rect2(111, 121, 151, 3), INK)
		draw_rect(Rect2(111, 121, 151*combat.stamina/combat.max_stamina, 3), BLUE)
	draw_circle(Vector2(55, 58), 45, BLUE, true, -1, true)
	draw_circle(Vector2(55, 58), 42, PALE, true, -1, true)
	draw_circle(Vector2(55, 58), 39.5, Color("#142b49"), true, -1, true)
	draw_texture_rect(portrait.get_texture(), Rect2(24, 27, 62, 62), false)

func _mission() -> void:
	if campaign.quests == null:
		return
	var lines: PackedStringArray = campaign.quests.objective_text().split("\n", false, 1)
	if lines.is_empty():
		return
	var x := width - 320.0
	_panel(Rect2(x, 15, 305, 103), GOLD)
	draw_line(Vector2(x+3, 47), Vector2(x+302, 47), GOLD, 1.2, true)
	_text("◎  Misión Principal", Vector2(x+17, 39), 20, GOLD)
	_text(lines[0], Vector2(x+18, 74), 17, PALE, 269)
	if lines.size() == 2:
		var split := lines[1].rfind(" (")
		var description := lines[1].left(split) if split >= 0 else lines[1]
		_text("□  " + description, Vector2(x+17, 100), 14, PALE, 221)
		if split >= 0:
			_text(lines[1].substr(split+1), Vector2(x+250, 100), 14, GOLD, 47)

func _progress() -> void:
	var data: Dictionary = campaign.data
	_panel(Rect2(140, 557, 186, 72), BLUE)
	draw_line(Vector2(145, 593), Vector2(321, 593), Color("#5477a4"), 1.0)
	_text("◆", Vector2(158, 581), 17, GOLD)
	_text("Créditos:  %d" % data.credits, Vector2(182, 581), 17)
	_text("▰", Vector2(158, 618), 17)
	_text("Tarjetas:  %d / 20" % data.cards.size(), Vector2(182, 618), 16)

func _quick_slots() -> void:
	var inventory: Node = campaign.player.inventory
	if inventory == null:
		return
	var start := width * 0.5 - 213.0
	for i in 4:
		var x := start + 108.0*i
		var entry: Dictionary = inventory.entry_for(inventory.quick_slots[i])
		var selected: bool = not entry.is_empty() and entry.uid == inventory.equipped_uid
		var color := GOLD if selected else Color("#617ea2")
		_panel(Rect2(x, 552, 104, 83), color)
		_panel(Rect2(x+11, 547, 22, 21), BLUE, INK, 4)
		_center(str(i+1), Vector2(x+22, 563), 14)
		if entry.is_empty():
			_center("Vacío", Vector2(x+52, 605), 13, Color("#adc1db"))
			continue
		var item = CATALOG.get_item(entry.item_id)
		if item.icon != null:
			draw_texture_rect(item.icon, Rect2(x+33, 559, 38, 37), false)
		_text(item.display_name, Vector2(x+7, 610), 12, PALE, 91)
		_center("×%d" % entry.quantity, Vector2(x+52, 628), 12)

func _reward() -> void:
	var x := width * 0.5
	_panel(Rect2(x-170, 468, 340, 69), Color("#a9ef34"), Color(0.025,0.27,0.12,0.94), 14)
	_text("✓", Vector2(x-146, 511), 31, Color("#c5ff71"))
	_center("¡Misión completada!", Vector2(x+13, 489), 19)
	_center(reward_title, Vector2(x+13, 511), 14)
	if reward_credits > 0:
		_center("+ %d Créditos" % reward_credits, Vector2(x+13, 530), 15, GOLD)

func _minimap() -> void:
	var c := MAP_CENTER
	draw_circle(c, 68, Color("#122740"), true, -1, true)
	draw_circle(c, 64, Color("#8aa0b4"), true, -1, true)
	draw_circle(c, 61, Color("#39474a"), true, -1, true)
	# Esquema orientado al norte del edificio, jardines y patios del campus.
	for region in [Rect2(-48,-43,96,44), Rect2(-47,7,94,19), Rect2(-48,32,35,11), Rect2(14,32,34,11)]:
		draw_rect(Rect2(c+region.position, region.size), Color("#718079"))
	draw_rect(Rect2(c+Vector2(-43,-39),Vector2(86,35)), Color("#566773"))
	for offset in [-36, 15]:
		draw_rect(Rect2(c+Vector2(offset,8),Vector2(21,16)), Color("#4a693b"))
	draw_rect(Rect2(c+Vector2(-8,-37),Vector2(16,77)), Color("#a2aa9d"))
	var player: Vector3 = campaign.player.global_position
	var p := _map_point(player)
	if is_instance_valid(campaign.guidance) and is_instance_valid(campaign.guidance.target):
		var t := _map_point(campaign.guidance.target.global_position)
		draw_dashed_line(p, t, GOLD, 2.0, 4.0)
		draw_circle(t, 4.0, GOLD, true, -1, true)
	var heading: Vector3 = -campaign.player.body.global_basis.z
	var dir := Vector2(heading.x, heading.z).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var right := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([p+dir*9,p-dir*5+right*5,p-dir*5-right*5]), PALE)
	draw_colored_polygon(PackedVector2Array([p+dir*6,p-dir*3+right*3,p-dir*3-right*3]), BLUE)
	_center("N", c+Vector2(0,-59), 12)

func _map_point(world: Vector3) -> Vector2:
	return MAP_CENTER + (Vector2(world.x, world.z+123.0)*MAP_SCALE).limit_length(55)

func _context() -> void:
	var value: String = ui.context.text
	if value.is_empty():
		return
	var at := Vector2(width*0.5, size.y/unit-162.0)
	var interaction: Node = campaign.get_node_or_null("InteractionController")
	var camera := get_viewport().get_camera_3d()
	if interaction != null and is_instance_valid(interaction.selected) and camera != null:
		var world: Vector3 = interaction.selected.global_position + Vector3.UP * 1.8
		if not camera.is_position_behind(world):
			at = camera.unproject_position(world)/unit
	var span := minf(380, font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 22)
	at.x = clampf(at.x, 12+span/2, width-12-span/2)
	at.y = clampf(at.y, 128, size.y/unit-118)
	_panel(Rect2(at-Vector2(span/2, 18),Vector2(span,29)),BLUE)
	var start := at-Vector2(span/2-11,0)
	if value.begins_with("[E] "):
		_text("[E]", start, 15, GOLD)
		_text(value.substr(4), start+Vector2(27,0), 15, PALE, span-46)
	else:
		_text(value, start, 15, PALE, span-19)
