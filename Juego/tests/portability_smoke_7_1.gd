extends SceneTree
## Run in an isolated checkout after importing with Godot 4.7.2.
## Never uses personal saves or creates remote results.
var checks=[]
func _initialize() -> void: run.call_deferred()
func check(id: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"test":id,"status":"PASS" if ok else "FAIL","detail":detail})
func run() -> void:
	var material=load("res://materials/entrance/MAT_Piedra_Posterior.tres")
	check("entrance_material_loads",material is ShaderMaterial and material.shader!=null)
	check("entrance_shader_loads",load("res://materials/entrance/piedra_estacionamiento.gdshader") is Shader)
	check("Login_scene_loads",load("res://scenes/education/Login.tscn") is PackedScene)
	var bank=JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/capstone_practice_bank.json"))
	check("local_bank_150",bank is Dictionary and bank.questions.size()==150)
	var main=load("res://Main.tscn").instantiate()
	var c=main.get_node("CampusCampaign");c.persist=false;c.set_meta("test_mode",true)
	main.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	root.add_child(main)
	var began=Time.get_ticks_msec()
	while not c.ready_for_play and Time.get_ticks_msec()-began<180000: await process_frame
	check("Main_ready",c.ready_for_play)
	if c.ready_for_play:
		check("saves_isolated",not c.persist and not c.cloud_mode and not c.player.inventory.persist)
		var bases=0
		for room in c.get_node("DuocGames4").laboratories.values():
			for mesh in room.get_children():
				if mesh is MeshInstance3D and mesh.mesh is BoxMesh and mesh.mesh.size.is_equal_approx(Vector3(0.36,0.03,0.24)): bases+=1
		check("monitor_bases_24",bases==24,bases)
		var guards=main.get_node("Piso5/TerrazaPicnic/CercaVidrio/Frente").find_children("GuardCollision71","StaticBody3D",true,false)
		check("terrace_guards_22",guards.size()==22,guards.size())
		var valid=true;var count=0
		for row in [["academico5","pc5",6],["seguridad6","pc6",7],["acceso7","pc7",6]]:
			for requirement in c.quests.definitions[row[0]].requirements:
				if requirement.kind=="computer" and requirement.id==row[1]:
					valid=valid and requirement.get("optional",false) and requirement.text.ends_with("piso "+str(row[2]));count+=1
		check("optional_computer_captions",valid and count==3)
	var auth=root.get_node_or_null("AuthManager")
	checks.append({"test":"remote_login","status":"BLOCKED","detail":"Private configuration and authorized session required on the destination PC; no network write tested"})
	check("AuthManager_autoload_resolved",auth!=null)
	var output=OS.get_environment("DUOC_PORTABILITY_REPORT")
	if not output.is_empty():
		var file=FileAccess.open(output,FileAccess.WRITE)
		if file: file.store_string(JSON.stringify(checks,"\t"))
	var failed=checks.filter(func(row): return row.status=="FAIL")
	print("PORTABILITY71_RESULT ",JSON.stringify({"checks":checks,"failures":failed.size()}))
	main.queue_free();await process_frame
	quit(0 if failed.is_empty() else 1)
