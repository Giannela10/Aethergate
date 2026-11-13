extends SceneTree
var checks=[]
func _initialize() -> void: run.call_deferred()
func check(id: String, ok: bool, detail: Variant=null) -> void:
	checks.append({"test":id,"status":"PASS" if ok else "FAIL","detail":detail})
func run() -> void:
	var bank=JSON.parse_string(FileAccess.get_file_as_string("res://resources/education/capstone_practice_bank.json"))
	var ids={};var prompts={};var valid=true
	for q in bank.questions:
		valid=valid and not ids.has(q.id) and preload("res://scripts/education/local_practice_service.gd")._valid(q)
		ids[q.id]=q
		var key=q.prompt.strip_edges().to_lower()
		if prompts.has(key): valid=false
		prompts[key]=true
	check("bank_150_unique_valid",valid and ids.size()==150,{"questions":ids.size(),"unique_prompts":prompts.size()})
	for mentor in bank.mentors:
		var profile=bank.mentors[mentor]
		var service=preload("res://scripts/education/local_practice_service.gd").new()
		var seen={};var passed=true;var subjects={}
		for i in profile.question_ids.size():
			var q=service.fetch(int(profile.floor),"teacher_challenge",mentor)
			if q.has("error") or seen.has(q.get("id","")): passed=false;break
			seen[q.id]=true;subjects[q.subject_id]=true
			var result=service.submit(q.id,ids[q.id].answer,"teacher_challenge")
			passed=passed and result.get("correct",false) and not result.get("verified",true) and not result.get("explanation","").is_empty() and service.submit(q.id,0,"teacher_challenge").has("error")
		check("deck_"+mentor,passed and seen.size()==profile.question_ids.size(),{"floor":profile.floor,"questions":seen.size(),"subjects":subjects.keys(),"mode":"Local service full cycle; no official grade or remote write"})
	var world=Node3D.new();root.add_child(world)
	var lab=load("res://scenes/education/TeachingLab.tscn").instantiate();world.add_child(lab)
	var bases=0;var stems=0;var screens=0
	for node in lab.get_children():
		if not node is MeshInstance3D or not node.mesh is BoxMesh: continue
		if node.mesh.size.is_equal_approx(Vector3(0.36,0.03,0.24)): bases+=1
		if node.mesh.size.is_equal_approx(Vector3(0.055,0.21,0.055)): stems+=1
		if node.mesh.size.is_equal_approx(Vector3(0.7,0.45,0.07)): screens+=1
	check("fresh_lab_stands",bases==4 and stems==4 and screens==4,{"bases":bases,"stems":stems,"screens":screens})
	var guard=load("res://scripts/pisos/piso_5/terrace_guard_collision_7_1.gd").new()
	var panel=CSGBox3D.new();panel.name="Panel01";panel.size=Vector3(3,1.7,0.06);panel.position=Vector3(20,0.85,0)
	guard.add_child(panel);world.add_child(guard)
	await physics_frame;await physics_frame
	var ray=PhysicsRayQueryParameters3D.create(Vector3(20,0.85,2),Vector3(20,0.85,-2))
	var hit=world.get_world_3d().direct_space_state.intersect_ray(ray)
	check("fresh_guard_collision",not hit.is_empty() and panel.is_ancestor_of(hit.collider))
	guard._ready();check("guard_install_idempotent",panel.find_children("GuardCollision71","StaticBody3D",true,false).size()==1)
	var packed=ResourceLoader.load("res://Main.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var persisted=false
	if packed!=null:
		var state=packed.get_state()
		for i in state.get_node_count():
			if str(state.get_node_path(i)).trim_prefix("./")!="Piso5/TerrazaPicnic/CercaVidrio/Frente": continue
			for p in state.get_node_property_count(i):
				if state.get_node_property_name(i,p)=="script": persisted=state.get_node_property_value(i,p).resource_path=="res://scripts/pisos/piso_5/terrace_guard_collision_7_1.gd"
	check("Main_guard_script_persisted",persisted)
	var out="res://"+FileAccess.get_file_as_string("res://reports/final_7_1/active_run.txt").strip_edges().trim_prefix("Juego/")+"/"
	var file=FileAccess.open(out+"education_regression.json",FileAccess.WRITE);file.store_string(JSON.stringify(checks,"\t"))
	var failed=checks.filter(func(r): return r.status=="FAIL")
	print("EDUCATION71_RESULT ",JSON.stringify({"checks":checks.size(),"failures":failed}))
	world.queue_free();await process_frame
	quit(0 if failed.is_empty() else 1)
