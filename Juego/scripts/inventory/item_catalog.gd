extends RefCounted
const Item = preload("res://scripts/inventory/inventory_item.gd")
const Weapon = preload("res://scripts/juego/weapon.gd")
const Sports = preload("res://scripts/juego/implemento_deportivo.gd")
static var definitions: Dictionary = {}

static func register_item(item: Resource) -> void:
	if definitions.is_empty():
		_build()
	if not item.id.is_empty():
		definitions[item.id] = item

static func get_item(id: String) -> Resource:
	if definitions.is_empty():
		_build()
	return definitions.get(id)

static func _add(id: String, title: String, category: int, props: Dictionary = {}) -> void:
	var item := Item.new()
	item.id = id
	item.display_name = title
	item.category = category
	for key in props:
		item.set(key,props[key])
	definitions[id] = item

static func _build() -> void:
	_add("Bebida","Bebida",0,{"heal_amount":10.0,"description":"Recupera 10 puntos de vida."})
	_add("BebidaEnergetica","Bebida energética",0,{"speed_multiplier":1.35,"duration":12.0,"description":"Velocidad +35% durante 12 s. Reutilizar renueva la duración, sin acumular potencia."})
	_add("Comida","Comida",0,{"heal_amount":30.0,"description":"Recupera 30 puntos de vida."})
	_add("ColacionEspecial","Colación especial",0,{"full_heal":true,"description":"Recupera toda la vida."})
	_add("Botiquin","Botiquín",0,{"heal_amount":50.0,"description":"Recupera 50 puntos de vida."})
	for kind in Weapon.KINDS:
		_add("Palo" if kind == "palo" else "Silla",Weapon.KINDS[kind].name,1,{"weapon_kind":kind,"stackable":false,"max_stack":1})
	var titles := {"bate":"Bate","raqueta":"Raqueta","pelota":"PelotaBasquetbol","baseball":"PelotaBeisbol","tenis":"PelotaTenis","futbol":"PelotaFutbol","rugby":"PelotaRugby","disco":"Disco"}
	for sport in Sports.SPORTS:
		_add(titles[sport],Sports.SPORTS[sport].name,1,{"weapon_sport":sport,"stackable":false,"max_stack":1})
	_add("PaletaPingPong","Paleta de ping-pong",1,{"weapon_kind":"paleta_ping_pong","rarity":1,"stackable":false,"max_stack":1})
	for id in {"Escoba":[0,24,30],"Bandeja":[1,28,25],"LibroPesado":[1,30,22],"Herramienta":[1,34,28],"Teclado":[2,32,25],"NotebookRoto":[2,40,20],"Cable":[1,24,32],"LlaveInglesa":[2,44,35],"ExtintorDorado":[3,48,45],"BandejaDelChef":[3,42,40],"PaletaProfesional":[3,28,38],"TecladoAdministrador":[3,42,40]}:
		var values: Array = {"Escoba":[0,24,30],"Bandeja":[1,28,25],"LibroPesado":[1,30,22],"Herramienta":[1,34,28],"Teclado":[2,32,25],"NotebookRoto":[2,40,20],"Cable":[1,24,32],"LlaveInglesa":[2,44,35],"ExtintorDorado":[3,48,45],"BandejaDelChef":[3,42,40],"PaletaProfesional":[3,28,38],"TecladoAdministrador":[3,42,40]}[id]
		_add(id,id,1,{"weapon_kind":"campus:"+id,"stackable":false,"max_stack":1,"rarity":values[0],"unique":id in ["BandejaDelChef","PaletaProfesional","TecladoAdministrador"],"weapon_data":{"damage":values[1],"durability":values[2],"swing":0.45 if id.contains("Paleta") else 0.7,"throwable":id.contains("Bandeja") or id.contains("Paleta"),"tech_bonus":1.35 if id == "TecladoAdministrador" else 1.0}})
	for id in ["LibroEspecial","LibroBiblioteca","Cargador","Documentos","LlavesPerdidas","CajaMantenimiento","TarjetaDuoc","USBMaestro","CredencialAntigua"]:
		_add(id,id,2,{"max_stack":20 if id == "TarjetaDuoc" else (3 if id == "LibroBiblioteca" else 1)})
	for key in ["CredencialDirector","LlaveCasino","TarjetaAcceso"]:
		_add(key,{"CredencialDirector":"Credencial del Director","LlaveCasino":"Llave del casino","TarjetaAcceso":"Tarjeta de acceso"}[key],2,{"max_stack":1})
	_add("USBInfectado","USB infectado",3,{"special_damage":40.0,"description":"Pulso digital a un enemigo compatible a 7 m, con línea de visión. Consume una unidad solo si surte efecto."})
	for reward in ["AuricularesLinguisticos","CuadernoDelEscritor","InsigniaIntegridad"]:
		_add(reward,reward,2,{"max_stack":1,"unique":true,"description":"Reconocimiento académico del duelo. Desbloquea un cosmético; no modifica estadísticas generales."})
	for definition in preload("res://scripts/campaign/academic_expansion_data.gd").REWARDS.values():
		_add(definition[0],definition[1],2,{"max_stack":1,"unique":true,"description":definition[2]})
	for key in {"lapiz":"Lápiz","hoja_impresa":"Hoja impresa","cuaderno":"Cuaderno","goma":"Goma de borrar"}:
		_add(key,{"lapiz":"Lápiz","hoja_impresa":"Hoja impresa","cuaderno":"Cuaderno","goma":"Goma de borrar"}[key],4)

static func weapon_id(node: Node) -> String:
	if node.has_meta("catalog_item_id"):
		return str(node.get_meta("catalog_item_id"))
	if node.get("sport") != null:
		for id in all_ids():
			var item = get_item(id)
			if item.weapon_sport == node.get("sport"):
				return id
	var kind: String = str(node.get("kind"))
	for id in all_ids():
		if get_item(id).weapon_kind == kind:
			return id
	return ""

static func all_ids() -> Array:
	if definitions.is_empty():
		_build()
	return definitions.keys()
