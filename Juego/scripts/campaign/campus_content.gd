extends RefCounted
const HEIGHTS := [0.0,12.058385849,23.967668533,35.674415588,47.974849701,60.158504486,71.942184448,83.913551331,-12.058385849]
static var weapon_manifest: Array[Dictionary] = []
static func point(floor_index: int, x: float, z: float) -> Vector3:
	return Vector3(x,HEIGHTS[floor_index]+0.12,z)

static func add_item(campaign: Node3D, id: String, item: String, position_value: Vector3, weapon: bool = false) -> Node3D:
	var node = load("res://scripts/campaign/weapon_pickup.gd" if weapon else "res://scripts/campaign/world_item.gd").new()
	node.name = id
	node.world_id = id
	node.item_id = item
	campaign.add_child(node)
	node.global_position = position_value
	return node

static func weapons(campaign: Node3D) -> void:
	weapon_manifest.clear()
	var rows := [
		[0,"Palo",-27,-145],[0,"Silla",-38,-140],[0,"PaletaPingPong",-30,-140],[0,"Escoba",-37,-111],[0,"Bandeja",-38,-108],
		[1,"Silla",-45,-113],[1,"LibroPesado",-55,-109],[1,"Palo",25,-144],
		[2,"Silla",26,-144],[2,"Palo",-26,-144],
		[3,"Herramienta",28,-144],[3,"Silla",-28,-144],
		[4,"Palo",26,-144],[4,"Herramienta",-28,-144],
		[5,"Silla",40,-135],[5,"LibroPesado",-40,-135],
		[6,"Palo",44,-135],[6,"ExtintorDorado",-72,-135],
		[7,"Teclado",40,-135],[7,"NotebookRoto",46,-135],[7,"Cable",52,-135],
		[8,"LlaveInglesa",-30,-141],[8,"Herramienta",30,-141],[8,"ExtintorDorado",45,-140]]
	# Añadir al final conserva los IDs y recogidas de partidas anteriores.
	rows.append_array([[0,"Palo",-3,-6],[0,"Silla",3,-7],[0,"Escoba",-7,-10]])
	for floor_index in range(1,9):
		var z := -133 if floor_index in [5,6,7] else -140
		rows.append_array([[floor_index,"Palo",30,z],[floor_index,"Silla",-30,z],[floor_index,"Bandeja" if floor_index%2 == 0 else "LibroPesado",34,z]])
	for i in rows.size():
		var row: Array = rows[i]
		var pos := point(row[0],row[2],row[3])
		add_item(campaign,"Arma_%02d" % i,row[1],pos,true)
		weapon_manifest.append({"floor":row[0]+1 if row[0]<8 else -1,"item":row[1],"position":[pos.x,pos.y,pos.z]})
static func npcs_and_computers(campaign: Node3D) -> void:
	var rows := [
		["Auxiliar","llaves",0,-29,-142,"Perdí mis llaves. Creo que quedaron en el Piso 4.",{"LlavesPerdidas":1},{}],
		["Estudiante","cargador",1,25,-142,"Olvidé mi cargador en el Piso 3. ¿Me ayudas?",{"Cargador":1},{}],
		["Profesor","documentos",2,-28,-142,"Lleva estos documentos al funcionario del Piso 5.",{},{"Documentos":1}],
		["Funcionario","documentos",4,-28,-142,"Estoy esperando los documentos del profesor.",{"Documentos":1},{}],
		["MonitorDeportes","implementos",0,-38,-134,"Perdimos un balón, una paleta y una raqueta. Devuélvelos aquí.",{"PelotaBasquetbol":1,"PaletaPingPong":1,"Raqueta":1},{}],
		["Tecnico","infectado",2,29,-142,"El computador del Piso 3 está infectado. Completa el Antivirus.",{},{}],
		["EstudiantePerdido","",0,-26,-135,"La biblioteca está en el Piso 2. Las escaleras y los ascensores conectan el campus.",{},{}],
		["AyudanteCasino","casino",0,-38,-106,"El Chef acepta desafíos, pero primero debes hablar con él.",{},{}]]
	for row in rows:
		var npc = load("res://scripts/campaign/npc.gd").new()
		npc.name = row[0]
		npc.npc_name = row[0]
		npc.quest_id = row[1]
		npc.dialogue = row[5]
		npc.requested_items = row[6]
		npc.starting_items = row[7]
		campaign.add_child(npc)
		npc.global_position = point(row[2],row[3],row[4])
	for row in [[0,"pc_intro",0,-5,-8],[2,"pc3",1,25,-143],[3,"pc4",2,25,-143],[5,"pc5",0,25,-143],[6,"pc6",2,35,-133],[5,"pc7",1,-35,-133],[7,"pc8",2,37,-133]]:
		var pc = load("res://scripts/juego/computer.gd").new()
		pc.name = row[1]
		pc.game_id = row[2]
		if row[1] in ["pc4","pc5","pc6","pc7","pc8"]:
			pc.activity_profile = row[1]
		pc.set_meta("campaign_id",row[1])
		pc.set_meta("floor",row[0]+1)
		campaign.add_child(pc)
		pc.global_position = point(row[0],row[3],row[4])
		if campaign.data.computers.get(row[1],false):
			pc.set_done()
	campaign.manager.task_count = campaign.get_tree().get_nodes_in_group("computer").size()
	campaign.manager.tasks_done = campaign.data.computers.size()
	campaign.manager._update_counters()
	var secret_pc = load("res://scripts/juego/computer.gd").new()
	secret_pc.name = "pc_secreto"
	secret_pc.game_id = 1
	secret_pc.set_meta("campaign_id","pc_secreto")
	campaign.add_child(secret_pc)
	secret_pc.global_position = point(8,-40,-141)
	if campaign.data.computers.get("pc_secreto",false):
		secret_pc.set_done()
	campaign.manager.task_count = campaign.get_tree().get_nodes_in_group("computer").size()
	campaign.manager._update_counters()
	for row in [[3,"LlavesPerdidas",-36,-143],[2,"Cargador",-34,-143],[1,"LibroBiblioteca",-46,-108],[1,"LibroBiblioteca",-52,-108],[1,"LibroBiblioteca",-58,-108],[2,"PelotaBasquetbol",28,-139],[3,"PaletaPingPong",-32,-142],[4,"Raqueta",32,-141]]:
		add_item(campaign,"Mision_%s_%s_%s" % [row[1],row[2],row[0]],row[1],point(row[0],row[2],row[3]))
