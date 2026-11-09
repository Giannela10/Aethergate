extends Node
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/characters/shared_6_3/native"))
	for file in ["base_body_anim","clothing_hoodie","clothing_tshirt","clothing_jeans","clothing_shoes","clothing_shirt","clothing_jacket","clothing_trenchcoat","hair_short02","hair_short04","hair_long01","hair_bob01","hair_bob02","hair_ponytail01","hair_braid01","hair_afro01"]:
		var doc=GLTFDocument.new()
		var state=GLTFState.new()
		var err=doc.append_from_file("res://assets/characters/shared_6_3/source/"+file+".glb",state)
		assert(err==OK,"GLTF parse "+file)
		var model=doc.generate_scene(state)
		var scene=PackedScene.new()
		assert(scene.pack(model)==OK,"Pack "+file)
		assert(ResourceSaver.save(scene,"res://assets/characters/shared_6_3/native/"+file+".scn",ResourceSaver.FLAG_COMPRESS)==OK,"Save "+file)
		model.free()
		print("BAKED62 ",file)
	print("BAKED62_DONE")

