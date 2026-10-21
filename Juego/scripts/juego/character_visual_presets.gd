extends RefCounted
## Stable visual data, independent of quests, actor movement and inventory.
const Profile = preload("res://scripts/juego/character_appearance.gd")
const REALISTIC_PROFILES := {"student_male":"ESTUDIANTE","student_female":"ESTUDIANTE","professor":"PROFESOR","staff":"FUNCIONARIO","health":"ENFERMERIA","workshop":"TALLER","boss_english":"INGLES","boss_language":"LENGUAJE","boss_ethics":"ETICA","director":"DIRECTOR"}
const ROLES := {
	"ESTUDIANTE":{"clothes":0,"pants":5,"backpack":1,"accessory":0},
	"PROFESOR":{"clothes":6,"pants":5,"backpack":0,"accessory":1},
	"FUNCIONARIO":{"clothes":0,"pants":5,"backpack":0,"accessory":5},
	"TECNICO":{"clothes":3,"pants":5,"backpack":2,"accessory":2},
	"GUARDIA":{"clothes":5,"pants":5,"backpack":0,"accessory":5},
	"VENDEDOR":{"clothes":2,"pants":5,"backpack":0,"accessory":0},
	"ENFERMERIA":{"clothes":0,"pants":0,"backpack":0,"accessory":5},
	"ODONTOLOGIA":{"clothes":6,"pants":6,"backpack":0,"accessory":5},
	"TALLER":{"clothes":5,"pants":5,"backpack":0,"accessory":4},
	"INGLES":{"clothes":4,"pants":5,"backpack":0,"accessory":1},
	"LENGUAJE":{"clothes":3,"pants":5,"backpack":0,"accessory":1},
	"ETICA":{"clothes":5,"pants":5,"backpack":0,"accessory":0}
}
static func create(id: String, role: String = "ESTUDIANTE") -> Dictionary:
	role = REALISTIC_PROFILES.get(role,role)
	var rng := RandomNumberGenerator.new()
	rng.seed = id.hash()
	var raw := {"skin":rng.randi_range(0,5),"hair":rng.randi_range(0,5),"hair_color":rng.randi_range(0,5),"shoes":5,"top":0,"outfit":0,"bottom_style":0,"shoe_style":0,"backpack_color":rng.randi_range(0,6),"head_accessory":0}
	raw.merge(ROLES.get(role,ROLES.ESTUDIANTE),true)
	if role == "ESTUDIANTE":
		raw.clothes = rng.randi_range(0,6)
		raw.pants = [0,3,5][rng.randi_range(0,2)]
		raw.backpack = rng.randi_range(0,1)
		raw.top = rng.randi_range(0,1)
		raw.bottom_style = 1
	elif role in ["PROFESOR","INGLES","LENGUAJE","ETICA","FUNCIONARIO","DIRECTOR"]:
		raw.top = [2,3,4][rng.randi_range(0,2)]
		raw.shoe_style = 1
		raw.bottom_style = 2
		if role == "INGLES": raw.head_accessory = 1
		if role == "DIRECTOR": raw.top = 4; raw.accessory = 5; raw.clothes = 5; raw.backpack = 0
	elif role in ["ENFERMERIA","ODONTOLOGIA"]:
		raw.top = 5
		raw.shoe_style = 1
	elif role == "TALLER":
		raw.top = 6; raw.shoe_style = 2; raw.bottom_style = 3
	raw["body_variant"] = rng.randi_range(0,2)
	raw["role"] = role
	raw["wardrobe_version"] = 2
	return raw

static func upgrade(id: String, stored: Dictionary) -> Dictionary:
	var result := stored.duplicate(true)
	var role: String = str(stored.get("role",role_for(id)))
	var added := create(id,role)
	for key in ["bottom_style","shoe_style","backpack_color","head_accessory"]:
		if not result.has(key): result[key] = added[key]
	if not stored.has("wardrobe_version") and role != "ESTUDIANTE": result.top = added.top
	result.wardrobe_version = 2
	return result

static func role_for(id: String) -> String:
	var key := id.to_lower()
	if "ingles" in key: return "INGLES"
	if "lenguaje" in key: return "LENGUAJE"
	if "etica" in key: return "ETICA"
	if "director" in key: return "DIRECTOR"
	if "tecnico" in key: return "TECNICO"
	if "profesor" in key: return "PROFESOR"
	if "auxiliar" in key or "funcionario" in key: return "FUNCIONARIO"
	if "guardia" in key: return "GUARDIA"
	if "vendedor" in key or "casino" in key: return "VENDEDOR"
	return "ESTUDIANTE"

static func apply(model: Node3D, preset: Dictionary) -> void:
	var unlocks := {}
	for key in Profile.LOCKS.values():
		unlocks[key] = true
	model.apply_appearance(Profile.normalize(preset,unlocks))
	model.set_meta("visual_preset",preset.duplicate(true))
	var width: float = [0.95,1.0,1.07][clampi(int(preset.get("body_variant",1)),0,2)]
	model.chest.scale.x = width
	model.hips.scale.x = width
