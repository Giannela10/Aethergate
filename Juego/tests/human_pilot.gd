extends "res://scripts/juego/player.gd"
## Isolated diagnostic actor. Never installed in Main or saved campaign data.
var source_preview: Node3D
var source_meshes: Array[Node] = []
var accepted := false
var test_state := "IDLE"
var static_mode := false
var quality := "CHARACTER_HIGH"
var preview_tick := 0.0
var normalization_scale := 0.0

func _ready() -> void:
	persist_inventory = false
	super._ready()
	name = "HumanPilot"
	remove_from_group("player")
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	collision_layer = 0; collision_mask = 0
	inventory_ui.queue_free()
	stationery_ui.queue_free()
	var asset := load("res://assets/characters/human_pilot/human_pilot.glb") as PackedScene
	# Empty maps are intentional: inspection found NO clips or bones to map.
	accepted = body.install_imported_visual(asset,{}, {})
	source_preview = asset.instantiate() as Node3D
	source_preview.name = "StaticGLBPreview"
	add_child(source_preview)
	source_meshes = source_preview.find_children("*","MeshInstance3D",true,false)
	var bounds := AABB(); var first := true
	for mesh in source_meshes:
		var box: AABB = (source_preview.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds = box if first else bounds.merge(box); first = false
	# Match the existing 2.7 m capsule; never resize the actor/building.
	normalization_scale = capsule.height/bounds.size.y
	source_preview.scale = Vector3.ONE*normalization_scale
	# Source faces +Z (verified from front/back screenshots); campus faces -Z.
	source_preview.rotation.y = PI
	source_preview.position = -(source_preview.basis*Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))
	var stick = preload("res://scripts/juego/weapon.gd").new()
	stick.kind = "palo"
	body.equip(stick); stick.pick_up()
	body.punch_landed.disconnect(_on_punch_landed) # Diagnostic poses cannot damage campaign actors.
	set_mode(false)
	if get_parent() == get_tree().root: _build_preview_controls()

func _build_preview_controls() -> void:
	var layer := CanvasLayer.new(); layer.name = "PilotPreviewControls"; add_child(layer)
	var rows := VBoxContainer.new(); rows.position = Vector2(12,12); layer.add_child(rows)
	var note := Label.new()
	note.text = "HumanPilot · PRUEBA AISLADA\nGLB: estático, sin huesos ni clips.\nMovimiento/arma/mochila: fallback procedural."
	rows.add_child(note)
	var source_button := Button.new(); source_button.text = "Ver GLB estático (sin animación)"
	source_button.pressed.connect(func(): set_mode(true)); rows.add_child(source_button)
	for state in ["IDLE","WALK","RUN","ATTACK_LIGHT","DEATH","SIT"]:
		var button := Button.new(); button.text = "Fallback · "+state
		button.pressed.connect(func(): set_mode(false); set_test_state(state))
		rows.add_child(button)

func set_mode(show_source: bool) -> void:
	static_mode = show_source
	source_preview.visible = show_source
	body.visible = not show_source

func set_test_state(state: String) -> void:
	test_state = state
	body.dead = false; body.death_t = 0; body.hurt_t = 0
	body.punch_p[0] = -1; body.punch_p[1] = -1
	body.fall_pivot.rotation = Vector3.ZERO; body.fall_pivot.position = Vector3.ZERO
	body.contextual_pose.seated = state == "SIT"
	if state == "ATTACK_LIGHT": body.start_punch()
	if state == "DEATH": body.die()

func set_character_quality(value: String) -> void:
	quality = value
	body.cast_near_shadows = value != "CHARACTER_LOW"

func _process(delta: float) -> void:
	if not is_instance_valid(source_preview): return
	if static_mode:
		preview_tick -= delta
		if preview_tick > 0: return
		preview_tick = 0.35
		body.update_visual_lod(0.35)
		source_preview.visible = body.activity_level != 3
		for mesh in source_meshes:
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if body.lod_level == 0 and body.cast_near_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return
	var speed := 5.5 if test_state == "RUN" else (2.5 if test_state == "WALK" else 0.0)
	body.animate(delta,Vector3(0,0,-speed),true,false)
