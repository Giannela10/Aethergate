extends Node3D
## The legacy actor is the simulation hitbox, never the mentor's hitbox.
var duel: Node
var original_visual: Node3D
var mentor: Node3D
var hologram: Node3D
var caption: Label3D
var active := false
var mentor_visual: Node3D
var idle_tick := 0.0

static func digital_model() -> Node3D:
	var model := Node3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("164d68")
	material.emission_enabled = true
	material.emission = Color("16bddc")
	material.emission_energy_multiplier = 0.5
	for row in [[Vector3(0,1.1,0),Vector3(0.65,0.75,0.45)],[Vector3(0,1.8,0),Vector3(0.45,0.35,0.4)],[Vector3(-0.46,1.1,0),Vector3(0.18,0.65,0.22)],[Vector3(0.46,1.1,0),Vector3(0.18,0.65,0.22)],[Vector3(-0.2,0.4,0),Vector3(0.2,0.65,0.25)],[Vector3(0.2,0.4,0),Vector3(0.2,0.65,0.25)]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new(); box.size = row[1]
		mesh.mesh = box; mesh.material_override = material; mesh.position = row[0]
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		model.add_child(mesh)
	var visor := Label3D.new()
	visor.text = "[ SIM ]"
	visor.position = Vector3(0,2.2,0)
	visor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	visor.font_size = 35
	model.add_child(visor)
	return model

func setup(controller: Node) -> void:
	duel = controller
	for key in ["body","_visual","visual"]:
		var candidate = duel.actor.get(key)
		if candidate is Node3D: original_visual = candidate; break
	hologram = digital_model()
	duel.actor.add_child(hologram)
	hologram.hide()
	mentor = Node3D.new()
	mentor.name = "Mentor_"+duel.boss_id
	mentor.add_to_group("educational_mentor")
	duel.campaign.add_child(mentor)
	mentor.global_position = duel.spawn_position
	var visual := preload("res://scripts/juego/student_visual.gd").new()
	mentor_visual=visual
	mentor.add_child(visual)
	var presets = preload("res://scripts/juego/character_visual_presets.gd")
	var role: String={"docente_enfermeria":"ENFERMERIA","docente_odontologia":"ODONTOLOGIA","director":"DIRECTOR","punto":"FUNCIONARIO","chef":"VENDEDOR"}.get(duel.boss_id,presets.role_for(duel.boss_id))
	presets.apply(visual,presets.create(duel.boss_id,role))
	caption = Label3D.new()
	caption.text = duel.boss_name+"\nMENTOR · SIMULACIÓN EDUCATIVA"
	caption.position.y = 2.8
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mentor.add_child(caption)
	mentor.show()
	if original_visual: original_visual.hide()
	duel.actor.set_meta("simulation_enemy",true)

func begin() -> void:
	active = true
	mentor.show()
	if original_visual: original_visual.hide()
	hologram.show()
	# Put the stationary mentor outside the arena center using the existing safety probe.
	var seats: Node = duel.campaign.player.get_node_or_null("SeatController")
	if seats:
		for offset in [Vector3(5,0,0),Vector3(-5,0,0),Vector3(0,0,3)]:
			var point = seats.safe_position(duel.spawn_position+offset)
			if point != null and absf(point.y-duel.spawn_position.y)<0.5:
				mentor.global_position = point
				break

func finish() -> void:
	active = false
	hologram.hide()
	mentor.show()
	caption.text = duel.boss_name+"\nSIMULACIÓN COMPLETADA"
	if original_visual: original_visual.hide()

func reset() -> void:
	active = false
	mentor.global_position=duel.spawn_position
	mentor.show()
	hologram.hide()
	if original_visual: original_visual.hide()

func _process(delta: float) -> void:
	if mentor_visual==null or not mentor.visible: return
	idle_tick-=delta
	if idle_tick>0: return
	idle_tick=0.15
	mentor_visual.animate(0.15,Vector3.ZERO,true,false)