static func collectibles(campaign: Node3D) -> void:
	for i in 20:
		var floor_index := mini(floori(i/2.0),8)
		var side := -1.0 if i%2 == 0 else 1.0
		var x := side*(42.0+floor_index*2)
		var z := -134.5 if floor_index >= 5 and floor_index < 8 else -142.5
		if floor_index == 0:
			x = -41 if i%2 == 0 else -40
			z = -106 if i%2 == 0 else -136
		if floor_index == 1:
			x = -42 if i%2 == 0 else -59
			z = -110
		if floor_index == 8 and i >= 18:
			z = -138.5
		var node = add_item(campaign,"Tarjeta_%02d" % (i+1),"TarjetaDuoc",point(floor_index,x,z))
		node.collectible_kind = "card"
		node.important = true
		node.pickup_message = "Tarjeta Duoc encontrada"
	for row in [["programacion",2,-38,-142,"Apunte de Programación: prueba el USB infectado contra el Director."],["datos",2,35,-142,"Apunte de Base de Datos: el funcionario del Piso 5 entrega la TarjetaAcceso."],["redes",2,-60,-134,"Apunte de Redes: la sala especial del Piso 8 requiere la credencial del Director."],["ia",2,58,-133,"Apunte de Inteligencia Artificial: sal del círculo azul antes de que termine la carga."]]:
		var node = add_item(campaign,"Apunte_"+row[0],"hoja_impresa",point(row[1],row[2],row[3]))
		node.note_text = row[4]
	for row in [["archivo_subterraneo",8,44,-143,"Archivo de mantención",""],["sala_director",7,51,-144,"Sala especial del Piso 8","especial8"],["rincon_biblioteca",1,-58,-111,"Rincón de lectura",""],["estudio6",5,-72,-134,"Rincón de estudio",""]]:
		var marker = load("res://scripts/campaign/area_marker.gd").new()
		marker.name = "Secreto_"+row[0]
		marker.marker_id = row[0]
		marker.marker_type = "secret"
		marker.area_name = row[4] if row[4] != "" else row[0]
		marker.required_door = row[5]
		campaign.add_child(marker)
		marker.global_position = point(row[1],row[2],row[3])
	for row in [["biblioteca",1,-45,-114,15.0],["casino",0,-48,-104,18.0],["punto",0,-42,-140,6.0],["auditorio",1,40,-110,12.0],["coordinacion",0,30,-143,8.0]]:
		var marker = load("res://scripts/campaign/area_marker.gd").new()
		marker.marker_id = row[0]
		marker.area_name = row[0].to_upper()
		marker.radius = row[4]
		campaign.add_child(marker)
		marker.global_position = point(row[1],row[2],row[3])
static func progression_content(campaign: Node3D) -> void:
	for floor_index in 9:
		var station = load("res://scripts/campaign/health_station.gd").new()
		station.name = "CentroVida_Piso%d" % (floor_index+1 if floor_index < 8 else -1)
		campaign.add_child(station)
		station.global_position = point(floor_index,-2 if floor_index == 0 else 24,-7 if floor_index == 0 else (-133 if floor_index in [5,6,7] else -140))
	for row in [["PuntoEstudiantil",0,-35,-141],["Casino",0,-39,-105],["Biblioteca",1,-44,-112]]:
		var station = load("res://scripts/campaign/health_station.gd").new()
		station.name = "CentroVida_"+row[0]
		campaign.add_child(station)
		station.global_position = point(row[1],row[2],row[3])
	for row in [[0,25,-142],[3,-25,-142],[7,28,-131]]:
		var vendor = load("res://scripts/campaign/campus_vendor.gd").new()
		campaign.add_child(vendor)
		vendor.global_position = point(row[0],row[1],row[2])
	var seller = load("res://scripts/campaign/campus_vendor.gd").new()
	seller.vendor_name = "Vendedor del campus"
	seller.prices = {"Botiquin":25,"Bebida":5,"Comida":10,"Palo":20,"Silla":25}
	campaign.add_child(seller)
	seller.global_position = point(0,31,-140)
	for floor_index in 9:
		var id := "Curativo_%d" % floor_index
		add_item(campaign,id,"Botiquin" if floor_index >= 5 else "Comida",point(floor_index,29 if floor_index > 1 else -35,-134 if floor_index in [5,6,7] else -143))
		var enemy = load("res://scripts/campaign/campus_enemy.gd").new()
		enemy.name = "EnemigoPiso%d" % (floor_index+1)
		enemy.floor_number = floor_index+1 if floor_index < 8 else 10
		enemy.variant = ["NORMAL","NORMAL","RAPIDO","PESADO","DISTANCIA","RAPIDO","PESADO","TECNOLOGICO","PESADO"][floor_index]
		campaign.add_child(enemy)
		enemy.global_position = point(floor_index,68 if floor_index in [5,6,7] else 36,-132 if floor_index in [5,6,7] else -143)
		enemy.home = enemy.global_position
		enemy.patrol_target = enemy.home
		enemy.died.connect(campaign.enemy_defeated)
