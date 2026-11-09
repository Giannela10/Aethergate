extends Node3D
## Representation adapter only. Actor ownership, collision, IDs and signals stay intact.
var host: Node3D
var model: Node3D
var identity=""
var role=""
var hidden: Array[MeshInstance3D]=[]
var tick=0.0
var pose_delta=0.0
var animation_interval=1.0/30.0
func pose_interval() -> float: return animation_interval
var profile: Dictionary={}
var skin_meshes: Array[MeshInstance3D]=[]
var eyewear: Array[MeshInstance3D]=[]
var headgear: Array[MeshInstance3D]=[]
var headset63: MeshInstance3D
var eye_rest=Vector3.ZERO
static var config: Dictionary={}
static func install(visual: Node3D) -> Node3D:
	if config.is_empty(): config=JSON.parse_string(FileAccess.get_file_as_string("res://scripts/juego/characters_6_3_rollout.json"))
	if not config.get("enabled",false) or visual.get_script().resource_path.contains("main_character_visual"): return null
	var actor=visual.get_parent()
	if not visual.is_visible_in_tree() or actor.get_meta("simulation_enemy",false): return null
	var preset: Dictionary=visual.get_meta("visual_preset",{})
	var id=str(preset.get("visual_id",""))
	var kind=str(preset.get("role","ESTUDIANTE"))
	var actor_script=actor.get_script().resource_path if actor.get_script() else ""
	if actor_script.ends_with("guardia_torniquetes.gd"):
		id="guard:"+str(actor.get_path()).get_slice("/Main/",1);kind="GUARDIA"
	elif actor_script.ends_with("boss_bibliotecaria.gd"):
		id="bibliotecaria";kind="BIBLIOTECARIA"
	elif id.is_empty(): return null # unknown/special actors are deliberately excluded
	var batch=int(config.get("batch",2))
	var eligible=id in config.get("pilot_ids",[])
	if batch>=3 and (actor.is_in_group("educational_mentor") or kind in ["PROFESOR","INGLES","ETICA","LENGUAJE","DIRECTOR"]): eligible=true
	if batch>=4 and kind=="ESTUDIANTE" and not id.contains("rescued"): eligible=true
	if batch>=5 and kind in ["FUNCIONARIO","GUARDIA","VENDEDOR","TECNICO","TALLER","BIBLIOTECARIA"]: eligible=true
	if batch>=6 and id.contains("rescued"): eligible=true
	if not eligible: return null
	var adapter=load("res://scripts/juego/npc_visual_6_3.gd").new()
	adapter.name="HumanVisual63";adapter.host=visual;adapter.identity=id;adapter.role=kind
	adapter.tick=float(absi(id.hash())%1000)/30000.0
	visual.add_child(adapter)
	if not adapter.build(): adapter.queue_free();return null
	return adapter
