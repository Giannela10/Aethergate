extends "res://scripts/juego/implemento_deportivo.gd"
const Catalog = preload("res://scripts/inventory/item_catalog.gd")
var item_id := "Escoba"
var max_durability := 1
var tech_bonus := 1.0

func _ready() -> void:
	var item = Catalog.get_item(item_id)
	var stats: Dictionary = item.weapon_data
	sport = item_id
	kind = "campus:"+item_id
	set_meta("catalog_item_id",item_id)
	set_meta("rarity",item.rarity)
	set_meta("rarity_name",["COMÚN","POCO COMÚN","RARA","ESPECIAL"][item.rarity])
	weapon_name = item.display_name
	var factor: float = [1.0,1.1,1.25,1.4][item.rarity]
	damage = float(stats.get("damage",24))*factor
	reach = float(stats.get("reach",1.9))
	max_durability = ceili(float(stats.get("durability",20))*factor)
	durability = max_durability
	set_meta("max_durability",max_durability)
	swing_time = float(stats.get("swing",0.65))
	tech_bonus = float(stats.get("tech_bonus",1))
	model = Node3D.new()
	add_child(model)
	if item_id.contains("Bandeja"):
		_box(model,Vector3(0.48,0.035,0.32),Vector3(0,-0.18,0),Color("aab9c0"))
	elif item_id.contains("Paleta"):
		_build_racket()
	elif item_id in ["Escoba","Cable","Herramienta","LlaveInglesa"]:
		_build_bat()
	elif item_id.contains("Extintor"):
		_cyl(model,0.10,0.10,0.5,Vector3(0,-0.25,0),Color("d8ac32") if item_id.contains("Dorado") else Color("ba263d"))
	else:
		_box(model,Vector3(0.42,0.08,0.26),Vector3(0,-0.18,0),Color("273d50"))
	_build_marker()
	put_down()

func can_throw() -> bool:
	return bool(Catalog.get_item(item_id).weapon_data.get("throwable",false))

func bonus_against(target: Node) -> float:
	return tech_bonus if target.is_in_group("technological") or target.name == "DirectorInformaticaBoss" or target.get_script() == load("res://scripts/pisos/piso_8/virus_director.gd") else 1.0
