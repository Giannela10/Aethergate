extends Node3D
func _ready(): run.call_deferred()
func run():
	var campus=load("res://Main.tscn").instantiate()
	var campaign=campus.get_node("CampusCampaign")
	campaign.persist=false;campaign.set_meta("test_mode",true)
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist=false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	for actor in campus.find_children("*","CharacterBody3D",true,false): actor.set_physics_process(false)
	campaign.live.director.set_process(false)
	var factory=preload("res://scripts/live/ambient_presentation.gd").new(campaign.live)
	var event=preload("res://scripts/live/event_data.gd").new()
	var rows=[];var failures=[];var geometry_hashes={}
	for floor_number in [-1,1,2,3,4,5,6,7,8]:
		var root=Node3D.new();root.name="FactoryFloor"+str(floor_number);add_child(root)
		root.position.y=preload("res://scripts/campaign/campus_content.gd").HEIGHTS[8 if floor_number==-1 else floor_number-1]
		event.event_id="factory_floor_"+str(floor_number)
		var body=factory._body(root,event,"ESTUDIANTE",0)
		for frame in 5: await get_tree().process_frame
		campaign.player.global_position=body.global_position+Vector3(2,0,1)
		body.lod_tick=0;body.activity_level=0;body.update_visual_lod(1)
		for frame in 10: body.animate(0.016,Vector3(0,0,-1),true,false)
		var adapter=body.human_visual63
		if adapter==null: failures.append("Missing dynamic model floor "+str(floor_number));root.queue_free();continue
		var traits=JSON.stringify(body.get_meta("remodel63").traits)
		var skin=adapter.model.human.find_children("Body","MeshInstance3D",true,false)[0]
		var geometry_hash=hash(skin.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		geometry_hashes[geometry_hash]=true
		var saved=JSON.parse_string(JSON.stringify(adapter.profile))
		body.apply_appearance(saved)
		await get_tree().process_frame
		var stable=JSON.stringify(body.get_meta("remodel63").traits)==traits
		var row={"floor":floor_number,"factory":"ambient_presentation._body","rig":body.human_visual63.model.rig.get_bone_count(),"profile_roundtrip_stable":stable,"geometry_hash":geometry_hash,"instances":body.find_children("HumanVisual63","Node3D",true,false).size()}
		rows.append(row)
		if not stable or row.rig!=53 or row.instances!=1: failures.append(row)
		root.queue_free();await get_tree().process_frame
	if geometry_hashes.size()<3: failures.append("Insufficient geometric variety")
	var out=FileAccess.open("res://reports/characters_6_3/dynamic_factories_validation.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"rows":rows,"failures":failures,"distinct_body_geometries":geometry_hashes.size(),"note":"Production factory invoked in an isolated fixture on all nine floor heights; these are not additional campaign actors."},"\t"));out.close()
	print("DYNAMIC63_DONE ",failures.size())