func build() -> bool:
	var rng=RandomNumberGenerator.new();rng.seed=identity.hash()
	profile=host.get_meta("appearance_profile",{})
	if profile.is_empty():
		profile=preload("res://scripts/juego/character_visual_presets.gd").create(identity,role)
		profile.skin=preload("res://scripts/juego/character_appearance.gd").SKIN.find(host.skin_color.to_html(false))
		profile.skin=maxi(0,int(profile.skin))
	if role=="GUARDIA": profile.clothes=5;profile.pants=5;profile.backpack=0
	if role=="BIBLIOTECARIA": profile.clothes=1;profile.hair_color=5;profile.backpack=0;profile.accessory=1
	model=preload("res://scripts/juego/human_npc_6_3.gd").new()
	model.identity=identity
	var styles=["hair_short02","hair_short04","hair_bob02","hair_long01","hair_ponytail01","hair_braid01","hair_bob01","hair_afro01"]
	model.hairstyle=styles[absi((identity+"hair63").hash())%styles.size()]
	if int(profile.get("hair",0))==2: model.hairstyle=""
	var top=int(profile.get("top",0))
	model.wardrobe=["clothing_tshirt","clothing_hoodie","clothing_shirt","clothing_hoodie","clothing_jacket","clothing_tshirt","clothing_shirt"][clampi(top,0,6)]
	if role=="BIBLIOTECARIA": model.hairstyle="hair_ponytail01";model.wardrobe="clothing_shirt"
	if role=="GUARDIA": model.wardrobe="clothing_jacket"
	if role=="ODONTOLOGIA": model.wardrobe="clothing_shirt" # Trenchcoat intersects the clinical teaching pose.
	if identity=="chef": model.wardrobe="clothing_shirt"
	if role=="ESTUDIANTE": model.wardrobe=["clothing_tshirt","clothing_hoodie","clothing_shirt","clothing_jacket"][absi((identity+"wardrobe63").hash())%4]
	var traits={"gender_male":rng.randf_range(0.15,0.75),"weight_min":rng.randf_range(0,0.08),"weight_max":rng.randf_range(0,0.10),"muscle_max":rng.randf_range(0,0.08)}
	if absi((identity+"body63").hash())%3==0 or role=="BIBLIOTECARIA":
		traits.gender_male=0.0;traits.gender_female=0.45
	for feature in ["nose_width","nose_length","nose_height","jaw_width","chin","cheekbones","eye_size","eye_spacing","eye_tilt","lips","mouth_width","ear_size","forehead"]:
		traits["face_"+feature+("_incr" if rng.randf()>0.5 else "_decr")]=rng.randf_range(0.10,0.38)
	if role!="ESTUDIANTE": traits.age_old=rng.randf_range(0.04,0.18)
	model.traits=traits
	add_child(model)
	if not model.initialize(host): return false
	model.apply_profile(profile)
	skin_meshes.assign(model.human.find_children("*","MeshInstance3D",true,false))
	# Keep authored role props and sockets; hide only the replaced body/clothes/hair.
	for mesh in host.fall_pivot.find_children("*","MeshInstance3D",true,false):
		var keep=str(mesh.get_meta("visual_module","")) in ["BACKPACK","ACCESSORY","HEAD_ACCESSORY"]
		var appearance=host.get("appearance_adapter")
		if appearance!=null and mesh in appearance.extras and str(mesh.get_meta("visual_module",""))=="":
			if mesh.get_parent()==host.head_pivot and int(profile.get("accessory",0)) in [2,4]: keep=true
			if mesh.get_parent()==host.chest and int(profile.get("accessory",0)) in [5,6,8]: keep=true
		if role=="GUARDIA" and mesh.material_override is StandardMaterial3D and mesh.material_override.metallic>0.5: keep=true
		if role=="BIBLIOTECARIA" and mesh.get_parent() in [host.hand_l,host.head_pivot] and mesh.mesh is BoxMesh: keep=true
		var ancestor=mesh.get_parent()
		while ancestor!=host.fall_pivot and ancestor!=null:
			if str(ancestor.name) in ["ActivityProp","WeaponSocket","ItemSocket"]: keep=true
			ancestor=ancestor.get_parent()
		if keep and mesh.get_parent()==host.head_pivot and ((role=="BIBLIOTECARIA" and mesh.mesh is BoxMesh) or (int(profile.get("accessory",0))==1 and str(mesh.get_meta("visual_module",""))=="ACCESSORY")): eyewear.append(mesh)
		if keep and mesh.get_parent()==host.head_pivot and (str(mesh.get_meta("visual_module",""))=="HEAD_ACCESSORY" or int(profile.get("accessory",0))==4): headgear.append(mesh)
		if not keep: mesh.hide();hidden.append(mesh)
	if int(profile.get("head_accessory",0))==1:
		for part in headgear: part.hide();hidden.append(part)
		headgear.clear()
		headset63=MeshInstance3D.new();headset63.name="Headset63"
		headset63.mesh=preload("res://scripts/juego/character_headset_6_3.gd").geometry()
		headset63.material_override=preload("res://scripts/juego/character_headset_6_3.gd").finish()
		add_child(headset63);headgear.append(headset63)
	host.set_meta("remodel63",{"id":identity,"role":role,"wardrobe":model.wardrobe,"hair":model.hairstyle,"traits":traits,"rig_bones":model.rig.get_bone_count()})
	var eyes=model.human.find_children("Eyes","MeshInstance3D",true,false)
	if not eyes.is_empty(): eye_rest=model.rig.to_local(eyes[0].to_global(eyes[0].get_aabb().get_center()))
	update(0.016)
	return true
