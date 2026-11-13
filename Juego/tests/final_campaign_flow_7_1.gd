extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;name="CampaignFlow71";parent.add_child(self);return "CAMPAIGN_FLOW_READY"
func npc(id: String, action: String) -> void:
	var c=f.campaign;var p=f.player;var target=c.get_node(id)
	c.ui.show();c.ui.close_modal();p.busy=false
	var scanner=p.get_node("InteractionController");var selected=false
	for offset in [Vector3(0,0,2.5),Vector3(0,0,-2.5),Vector3(2.5,0,0),Vector3(-2.5,0,0)]:
		var safe=p.get_node("SeatController").safe_position(target.global_position+offset)
		if safe==null: continue
		p.global_position=safe;await get_tree().physics_frame;scanner.scan()
		if scanner.selected==target: selected=true;break
	f.record("npc_E_"+id,"PASS" if selected else "FAIL")
	if selected: scanner.interact_selected()
	else: target.interact(p)
	var buttons=c.ui.column.find_children("*","Button",true,false)
	for button in buttons:
		if (action=="accept" and button.text.to_lower().contains("aceptar")) or (action=="deliver" and button.text.to_lower().contains("entregar")):
			button.pressed.emit();break
	f.record("npc_"+id+"_"+action,"PASS" if (c.quests.state("documentos")==1 and p.inventory.has_item("Documentos")) if action=="accept" else c.quests.state("documentos")==2 else "FAIL")
	c.ui.close_modal()
func documents_start() -> void:
	f.active_floor=3;f.phase="documents_dependency"
	await npc("Profesor","accept")
	f.write("floor_3/documents_dependency_done",{"state":f.campaign.quests.state("documentos")})
func documents_deliver() -> void:
	f.active_floor=5;f.phase="documents"
	await npc("Funcionario","deliver")
	var credits=f.campaign.data.credits;var xp=f.campaign.data.xp;var keys=f.player.inventory.count_item("TarjetaAcceso")
	await npc("Funcionario","deliver")
	f.record("documents_reward_once","PASS" if f.campaign.data.credits==credits and f.campaign.data.xp==xp and f.player.inventory.count_item("TarjetaAcceso")==keys and keys==1 else "FAIL")
	f.write("floor_5/documents_done",{"keys":keys,"state":f.campaign.quests.state("documentos")})
func terrace_checks() -> void:
	f.active_floor=5;f.phase="terrace"
	var fence=f.campus.get_node("Piso5/TerrazaPicnic/CercaVidrio")
	var rows=[]
	for shape in fence.find_children("*","CollisionShape3D",true,false):
		if shape.disabled or not shape.shape is BoxShape3D: continue
		var axis=Vector3.RIGHT if shape.shape.size.x<shape.shape.size.z else Vector3.BACK
		var normal=(shape.global_basis*axis).normalized()
		var ray=PhysicsRayQueryParameters3D.create(shape.global_position+normal*1.5,shape.global_position-normal*1.5);ray.exclude=[f.player.get_rid()]
		var hit=f.player.get_world_3d().direct_space_state.intersect_ray(ray)
		rows.append({"path":str(shape.get_path()),"hit":str(hit.collider.get_path()) if not hit.is_empty() else null,"own_barrier":not hit.is_empty() and hit.collider==shape.get_parent()})
	for panel in fence.find_children("Panel*","CSGBox3D",true,false):
		var axis=Vector3.RIGHT if panel.size.x<panel.size.z else Vector3.BACK
		var normal=(panel.global_basis*axis).normalized()
		var ray=PhysicsRayQueryParameters3D.create(panel.global_position+normal*1.5,panel.global_position-normal*1.5);ray.exclude=[f.player.get_rid()]
		var hit=f.player.get_world_3d().direct_space_state.intersect_ray(ray)
		rows.append({"path":str(panel.get_path()),"use_collision":panel.use_collision,"hit":str(hit.collider.get_path()) if not hit.is_empty() else null,"own_barrier":not hit.is_empty() and (hit.collider==panel or panel.is_ancestor_of(hit.collider))})
	f.record("terrace_fence_physics_samples","PASS" if not rows.is_empty() and rows.all(func(r): return r.own_barrier) else "FAIL",{"rows":rows,"scope":"Ray intersections at existing fence centers; not an exhaustive capsule test around all edges"})
func terrace_guard_walk() -> void:
	f.active_floor=5;f.phase="guard_after"
	var p=f.player;var c=f.campaign
	c.ui.close_modal();p.busy=false;p.dead=false;p.velocity=Vector3.ZERO
	p.global_position=Vector3(-81.39,48.1,-79);p.cam_yaw=PI
	p.set_process(true);p.set_physics_process(true);p.body.show();c.manager.cam_yaw=PI;c.manager.set_process(true);c.manager.cam.make_current()
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_forward");await get_tree().create_timer(2.5).timeout;Input.action_release("move_forward")
	var blockers=[]
	for i in p.get_slide_collision_count(): blockers.append(str(p.get_slide_collision(i).get_collider().get_path()))
	f.record("terrace_front_guard","PASS" if p.global_position.z< -76.3 and absf(p.global_position.y-47.97485)<0.3 else "FAIL",{"end":str(p.global_position),"blockers":blockers,"expected":"Remain inside fence, not reach outside target"})
	await RenderingServer.frame_post_draw;f.get_viewport().get_texture().get_image().save_png(f.out+"floor_5/guard_after_walk.png")
	p.set_process(false);p.set_physics_process(false);p.body.hide();c.manager.set_process(false);f.camera.make_current()
