@tool
extends "res://scripts/pisos/piso_1/interior_coordinacion.gd"
## Acabados y mobiliario de las fotos; conserva los nodos de piso y techo.

func assembly(title: String, p: Vector3, angle: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = title
	n.position = p
	n.rotation.y = angle
	add_child(n)
	n.owner = owner
	return n

func part(parent: Node3D, title: String, p: Vector3, size: Vector3, key: String, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = p
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mats[key]
	parent.add_child(n)
	n.owner = owner
	if solid:
		var body := StaticBody3D.new()
		n.add_child(body)
		body.owner = owner
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		collision.owner = owner
	return n

func office_chair(p: Vector3, angle: float = 0.0, visitor: bool = false) -> void:
	var n := assembly("SillaEspera" if visitor else "SillaOficina",p,angle)
	part(n,"Asiento",Vector3(0,0.64,0),Vector3(0.95,0.15,0.9),"negro",true)
	part(n,"Respaldo",Vector3(0,1.16,0.4),Vector3(0.92,0.95,0.13),"negro",true)
	for side in [-1,1]:
		part(n,"Apoyabrazos",Vector3(side*0.58,0.94,0),Vector3(0.13,0.1,0.7),"negro")
		part(n,"SoporteBrazo",Vector3(side*0.58,0.76,0.1),Vector3(0.055,0.34,0.055),"metal")
	if visitor:
		for x in [-0.42,0.42]:
			for z in [-0.32,0.32]:
				part(n,"PataMetalica",Vector3(x,0.32,z),Vector3(0.045,0.6,0.045),"metal")
	else:
		part(n,"Piston",Vector3(0,0.34,0),Vector3(0.13,0.55,0.13),"metal")
		for i in range(5):
			var arm := part(n,"BaseGiratoria",Vector3(sin(i*TAU/5)*0.28,0.12,cos(i*TAU/5)*0.28),Vector3(0.065,0.07,0.65),"negro")
			arm.rotation.y = i*TAU/5
			part(n,"Rueda",Vector3(sin(i*TAU/5)*0.55,0.08,cos(i*TAU/5)*0.55),Vector3(0.14,0.14,0.14),"negro")

func equipment(parent: Node3D, p: Vector3) -> void:
	part(parent,"BaseMonitor",p+Vector3(0,0.06,0),Vector3(0.65,0.055,0.4),"negro")
	part(parent,"PieMonitor",p+Vector3(0,0.35,-0.08),Vector3(0.1,0.65,0.1),"negro")
	part(parent,"Monitor",p+Vector3(0,0.66,-0.08),Vector3(1.3,0.78,0.085),"negro")
	part(parent,"Pantalla",p+Vector3(0,0.66,-0.027),Vector3(1.17,0.65,0.018),"pantalla")
	part(parent,"VentanaPantalla",p+Vector3(-0.18,0.66,-0.015),Vector3(0.63,0.39,0.008),"blanco")
	part(parent,"BarraPantalla",p+Vector3(-0.18,0.88,-0.009),Vector3(0.63,0.035,0.008),"azul")
	part(parent,"Teclado",p+Vector3(0,0.08,0.58),Vector3(0.85,0.045,0.3),"negro")
	for i in range(9):
		part(parent,"Teclas",p+Vector3(-0.35+i*0.085,0.11,0.58),Vector3(0.025,0.01,0.24),"metal")
	part(parent,"Mouse",p+Vector3(0.68,0.085,0.58),Vector3(0.14,0.065,0.23),"negro")
	var phone := part(parent,"Telefono",p+Vector3(-0.92,0.18,0.45),Vector3(0.45,0.18,0.42),"negro")
	phone.rotation.x = -0.18
	part(parent,"Auricular",p+Vector3(-1.02,0.31,0.45),Vector3(0.11,0.1,0.43),"negro")
	part(parent,"DisplayTelefono",p+Vector3(-0.82,0.29,0.38),Vector3(0.18,0.025,0.14),"pantalla")
	part(parent,"Papeles",p+Vector3(0.94,0.07,0.42),Vector3(0.42,0.025,0.55),"blanco")
	part(parent,"PortaLapices",p+Vector3(0.87,0.16,-0.18),Vector3(0.14,0.26,0.14),"azul")
	for i in range(3):
		part(parent,"Lapiz",p+Vector3(0.83+i*0.04,0.35,-0.18),Vector3(0.012,0.27,0.012),"dorado")

func workstation(p: Vector3, angle: float = 0.0) -> void:
	var n := assembly("PuestoCoordinador",p,angle)
	part(n,"TableroMadera",Vector3(0,1.13,0),Vector3(3.3,0.14,1.65),"madera",true)
	for x in [-1.45,1.45]:
		for z in [-0.64,0.64]:
			part(n,"PataAcero",Vector3(x,0.56,z),Vector3(0.085,1.1,0.085),"metal")
		part(n,"TravesanoAcero",Vector3(x,0.17,0),Vector3(0.085,0.085,1.38),"metal")
	part(n,"CPU",Vector3(1.09,0.48,-0.12),Vector3(0.44,0.75,0.65),"negro")
	equipment(n,Vector3(0,1.22,-0.2))
	office_chair(p+Basis(Vector3.UP,angle)*Vector3(0,0,1.65),angle)

func glass_front(x1: float, x2: float, z: float, door: float, outside: bool = false) -> void:
	for span in [[x1,door-1.5],[door+1.5,x2]]:
		var width: float = span[1]-span[0]
		var center: float = (span[0]+span[1])*0.5
		box("MamparaVidrio",Vector3(center,2.42,z),Vector3(width,4.84,0.08),"vidrio")
		box("ViniloEsmerilado",Vector3(center,1.5,z+(-0.06 if outside else 0.06)),Vector3(width,2.15,0.018),"esmerilado",false)
		var count := ceili(width/3.0)
		for i in range(count+1):
			box("MontanteNegro",Vector3(span[0]+width*i/count,2.42,z),Vector3(0.09,4.84,0.14),"negro",false)
		for y in [0.15,3.55,4.84]:
			box("PerfilNegro",Vector3(center,y,z),Vector3(width,0.1,0.14),"negro",false)
	box("DintelVidrioPuerta",Vector3(door,4.32,z),Vector3(3,1.04,0.08),"vidrio")
	box("MarcoSuperiorPuerta",Vector3(door,3.78,z),Vector3(3.14,0.1,0.15),"negro",false)
	for side in [-1,1]:
		box("MarcoPuerta",Vector3(door+side*1.56,1.9,z),Vector3(0.12,3.8,0.14),"negro")
	# Hoja abierta, perpendicular a la mampara, mantiene el paso libre.
	box("PuertaAbiertaVidrio",Vector3(door-1.62,1.9,z+1.45),Vector3(0.08,3.7,2.9),"vidrio")
	box("TiradorPuerta",Vector3(door-1.53,1.6,z+2.5),Vector3(0.06,0.85,0.06),"metal",false)
	if outside:
		label("RotuloCoordinacion",Vector3(door,4.28,z-0.08),"COORDINACIÓN")
		get_node("RotuloCoordinacion").rotation.y = PI
		for x in [door-5.0,door+6.0]:
			label("Bienvenida",Vector3(x,1.7,z-0.085),"¡BIENVENIDOS!")
			get_child(get_child_count()-1).rotation.y = PI
			for y in [0.48,2.56]:
				box("LineaViniloDorada",Vector3(x,y,z-0.085),Vector3(5.5,0.025,0.012),"dorado",false)
		for y in [2.2,2.8]:
			box("AvisoPuerta",Vector3(door-1.05,y,z+0.12),Vector3(0.58,0.43,0.02),"blanco",false)
			box("CabeceraAviso",Vector3(door-1.05,y+0.15,z+0.105),Vector3(0.55,0.06,0.015),"azul",false)

func build() -> String:
	# Estos dos nodos se conservan completos, con materiales, geometría y colisiones.
	for child in get_children():
		if str(child.name) not in ["PisoCoordinacion","TechoCoordinacion"]:
			child.free()
	position = Vector3.ZERO
	colors.merge({"negro":Color(0.025,0.028,0.03),"metal":Color(0.28,0.3,0.31),"vidrio":Color(0.55,0.64,0.65,0.2),"esmerilado":Color(0.8,0.8,0.72,0.65)},true)
	colors.madera = Color(0.66,0.47,0.28)
	colors.pared = Color(0.87,0.86,0.79)
	for key in colors:
		var m := StandardMaterial3D.new()
		m.albedo_color = colors[key]
		m.roughness = 0.65
		mats[key] = m
	for key in ["vidrio","esmerilado"]:
		mats[key].transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mats[key].cull_mode = BaseMaterial3D.CULL_DISABLED
	# Vetado de madera para el mobiliario, sin alterar el suelo existente.
	var wood_shader := Shader.new()
	wood_shader.code = "shader_type spatial; varying vec3 p; void vertex(){p=VERTEX;} void fragment(){float grain=sin(p.y*48.0+sin(p.x*8.0+p.z*6.0)*3.0)*0.025+sin(p.y*135.0+p.x*12.0)*0.015; ALBEDO=vec3(0.58,0.43,0.29)+grain; ROUGHNESS=0.48;}"
	var wood := ShaderMaterial.new()
	wood.shader = wood_shader
	mats.madera = wood
	glass_front(33.0,83.7,-122.05,71.0,true)
	# Completa el muro por encima del techo conservado.
	box("MuroSuperiorEntrada",Vector3(58.3,8.48,-122.05),Vector3(50.7,6.97,0.505),"pared")
	# Al entrar hacia +Z: recepción a la izquierda (+X), espera a la derecha.
	var reception := assembly("Recepcion",Vector3(76.6,0,-116.7),PI/2)
	part(reception,"MesonMadera",Vector3(0,0.7,0),Vector3(8.6,1.4,1.1),"madera",true)
	part(reception,"CubiertaMeson",Vector3(0,1.42,0),Vector3(8.7,0.1,1.16),"madera",true)
	part(reception,"ZocaloMeson",Vector3(0,0.2,0.56),Vector3(8.4,0.25,0.03),"metal")
	for x in [-2.8,0.0,2.8]:
		equipment(reception,Vector3(x,1.49,-0.05))
		office_chair(Vector3(79,0,-116.7-x),PI/2)
	for z in [-119.0,-115.8,-112.6]:
		box("ArmarioMadera",Vector3(82.6,1.72,z),Vector3(0.75,3.25,3.05),"madera")
		for offset in [-0.74,0.74]:
			box("PuertaArmario",Vector3(82.18,1.74,z+offset),Vector3(0.06,3.15,1.46),"madera",false)
			box("TiradorArmario",Vector3(82.1,1.5,z+offset),Vector3(0.07,0.38,0.05),"metal",false)
	for z in [-119.2,-117.0,-114.8,-112.6]:
		office_chair(Vector3(65.6,0,z),-PI/2,true)
	# Pared detrás del mostrador; acceso a las oficinas alineado con la entrada.
	box("ParedRecepcion",Vector3(77.6,2.48,-109.5),Vector3(11.7,4.85,0.16),"pared")
	box("ParedEspera",Vector3(66.3,2.48,-109.5),Vector3(4.6,4.85,0.16),"pared")
	box("DintelOficinas",Vector3(70.2,4.25,-109.5),Vector3(3.2,1.35,0.16),"pared")
	box("PuertaMaderaAbierta",Vector3(68.5,1.8,-108),Vector3(0.12,3.4,2.9),"madera")
	box("ManillaOficina",Vector3(68.6,1.65,-106.85),Vector3(0.12,0.08,0.35),"metal",false)
	# Puestos de trabajo y despachos transparentes al fondo.
	for x in [39.0,48.0,57.0,77.0]:
		workstation(Vector3(x,0,-105.2))
	for x in [39.0,52.0,65.0,77.0]:
		workstation(Vector3(x,0,-96.7),PI)
	for span in [[33.0,46.0,43.0],[46.0,59.0,56.0],[59.0,72.0,69.0],[72.0,83.5,80.0]]:
		glass_front(span[0],span[1],-100.7,span[2])
		label("RotuloOficina",Vector3(span[0]+3,3.3,-100.58),"COORDINACIÓN\nACADÉMICA")
		get_child(get_child_count()-1).rotation.y = PI
		label("GraficaInformatica",Vector3(span[0]+3,1.5,-100.8),"</>\nINFORMÁTICA")
		get_child(get_child_count()-1).rotation.y = PI
	for x in [46.0,59.0,72.0]:
		box("DivisionDespachos",Vector3(x,2.45,-97.1),Vector3(0.08,4.8,7),"vidrio")
		box("PerfilDivision",Vector3(x,2.45,-93.6),Vector3(0.1,4.8,0.12),"negro",false)
	# Impresora multifunción junto a los puestos, con bandejas y panel inclinado.
	box("Fotocopiadora",Vector3(34.6,0.85,-106),Vector3(1.5,1.6,1.4),"blanco")
	box("Scanner",Vector3(34.6,1.75,-106),Vector3(1.5,0.2,1.4),"negro",false)
	for y in [0.4,0.85,1.25]:
		box("CajonImpresora",Vector3(34.6,y,-105.27),Vector3(1.3,0.25,0.055),"metal",false)
	box("PanelImpresora",Vector3(35.1,1.95,-105.5),Vector3(0.45,0.18,0.4),"negro",false)
	# Paneles luminosos fijados bajo el techo actual; no se crea otro techo.
	mats.blanco.emission_enabled = true
	mats.blanco.emission = Color(1,0.96,0.9)
	mats.blanco.emission_energy_multiplier = 0.35
	for x in [39.0,52.0,65.0,77.0]:
		for z in [-117.0,-105.0,-96.0]:
			light_at("LuzReferencia"+str(x)+str(z),Vector3(x,4.87,z))
	set_meta("referencias","Fotos coordinación 2026-10-09: entrada, recepción y oficinas; suelo y techo conservados")
	return "Coordinación actualizada sin cambiar suelo ni techo"