func reapply(_profile: Dictionary) -> void:
	if is_instance_valid(headset63): headset63.free();headset63=null
	if model!=null:
		model.set_active(false)
		model.free();model=null
	hidden.clear();eyewear.clear();headgear.clear()
	build()
func update(delta: float) -> void:
	if model==null: return
	for mesh in hidden:
		if is_instance_valid(mesh): mesh.hide()
	var player=get_tree().get_first_node_in_group("player")
	var distance=host.global_position.distance_to(player.global_position) if player else 0.0
	set_relevance(distance)
	if not model.visible: return
	tick+=delta;pose_delta+=delta
	var interval=1.0/30.0 if distance<4 else 1.0/15.0 if distance<10 else 0.12 if distance<28 else 0.40
	if tick+0.00001<interval: return
	model.update_pose(pose_delta);pose_delta=0
	align_eyewear()
	align_headgear()
	tick=fmod(tick,interval)
	for mesh in skin_meshes:
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if distance<16 and host.cast_near_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func set_relevance(distance: float) -> void:
	if model==null: return
	animation_interval=1.0/30.0 if distance<4 else 1.0/15.0 if distance<10 else 0.12 if distance<28 else 0.40
	host.set_meta("npc63_distant",distance>8)
	var player=get_tree().get_first_node_in_group("player")
	var same_level=player==null or absf(host.global_position.y-player.global_position.y)<5.5
	model.visible=distance<50 and same_level

func align_eyewear() -> void:
	if eyewear.is_empty(): return
	var bone=model.rig.find_bone("head")
	var target=model.rig.global_transform*(model.rig.get_bone_global_pose(bone)*model.rig.get_bone_global_rest(bone).affine_inverse()*eye_rest)
	target+=(host.global_basis*Vector3.FORWARD).normalized()*0.025
	var center=Vector3.ZERO
	var count=0
	for part in eyewear:
		if is_instance_valid(part): center+=part.to_global(part.get_aabb().get_center());count+=1
	if count==0: return
	var offset=target-center/float(count)
	for part in eyewear:
		if is_instance_valid(part): part.global_position+=offset

func align_headgear() -> void:
	if is_instance_valid(headset63): headset63.global_basis=host.head_pivot.global_basis
	if headgear.is_empty(): return
	var bone=model.rig.find_bone("head")
	var eyes=model.rig.global_transform*(model.rig.get_bone_global_pose(bone)*model.rig.get_bone_global_rest(bone).affine_inverse()*eye_rest)
	var unit=model.rig.global_basis.get_scale().y
	var center=eyes-(host.global_basis*Vector3.FORWARD).normalized()*0.065*unit
	var bounds=AABB()
	var first=true
	for part in headgear:
		if not is_instance_valid(part): continue
		var box=part.global_transform*part.get_aabb()
		bounds=box if first else bounds.merge(box);first=false
	if first: return
	var offset=center-bounds.get_center()
	offset.y=eyes.y+0.020*unit-bounds.get_center().y if int(profile.get("head_accessory",0))==1 else eyes.y+0.095*unit-bounds.position.y
	for part in headgear:
		if is_instance_valid(part): part.global_position+=offset
