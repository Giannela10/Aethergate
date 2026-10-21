extends Node3D
## Uses the existing basement slab. No walls, workshop moves or new floor geometry.
var campaign: Node
var config: Resource = preload("res://resources/live/nexo_final.tres")
var actor: CharacterBody3D
var terminals: Array[Node3D] = []
var access: Node3D
var warning: Label3D
var cyan: StandardMaterial3D
var dark: StandardMaterial3D
var green: StandardMaterial3D
var lights: Array[OmniLight3D] = []
var tick := 0.0
var finishing := false
var placement_valid := false
func material(color: Color,emission: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color; result.roughness = 0.65
	result.emission_enabled = emission; result.emission = color; result.emission_energy_multiplier = 0.7
	return result
func box(parent: Node3D,size_value: Vector3,pos: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size_value
	node.mesh = mesh; node.position = pos; node.material_override = mat; parent.add_child(node)
	return node
func label(parent: Node3D,text: String,pos: Vector3) -> Label3D:
	var node := Label3D.new(); node.text = text; node.position = pos
	node.font_size = 32; node.pixel_size = 0.005; node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.visibility_range_end = 26
	parent.add_child(node); return node
func disc(parent: Node3D,radius: float,color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := CylinderMesh.new()
	mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = 0.025; mesh.radial_segments = 48
	node.mesh = mesh; node.position.y = 0.04
	var mat := material(color); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	node.material_override = mat; node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node); return node
func _ready() -> void:
	cyan = material(Color("28cfe2"),true); green = material(Color("4ac78b"),true); dark = material(Color("223340"))
	# Validate occupied points with the existing player capsule before enabling access.
	placement_valid = true
	for offset in [Vector3.ZERO,Vector3(0,0,-8),Vector3(-6,0,-3),Vector3(6,0,-3),Vector3(0,0,7)]:
		if campaign.player.get_node("SeatController").safe_position(global_position+offset) == null: placement_valid = false
	disc(self,10.5,Color(0.08,0.65,0.8,0.08))
	warning = label(self,"",Vector3(0,4,0))
	access = preload("res://scripts/pisos/piso_menos_1/nexo_terminal.gd").new()
	access.name = "AccesoNexo"; access.area = self; access.is_access = true; access.position = Vector3(0,0,-11)
	add_child(access)
	for index in 3:
		var terminal = preload("res://scripts/pisos/piso_menos_1/nexo_terminal.gd").new()
		terminal.name = ["TerminalNexo_A","TerminalNexo_B","TerminalNexo_C"][index]
		terminal.area = self; terminal.position = [Vector3(-6,0,-3),Vector3(6,0,-3),Vector3(0,0,7)][index]
		add_child(terminal); terminals.append(terminal)
	for x in [-8,8]:
		box(self,Vector3(0.75,2.5,0.7),Vector3(x,1.25,5),dark)
		box(self,Vector3(0.65,1.6,0.04),Vector3(x,1.4,4.62),cyan)
		var light := OmniLight3D.new(); light.position = Vector3(x,2.5,3); light.omni_range = 7; light.light_energy = 0.6; light.shadow_enabled = false
		add_child(light); lights.append(light)
	actor = preload("res://scripts/pisos/piso_menos_1/nexo_boss.gd").new()
	actor.name = "NEXO"; actor.area = self; add_child(actor)
	campaign.gameplay_event.connect(on_event)
	if campaign.data.bosses.get("director",false) and campaign.quests.state("postgame") == 2 and not campaign.player.has_key_item("CredencialDirector"):
		campaign.give_reward_item("CredencialDirector",1)
	if completed(): actor.shutdown()
func completed() -> bool: return campaign.data.get("campaign_completed",false) == true or campaign.data.bosses.get("nexo",false) == true
func archive_available() -> bool:
	return campaign.quests.state("postgame") == 2 and campaign.data.bosses.get("director",false) == true
func can_access() -> bool:
	return placement_valid and archive_available() and campaign.player.has_key_item("CredencialDirector") and campaign.data.unlocks.get("nexo_archive_read",false)
func authorized() -> bool: return can_access() and campaign.data.unlocks.get("door:nexo_core",false)
func enter_core() -> void:
	if not can_access(): campaign.ui.notify("El acceso al núcleo está bloqueado."); return
	if campaign.active_duel != null: return
	if not campaign.data.unlocks.get("door:nexo_core",false):
		campaign.data.unlocks["door:nexo_core"] = true
		campaign.event("door","nexo_core")
	set_checkpoint(); campaign.save_game()
	campaign.ui.notify("Acceso autorizado · Acércate a NEXO cuando estés preparado.")
func set_checkpoint() -> void:
	var safe = campaign.player.get_node("SeatController").safe_position(global_position+Vector3(0,0,-8))
	if safe == null: return
	campaign.data.checkpoint = {"id":"NEXO · preparación","position":[safe.x,safe.y,safe.z],"health":campaign.player.health}
func start_intro_camera() -> void:
	if actor.duel.state != actor.duel.DuelState.INTRO: return
	campaign.ui.begin_character_dialogue(actor,true)
	campaign.live.reactive.discovery_sound()
func set_lighting(active: bool,critical: bool = false) -> void:
	for light in lights:
		light.light_color = Color("ff734b") if critical else (Color("47cce8") if active else Color.WHITE)
		light.light_energy = 1.2 if active else 0.6
	if is_instance_valid(actor) and is_instance_valid(actor.glow): actor.glow.light_color = Color("ff734b") if critical else Color("47cce8") if active else Color("4ac78b")
func on_event(_kind: String,_id: String,_amount: int) -> void:
	# Presentation is deferred until existing dialogue/duel locks are released.
	tick = 0
func read_archive() -> void:
	campaign.data.unlocks["nexo_archive_read"] = true
	campaign.data.notes["proyecto_nexo_final"] = "Proyecto NEXO coordina los fallos del campus desde un núcleo de control industrial en el subterráneo. La credencial del Director permite aislarlo. Desconecta sus enlaces para detener el protocolo."
	campaign.player.set_meta("important_scene",true)
	campaign.ui.dialog("PROYECTO NEXO · ARCHIVO FINAL",campaign.data.notes.proyecto_nexo_final+"\n\nNuevo objetivo: Encuentra el núcleo de NEXO.\nZona aproximada: bahía industrial del sector este del −1. Puedes prepararte antes de entrar.",["Continuar"],[campaign.ui.close_modal],true)
	campaign.save_game()
func _process(delta: float) -> void:
	tick -= delta
	if tick > 0: return
	tick = 0.5
	if campaign.player.dead or campaign.ui.modal or campaign.player.busy or campaign.active_duel != null or campaign.manager.minigame.active: return
	if archive_available() and not campaign.data.unlocks.get("nexo_archive_read",false): read_archive()
	elif completed() and not campaign.data.unlocks.get("nexo_ending_seen",false) and not finishing: finish_campaign()
func finish_campaign() -> void:
	if finishing or not completed(): return
	finishing = true
	campaign.data["campaign_completed"] = true
	campaign.live.campus_state.refresh(); campaign.live.reactive.refresh()
	campaign.save_game()
	campaign.live.director.acquire_story_lock("nexo_ending")
	campaign.player.busy = true
	await campaign.ui.show_intro("NEXO DESACTIVADO","SISTEMAS RESTAURADOS",2.5)
	campaign.player.busy = false
	campaign.data.unlocks["nexo_ending_seen"] = true
	campaign.live.director.release_story_lock("nexo_ending")
	campaign.save_game(); finishing = false
	if not campaign.data.unlocks.get("nexo_credits_seen",false):
		campaign.ui.dialog("DUOCGAMES · CAMPAÑA COMPLETADA","El campus vuelve a estar bajo control. Puedes continuar las actividades y encargos pendientes.",["Ver créditos","Saltar créditos"],[show_credits,skip_credits],true)
	else: show_results()
func skip_credits() -> void:
	campaign.data.unlocks["nexo_credits_seen"] = true; campaign.save_game(); show_results()
func show_credits() -> void:
	campaign.data.unlocks["nexo_credits_seen"] = true; campaign.save_game()
	campaign.ui.dialog("CRÉDITOS","DUOCGAMES\nProyecto de título\n\nCreación y desarrollo: equipo DuocGames\nMotor: Godot Engine\n\nGracias por jugar.",["Continuar","Saltar créditos"],[show_results,show_results],true)
func results_text() -> String:
	var main_done := 0; var side_done := 0; var main_total := 0; var side_total := 0
	for q in campaign.quests.definitions.values():
		if q.main_quest:
			main_total += 1
			if campaign.quests.state(q.quest_id) == 2: main_done += 1
		else:
			side_total += 1
			if campaign.quests.state(q.quest_id) == 2: side_done += 1
	var bosses_done := 0; var bosses_total := 0; var optional_done := 0
	for controller in get_tree().get_nodes_in_group("boss_duel"):
		bosses_total += 1
		if campaign.data.bosses.get(controller.boss_id,false):
			bosses_done += 1
			if controller.boss_id == "profesor_redes": optional_done += 1
	var weapons_found := 0
	for id in campaign.data.collected:
		if str(id).begins_with("Arma_") and campaign.data.collected[id]: weapons_found += 1
	var notes_found := 0
	for id in ["Apunte_programacion","Apunte_datos","Apunte_redes","Apunte_ia"]:
		if campaign.data.notes.has(id): notes_found += 1
	var seconds := int(campaign.data.stats.get("time_played",0))
	var weapon_total: int = preload("res://scripts/campaign/campus_content.gd").weapon_manifest.size()
	var found: int = main_done+side_done+bosses_done+mini(20,campaign.data.cards.size())+notes_found+mini(5,campaign.data.secrets.size())+weapons_found
	var total: int = main_total+side_total+bosses_total+20+4+5+weapon_total
	return "Tiempo jugado: %02d:%02d:%02d\nNivel: %d\nPrincipales: %d/%d · Secundarias: %d/%d\nBosses: %d/%d · Opcionales: %d/1\nEnemigos derrotados: %d\nSecretos: %d/5 · Tarjetas: %d/20 · Apuntes: %d/4\nArmas de escenario encontradas: %d/%d\nProgreso del registro: %.1f%%\n\nPorcentaje calculado sobre misiones, bosses, tarjetas, apuntes, secretos y armas de escenario. No cuenta sillas, eventos raros ni actividades repetibles." % [seconds/3600,(seconds/60)%60,seconds%60,1+int(campaign.data.xp/150),main_done,main_total,side_done,side_total,bosses_done,bosses_total,optional_done,int(campaign.data.stats.get("enemies",0)),campaign.data.secrets.size(),campaign.data.cards.size(),notes_found,weapons_found,weapon_total,100.0*found/maxi(1,total)]
func show_results() -> void:
	campaign.ui.dialog("DUOCGAMES\nCAMPAÑA COMPLETADA",results_text(),["Continuar explorando","Ver créditos","Menú principal"],[campaign.ui.close_modal,show_credits,campaign.show_start_menu],true)
