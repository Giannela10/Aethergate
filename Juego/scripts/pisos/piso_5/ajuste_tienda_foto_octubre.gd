@tool
extends "res://scripts/exterior/arquitectura_fotos_octubre.gd"
func apply_photo() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	if shop.has_meta("reference_095543"): return {"status":"already_applied"}
	var before:Dictionary={"position":str(shop.position),"rotation":str(shop.rotation),"scale":str(shop.scale),"children":shop.get_child_count()}
	shop.rotation.y=PI*0.5
	shop.scale=Vector3(1.0,0.85,1.0)
	# Frente hacia el pasillo longitudinal. Escalera a la izquierda y pared a la derecha.
	shop.position=Vector3(-28.2,47.975,-136.6)
	var original_nodes:Array=shop.get_children()
	for n in original_nodes:
		if not n is Node3D: continue
		var title:=str(n.name)
		if title=="RevestimientoMadera" or title.begins_with("JuntaMadera"):
			n.visible=false
		if title=="MostradorFrontal" or title=="CubiertaFrontal":
			n.position.x=-0.7
			resize_box(n,Vector3(5.0 if title=="MostradorFrontal" else 5.15,n.mesh.size.y,n.mesh.size.z))
		if title=="MostradorRetorno" or title=="CubiertaRetorno":
			n.position.z=-0.75
			resize_box(n,Vector3(n.mesh.size.x,n.mesh.size.y,1.4))
		if title.begins_with("JuntaGabinete") or title.begins_with("TiradorGabinete"):
			n.position.x-=0.7
			if n.position.x>1.7: n.visible=false
		var cold:bool=title.contains("Refrigerador") or title.begins_with("RepisaFrio") or title.begins_with("Botella") or title=="LuzInteriorFrio" or title=="MarcaCachantunFoto"
		if cold:
			n.position.x+=4.7
			n.position.y*=0.80
			n.scale.y*=0.80
		if title=="CongeladorBlanco" or title=="TapaCongelador" or title=="FranjaCongelador":
			n.position.x=2.0; n.position.z+=1.35
		if title=="SenalPiso5": n.visible=false
	# Techo de vidrio con estructura metálica, abierto hacia el pasillo.
	var g:=group(shop,"Referencia095543")
	var glass:=mat(Color(0.52,0.67,0.65,0.16),0.24)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	for x in [-4.0,4.0]:
		box(g,"MarcoLateral",Vector3(x,4.95,-1.7),Vector3(0.09,0.11,5.3),black)
	for z in [-4.35,-2.6,-0.85,0.95]:
		box(g,"TravesanoCubierta",Vector3(0,4.95,z),Vector3(8.0,0.11,0.09),black)
	for x in [-2.0,0.0,2.0]:
		box(g,"PerfilLongitudinal",Vector3(x,4.95,-1.7),Vector3(0.065,0.09,5.3),black)
	box(g,"CristalCubierta",Vector3(0,4.99,-1.7),Vector3(7.9,0.018,5.2),glass)
	for x in [-3.9,3.9]:
		box(g,"PilarTrasero",Vector3(x,2.45,-4.28),Vector3(0.08,4.9,0.08),black)
	# Mampara posterior y pared de madera a la derecha de la atención.
	box(g,"VidrioPosterior",Vector3(0,2.5,-4.22),Vector3(7.9,4.9,0.035),glass)
	box(g,"FranjaEsmerilada",Vector3(0,1.15,-4.19),Vector3(7.9,1.3,0.02),mat(Color("b9c8c3")))
	for x in [-2.0,0.0,2.0]:
		box(g,"MontantePosterior",Vector3(x,2.5,-4.15),Vector3(0.06,5.0,0.06),black)
	box(g,"MaderaLateral",Vector3(4.08,2.8,-0.2),Vector3(0.045,5.6,8.0),wood)
	var sign:=group(g,"DEA_Y_Plano")
	sign.position=Vector3(4.02,2.35,2.2)
	sign.rotation.y=-PI*0.5
	box(sign,"GabineteDEA",Vector3.ZERO,Vector3(0.72,0.92,0.22),mat(Color("d3e0d6")))
	text(sign,"DEA","♥ ⚡\nDESFIBRILADOR",Vector3(0,0,0.13),32,Color("258253"),0.0042)
	box(sign,"Plano",Vector3(0,1.34,-0.03),Vector3(1.15,0.85,0.06),white)
	box(sign,"CabeceraPlano",Vector3(0,1.70,0.01),Vector3(1.15,0.14,0.02),yellow)
	text(sign,"Piso","PISO 5",Vector3(-0.28,1.70,0.03),22,Color.BLACK,0.004)
	for i in range(5):
		var line:=box(sign,"PlanoPasillo",Vector3(-0.3+i*0.14,1.33,0.015),Vector3(0.08,0.45,0.012),mat(Color("71a6ba")))
		line.rotation.z=0.45
	# Se conserva la cartelería fotográfica ya importada del mismo negocio.
	var badge:Node3D=shop.get_node_or_null("LetreroJuanValdez")
	if badge!=null: badge.position=Vector3(3.35,4.65,0.9)
	var menu:Node3D=shop.get_node_or_null("CartaFotografica")
	if menu!=null:
		menu.position=Vector3(3.96,4.05,-2.0); menu.rotation.y=-PI*0.5; menu.scale=Vector3(0.48,0.85,1.0)
	var frame:Node3D=shop.get_node_or_null("MarcoCartaIluminada")
	if frame!=null:
		frame.position=Vector3(3.98,4.05,-2.0); frame.rotation.y=-PI*0.5; frame.scale=Vector3(0.48,0.85,1.0)
	var floor_node:MeshInstance3D=shop.get_node("PisoBaldosasTienda")
	floor_node.material_override=floor_mat
	shop.set_meta("reference_095543",true)
	shop.set_meta("referencia","WhatsApp Image 2026-10-19 at 09.55.43.jpeg")
	shop.set_meta("orientacion","frente +X; pared derecha -Z; escalera lado +Z")
	var result:Dictionary={"before":before,"after_position":str(shop.position),"front":"+X","scale":str(shop.scale),"main_path_preserved":true}
	var f:=FileAccess.open("res://reports/tienda_piso5_ajuste.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	return result
func align_wall() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	if shop.has_meta("next_to_emergency"): return {"status":"emergency_location_preserved"}
	shop.position.z=-135.3
	shop.get_node("CieloHormigonNicho").visible=false
	var panel:MeshInstance3D=shop.get_node("Referencia095543/MaderaLateral")
	panel.position=Vector3(3.96,2.8,2.8)
	resize_box(panel,Vector3(0.045,5.6,16.0))
	var sign:Node3D=root.get_node("Piso5/SenaleticaEscaleraFotos")
	if not sign.has_node("CaraPasilloNegocio"):
		var rear:=group(sign,"CaraPasilloNegocio")
		rear.rotation.y=PI
		box(rear,"Amarillo",Vector3(2.8,0,0.065),Vector3(1.25,1.45,0.035),yellow)
		text(rear,"Piso","5",Vector3(2.8,0,0.095),84,Color("20262a"),0.009)
		text(rear,"Destinos","TERRAZA · CAFETERÍA\nASCENSORES  →",Vector3(-0.6,0,0.072),32,Color("252b2e"),0.005)
	return {"position":str(shop.position),"aligned_with_existing_wall":true}
func finish_equipment() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	if shop.has_meta("equipment_095543"): return {"status":"already_applied"}
	shop.get_node("Referencia095543/DEA_Y_Plano").position.x=3.72
	shop.get_node("CartaFotografica").position.x=3.80
	shop.get_node("MarcoCartaIluminada").position.x=3.87
	var prefixes:Array[String]=["MaquinaCafe","FrenteMaquinaRojo","PanelMaquina","BandejaMaquina","BoquillaCafe","BotonCafe","VasoCafe"]
	for n in shop.get_children():
		if not n is Node3D: continue
		for prefix in prefixes:
			if not str(n.name).begins_with(prefix): continue
			if n.position.x>0.0: n.visible=false
			else: n.position.x+=0.8
			if prefix=="FrenteMaquinaRojo": n.material_override=black
			break
	var meson:MeshInstance3D=shop.get_node("MesonEquipos")
	meson.position.x=-0.10
	resize_box(meson,Vector3(1.5,2.1,1.1))
	shop.set_meta("equipment_095543",true)
	var f:=FileAccess.open("res://reports/tienda_piso5_ajuste.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":str(shop.position),"rotation_y_degrees":90,"scale":str(shop.scale),"front":"+X","wall":"-Z","stairs":"+Z","path_preserved":"Piso5/TiendaEsquinaPiso5","reference":"WhatsApp Image 2026-10-19 at 09.55.43.jpeg"},"  "))
	return {"equipment_adjusted":true}
