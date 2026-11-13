extends Node3D
var results=[]
func _ready() -> void: run.call_deferred()
func check(id: String, ok: bool, detail: Variant=null) -> void:
	results.append({"test":id,"status":"PASS" if ok else "FAIL","detail":detail})
func run() -> void:
	var main=load("res://Main.tscn").instantiate()
	var c=main.get_node("CampusCampaign");c.persist=false;c.set_meta("test_mode",true)
	main.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(main)
	while not c.ready_for_play: await get_tree().process_frame
	while get_tree().get_nodes_in_group("boss_duel").any(func(d): return not d.initialized): await get_tree().process_frame
	check("fresh_Main_ready",c.ready_for_play)
	check("personal_cloud_saves_disabled",not c.persist and not c.cloud_mode and not c.player.inventory.persist)
	var count=0
	for room in c.get_node("DuocGames4").laboratories.values():
		for mesh in room.get_children():
			if mesh is MeshInstance3D and mesh.mesh is BoxMesh and mesh.mesh.size.is_equal_approx(Vector3(0.36,0.03,0.24)): count+=1
	check("persisted_monitor_bases",count==24,{"count":count})
	var front=main.get_node("Piso5/TerrazaPicnic/CercaVidrio/Frente")
	var guards=front.find_children("GuardCollision71","StaticBody3D",true,false)
	check("persisted_guard_bodies",guards.size()==22,{"count":guards.size()})
	var captions=[];var valid=true
	for row in [["academico5","pc5","Preparación opcional de Inglés: computador del piso 6"],["seguridad6","pc6","Preparación opcional de Comunicación: computador del piso 7"],["acceso7","pc7","Preparación opcional de Ética: computador del piso 6"]]:
		for requirement in c.quests.definitions[row[0]].requirements:
			if requirement.kind=="computer" and requirement.id==row[1]:
				captions.append(requirement.duplicate(true));valid=valid and requirement.text==row[2] and requirement.get("optional",false)
	check("fresh_optional_captions_utf8",valid and captions.size()==3,captions)
	check("campaign_not_artificially_completed",not c.data.bosses.get("director",false) and not c.floor_unlocked("S"))
	await get_tree().create_timer(2.0).timeout
	var out="res://"+FileAccess.get_file_as_string("res://reports/final_7_1/active_run.txt").strip_edges().trim_prefix("Juego/")+"/"
	var file=FileAccess.open(out+"fresh_Main_checks_v2.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"\t"))
	print("FINAL71_FRESH_MAIN ",JSON.stringify(results))
