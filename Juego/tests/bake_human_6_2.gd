extends Node
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/characters/main_6_2/native"))
	for file in ["base_body_anim","clothing_hoodie","clothing_tshirt","clothing_jeans","clothing_shoes","hair_short02","hair_short04","hair_long01"]:
		var doc=GLTFDocument.new()
		var state=GLTFState.new()
		var err=doc.append_from_file("res://assets/characters/main_6_2/source/"+file+".glb",state)
		assert(err==OK,"GLTF parse "+file)
		var model=doc.generate_scene(state)
		var scene=PackedScene.new()
		assert(scene.pack(model)==OK,"Pack "+file)
		assert(ResourceSaver.save(scene,"res://assets/characters/main_6_2/native/"+file+".scn",ResourceSaver.FLAG_COMPRESS)==OK,"Save "+file)
		model.free()
		print("BAKED62 ",file)
	print("BAKED62_DONE")