func director_tasks() -> void:
	f.active_floor=8;f.phase="director_tasks"
	var c=f.campaign;var expansion=c.academic_expansion
	c.ui.show();c.ui.close_modal();f.player.busy=false
	var connection=expansion.task_nodes.filter(func(p): return p.get("task_id")=="director_task_network")[0]
	f.player.global_position=connection.global_position+Vector3(0,0,1.5)
	connection.interact(f.player)
	for i in 4:
		var buttons=c.ui.column.find_children("*","Button",true,false)
		if buttons.is_empty(): break
		buttons[0].pressed.emit();await get_tree().process_frame
	f.record("director_connection_steps","PASS" if expansion.state.flags.get("director_task_network",false) else "FAIL")
	var config=expansion.task_nodes.filter(func(p): return p.get("task_id")=="director_task_config" and p.get("index")==2)[0]
	f.player.global_position=config.global_position+Vector3(0,0,1.5);config.interact(f.player)
	var buttons=c.ui.column.find_children("*","Button",true,false)
	if not buttons.is_empty(): buttons[0].pressed.emit()
	f.record("director_configuration_real_choice","PASS" if expansion.state.flags.get("director_task_config",false) else "FAIL")
	var antivirus=c.get_node("director_antivirus")
	f.player.global_position=antivirus.global_position+Vector3(0,0,1.5)
	f.player._use_computer(antivirus)
	f.record("director_antivirus_started","PASS" if c.manager.current_computer==antivirus else "FAIL")
	f.record("director_antivirus_completed","NOT RUN","Minigame was opened, no success signal or artificial win injected")
	if c.manager.minigame.has_method("close"): c.manager.minigame.close(false)
	f.record("director_prerequisites_enforced","PASS" if not expansion.boss_missing("director").is_empty() and not c.data.bosses.get("director",false) and not c.floor_unlocked("S") else "FAIL",{"completed_tasks":expansion.director_count(),"missing":expansion.boss_missing("director")})
	f.record("director_official_integrator","BLOCKED","V4 published resources return 404/PGRST205; no real student session or verified attempt available")
	f.record("nexo_access_stays_locked","PASS" if not c.final_area.can_access() and not c.final_area.archive_available() else "FAIL")
	f.write("floor_8/director_flow_done",{"tasks":expansion.director_count(),"missing":expansion.boss_missing("director")})
func computer_captions() -> void:
	f.active_floor=6;f.phase="captions_after"
	var rows=[];var valid=true
	for row in [["academico5","pc5","Preparación opcional de Inglés: computador del piso 6"],["seguridad6","pc6","Preparación opcional de Comunicación: computador del piso 7"],["acceso7","pc7","Preparación opcional de Ética: computador del piso 6"]]:
		for requirement in f.campaign.quests.definitions[row[0]].requirements:
			if requirement.kind!="computer" or requirement.id!=row[1]: continue
			var before: Dictionary=requirement.duplicate(true)
			requirement.text=row[2]
			var expected=before.duplicate(true);expected.erase("text")
			var actual: Dictionary=requirement.duplicate(true);actual.erase("text")
			valid=valid and expected==actual and requirement.get("optional",false)
			rows.append({"quest":row[0],"before":before,"after":requirement.duplicate(true),"computer_position":str(f.campaign.get_node(row[1]).global_position)})
	f.write("floor_6/computer_caption_changes",rows)
	f.record("computer_captions_only","PASS" if valid and rows.size()==3 else "FAIL",{"scope":"Display text only; IDs, optional flags, amounts and requirement kinds unchanged"})
func access7() -> void:
	f.active_floor=7;f.phase="restricted_access"
	var gate=f.campus.get_node("Piso7/PasilloReferencia/Sala805/PuertaSala/CampaignAccess")
	f.player.global_position=gate.interaction_target().global_position+Vector3(0,0,1.5)
	f.record("earned_access_card","PASS" if f.player.has_key_item("TarjetaAcceso") else "FAIL",{"source":"Real documents quest delivery in this fixture"})
	gate.interact(f.player)
	f.record("access7_card_controller","PASS" if gate.unlocked and f.campaign.data.unlocks.get("door:acceso7",false) else "FAIL",{"scope":"Real gate controller with earned key; not a full walked doorway route"})
	f.record("floor8_main_requirements_preserved","PASS" if not f.campaign.floor_unlocked("8") else "FAIL",{"state":f.campaign.quests.state("acceso7"),"scope":"Opening a door does not complete unmet main prerequisites"})
	var coordinator=f.campaign.academic_expansion.actors.coordinador_profesores.duel
	f.player.global_position=coordinator.interaction_target().global_position+Vector3(0,0,2.5)
	await get_tree().physics_frame;await get_tree().physics_frame
	var scanner=f.player.get_node("InteractionController");scanner.scan()
	f.record("coordinator_E_return","PASS" if scanner.selected==coordinator else "FAIL",{"scope":"Diagnostic relocation to coordinator; real scanner selection"})
	if scanner.selected==coordinator: scanner.interact_selected()
	else: coordinator.interact(f.player)
	f.record("locate_teachers_dependency","PASS" if f.campaign.academic_expansion.coordinator_missing().is_empty() else "FAIL",{"missing":f.campaign.academic_expansion.coordinator_missing(),"seen":f.campaign.academic_expansion.state.seen})
	coordinator.decline();f.campaign.ui.close_modal()