func move_to_emergency() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	if shop.has_meta("next_to_emergency"): return {"status":"already_moved"}
	var before:Vector3=shop.position
	shop.position=Vector3(-27.4,47.975,-145.3)
	shop.rotation.y=0.0
	var g:Node3D=shop.get_node("Referencia095543")
	var wood_panel:MeshInstance3D=g.get_node("MaderaLateral")
	wood_panel.position=Vector3(3.86,2.8,-1.3)
	resize_box(wood_panel,Vector3(0.045,5.6,5.8))
	g.get_node("DEA_Y_Plano").position=Vector3(3.65,2.35,1.2)
	# Abrir el antiguo tabique del nicho: solo la parte que invade el negocio.
	# Las piezas originales permanecen ocultas/deshabilitadas y se conservan sus rutas.
	var adaptation:Node3D=root.get_node("Piso5/DesembarcoTiendaReferencia")
	var hole:=AABB(Vector3(-32,47.95,-150.1),Vector3(9.2,6.0,10.8))
	var cut_count:=0
	for n in adaptation.get_children():
		if not n is MeshInstance3D or not n.visible or n.mesh==null: continue
		var a:AABB=n.global_transform*n.get_aabb()
		if a.size.y<2.0 or a.size.z<0.2: continue
		if a.intersection(hole).has_volume():
			adaptation.call("cut_wall",n,hole); cut_count+=1
	var layout:=group(root.get_node("Piso5"),"NichoNegocioEmergencia")
	layout.set_meta("reference","ubicación corregida por usuario: al lado de escalera de emergencia")
	# Tabique lateral al lado oeste del acceso de emergencia, sin invadir su marco.
	var wall:=box(layout,"TabiqueLateralNegocio",Vector3(-23.34,50.775,-146.7),Vector3(0.24,5.6,6.2),wood)
	var body:=StaticBody3D.new()
	body.name="Cuerpo"; owned(body,wall)
	var collision:=CollisionShape3D.new()
	collision.name="Colision"
	var shape:=BoxShape3D.new()
	shape.size=Vector3(0.24,5.6,6.2); collision.shape=shape; owned(collision,body)
	# Señal sobre el acceso del negocio; puerta de emergencia original intacta.
	var sign:=group(layout,"IdentificacionNegocio")
	sign.position=Vector3(-27.7,52.8,-144.25)
	box(sign,"Placa",Vector3.ZERO,Vector3(3.6,0.52,0.06),black)
	text(sign,"Texto","CAFETERÍA · PISO 5",Vector3(0,0,0.045),38,Color.WHITE,0.006)
	shop.set_meta("next_to_emergency",true)
	shop.set_meta("lado","junto_a_escalera_emergencia")
	shop.set_meta("orientacion","frente +Z; puerta emergencia a la derecha (+X)")
	var door:Node3D=root.get_node("Piso5/EscaleraEmergencia/PuertaPiso5")
	var report:Dictionary={"before":str(before),"position":str(shop.position),"front":"+Z","emergency_door":str(door.global_position),"center_distance":shop.global_position.distance_to(door.global_position),"partitions_cut":cut_count,"door_path_preserved":true}
	var f:=FileAccess.open("res://reports/tienda_piso5_ubicacion_emergencia.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	return report
func enlarge_and_close() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	if shop.has_meta("enlarged_closed"): return {"status":"already_enlarged"}
	# Crecer hacia la izquierda y hacia delante: el borde junto a la salida queda anclado.
	shop.scale=Vector3(1.35,0.95,1.18)
	shop.position=Vector3(-28.751,47.975,-144.517)
	var layout:Node3D=root.get_node("Piso5/NichoNegocioEmergencia")
	var side:MeshInstance3D=layout.get_node("TabiqueLateralNegocio")
	side.position=Vector3(-23.34,53.875,-146.85)
	resize_box(side,Vector3(0.24,11.8,6.4))
	var walls:=group(layout,"CierreCompletoNegocio")
	solid_box(walls,"CierrePosterior",Vector3(-28.78,53.875,-149.92),Vector3(11.1,11.8,0.20),mat(Color("a9aaa4")))
	solid_box(walls,"CierreLateralIzquierdo",Vector3(-34.22,53.875,-146.85),Vector3(0.20,11.8,6.4),mat(Color("a9aaa4")))
	# El dintel rellena la abertura sobre el negocio sin cerrar su frente de atención.
	solid_box(walls,"CierreSuperiorFrente",Vector3(-28.78,56.64,-143.75),Vector3(11.1,6.28,0.20),wood)
	var sign:Node3D=layout.get_node("IdentificacionNegocio")
	sign.position=Vector3(-28.8,53.17,-143.58)
	var floor_panel:MeshInstance3D=shop.get_node("PisoBaldosasTienda")
	floor_panel.position.z=-1.5
	resize_box(floor_panel,Vector3(8.0,0.024,5.6))
	shop.set_meta("enlarged_closed",true)
	var report:Dictionary={"position":str(shop.position),"scale":str(shop.scale),"width_increase_percent":35,"depth_increase_percent":18,"area_increase_percent":59.3,"emergency_side_anchored":true,"wall_height":11.8,"front_open":true}
	var f:=FileAccess.open("res://reports/tienda_piso5_ampliacion.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	return report
func trim_installations() -> Dictionary:
	setup()
	var shop:Node3D=root.get_node("Piso5/TiendaEsquinaPiso5")
	var tray:MeshInstance3D=shop.get_node("BandejaInstalaciones")
	resize_box(tray,Vector3(7.5,0.12,0.38))
	var pipes:=0
	for n in shop.find_children("TuberiaSuperior*","MeshInstance3D",true,false):
		if n.mesh is CylinderMesh:
			var mesh:CylinderMesh=n.mesh.duplicate()
			mesh.height=7.5; n.mesh=mesh; pipes+=1
	return {"tray_trimmed":true,"pipes_trimmed":pipes}
func solid_box(parent:Node3D,title:String,position_v:Vector3,size_v:Vector3,surface:Material) -> void:
	var n:=box(parent,title,position_v,size_v,surface)
	var body:=StaticBody3D.new()
	body.name="Cuerpo"; owned(body,n)
	var collision:=CollisionShape3D.new()
	collision.name="Colision"
	var shape:=BoxShape3D.new()
	shape.size=size_v; collision.shape=shape; owned(collision,body)
func resize_box(n:MeshInstance3D, size_v:Vector3) -> void:
	var mesh:BoxMesh=n.mesh.duplicate()
	mesh.size=size_v; n.mesh=mesh
	for c in n.find_children("*","CollisionShape3D",true,false):
		if c.shape is BoxShape3D:
			var shape:BoxShape3D=c.shape.duplicate()
			shape.size=size_v; c.shape=shape
