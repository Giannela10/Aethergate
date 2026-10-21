extends SceneTree
## Regenera exclusivamente el pasillo derecho y la capilla de las referencias.
var scene: Node3D
var corridorRoot: Node3D
var mats: Dictionary = {}

func material(key: String, color: Color, roughness: float = 0.7) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	mats[key] = m

func box(parent: Node3D, title: String, p: Vector3, size: Vector3, key: String, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	n.position = p
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = mats[key]
	parent.add_child(n)
	n.owner = scene
	if solid:
		var body := StaticBody3D.new()
		n.add_child(body)
		body.owner = scene
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		collision.owner = scene
	return n

func label(parent: Node3D, content: String, p: Vector3, key: String, scale_value: float = 0.008) -> void:
	var n := Label3D.new()
	n.text = content
	n.position = p
	n.font_size = 64
	n.pixel_size = scale_value
	n.modulate = mats[key].albedo_color
	parent.add_child(n)
	n.owner = scene

func light(parent: Node3D, p: Vector3, warm: bool) -> void:
	var n := OmniLight3D.new()
	n.position = p
	n.light_color = Color(1.0,0.85,0.65) if warm else Color(0.9,0.94,1.0)
	n.light_energy = 1.5
	n.omni_range = 14
	parent.add_child(n)
	n.owner = scene

func cross_at(parent: Node3D, p: Vector3, scale_value: float, key: String) -> void:
	box(parent,"CruzVertical",p,Vector3(0.13,1.7,0.12)*scale_value,key)
	box(parent,"CruzHorizontal",p+Vector3(0,0.35,0)*scale_value,Vector3(0.95,0.13,0.12)*scale_value,key)

func _initialize() -> void:
	scene = load("res://Main.tscn").instantiate()
	var piso := scene.get_node("Piso1")
	var old := piso.get_node_or_null("PasilloDerechoYCapilla")
	if old:
		old.free()
	corridorRoot = Node3D.new()
	corridorRoot.name = "PasilloDerechoYCapilla"
	piso.add_child(corridorRoot)
	corridorRoot.owner = scene
	material("black",Color(0.055,0.06,0.065),0.38)
	material("wall",Color(0.66,0.64,0.59))
	material("cream",Color(0.88,0.84,0.73))
	material("white",Color(0.95,0.93,0.87))
	material("wood",Color(0.34,0.145,0.055),0.34)
	material("ceilingwood",Color(0.38,0.22,0.12))
	material("gold",Color(0.73,0.5,0.15),0.28)
	material("blue",Color(0.035,0.09,0.52))
	material("yellow",Color(0.95,0.67,0.07))
	material("tile",Color(0.25,0.24,0.22),0.3)
	material("glass",Color(0.22,0.27,0.27,0.3),0.18)
	mats.glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	material("frost",Color(0.53,0.57,0.54,0.8),0.6)
	mats.frost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material("lamp",Color(0.95,0.96,1.0))
	mats.lamp.emission_enabled = true
	mats.lamp.emission = Color(1,0.94,0.8)
	mats.lamp.emission_energy_multiplier = 2.5
	# El pasillo se recorre hacia +X; las salas del lado izquierdo están al norte.
	# Se sustituye el frente opaco, incluyendo su colisión, por mamparas accesibles.
	var wall := piso.get_node("MeshInstance3D12")
	wall.hide()
	for c in wall.find_children("*","CollisionShape3D",true,false):
		c.disabled = true
	box(corridorRoot,"MuroSobreMamparas",Vector3(52.0345,9,-143.9405),Vector3(38.58072,6,0.2475),"wall",true)
	var shader := Shader.new()
	shader.code = "shader_type spatial; varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){vec2 uv=world.xz*vec2(0.65,2.8); vec2 f=fract(uv); float joint=max(step(0.965,f.x),step(0.94,f.y)); float grain=fract(sin(dot(floor(uv),vec2(12.9898,78.233)))*43758.5453); ALBEDO=mix(vec3(0.25+grain*0.065),vec3(0.43),joint); ROUGHNESS=0.38;}"
	var tile := ShaderMaterial.new()
	tile.shader = shader
	box(corridorRoot,"PavimentoPasillo",Vector3(54,0.055,-133),Vector3(47,0.08,20),"tile").material_override = tile
	# Techo oscuro, conductos y luminarias longitudinales.
	box(corridorRoot,"TechoIndustrial",Vector3(54,6.65,-133),Vector3(47,0.16,20),"black")
	for z in [-140.0,-126.0]:
		box(corridorRoot,"ConductoInstalaciones",Vector3(54,6.2,z),Vector3(46,0.38,0.48),"wall")
		for x in [36.0,46.0,56.0,66.0,75.0]:
			box(corridorRoot,"LuminariaLineal",Vector3(x,5.95,z),Vector3(5.4,0.09,0.16),"lamp")
			light(corridorRoot,Vector3(x,5.6,z),false)
	for x in range(33,78,5):
		box(corridorRoot,"TravesanoTecho",Vector3(x,6.4,-133),Vector3(0.12,0.18,20),"wall")
	# Mamparas con puertas abiertas de 3 metros; última puerta: capilla.
	for section in [[33.0,42.0,39.0],[42.0,54.0,49.0],[54.0,71.0,65.0]]:
		var start: float = section[0]
		var end: float = section[1]
		var door: float = section[2]
		for span in [[start,door-1.5],[door+1.5,end]]:
			var center: float = (span[0]+span[1])*0.5
			var width: float = span[1]-span[0]
			box(corridorRoot,"MamparaVidrio",Vector3(center,2.8,-143.65),Vector3(width,5.6,0.09),"glass",true)
			box(corridorRoot,"ViniloEsmerilado",Vector3(center,1.55,-143.58),Vector3(width,2.5,0.02),"frost")
			for y in [0.18,3.0,5.6]:
				box(corridorRoot,"PerfilHorizontal",Vector3(center,y,-143.55),Vector3(width,0.09,0.12),"black")
			var count := ceili(width/2.4)
			for i in range(count+1):
				box(corridorRoot,"PerfilVertical",Vector3(span[0]+width*i/count,2.8,-143.55),Vector3(0.08,5.6,0.12),"black")
		box(corridorRoot,"DintelPuerta",Vector3(door,4.85,-143.65),Vector3(3,1.5,0.15),"black",true)
		for side in [-1,1]:
			box(corridorRoot,"JambaPuerta",Vector3(door+side*1.55,2.05,-143.55),Vector3(0.14,4.1,0.16),"black",true)
		label(corridorRoot,"CAPILLA" if door == 65 else "FINANCIAMIENTO" if door == 39 else "APOYO ESTUDIANTIL",Vector3(door,4.55,-143.45),"white",0.006)
		if door == 65:
			cross_at(corridorRoot,Vector3(door,5.45,-143.43),0.48,"gold")
		else:
			label(corridorRoot,"Tu futuro\ncomienza aquí",Vector3(start+2,1.8,-143.48),"blue",0.007)
			box(corridorRoot,"GraficaAmarilla",Vector3(start+0.4,1.55,-143.45),Vector3(0.2,2.3,0.025),"yellow")
	for span in [[33.0,37.5],[40.5,47.5],[50.5,63.5],[66.5,71.0]]:
		for y in range(8):
			box(corridorRoot,"RevestimientoListonado",Vector3((span[0]+span[1])*0.5,3.55+y*0.35,-143.44),Vector3(span[1]-span[0],0.28,0.06),"wall")
	# Interior de la capilla: volumen existente x54..71, z-162..-144.
	var chapel := Node3D.new()
	chapel.name = "Capilla"
	corridorRoot.add_child(chapel)
	chapel.owner = scene
	box(chapel,"PisoCapilla",Vector3(62.5,0.11,-153),Vector3(16.6,0.14,18.4),"tile",true)
	box(chapel,"ParedIzquierda",Vector3(54.2,3,-153),Vector3(0.2,6,18.4),"cream",true)
	box(chapel,"ParedFondo",Vector3(62.5,3,-162.1),Vector3(16.6,6,0.2),"cream",true)
	box(chapel,"ParedDerecha",Vector3(70.8,3,-153),Vector3(0.2,6,18.4),"cream",true)
	box(chapel,"CieloBlanco",Vector3(62.5,6,-153),Vector3(16.6,0.18,18.4),"white")
	# Baldosas oscuras con juntas finas y brillo suave.
	var chapel_shader := Shader.new()
	chapel_shader.code = "shader_type spatial; varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){vec2 f=fract(world.xz*0.75); float joint=max(step(0.985,f.x),step(0.985,f.y)); ALBEDO=mix(vec3(0.095,0.085,0.075),vec3(0.25,0.23,0.21),joint); ROUGHNESS=0.28;}"
	var chapel_floor := ShaderMaterial.new()
	chapel_floor.shader = chapel_shader
	chapel.get_node("PisoCapilla").material_override = chapel_floor
	# Ventanas pequeñas de colores y marcos oscuros en el lateral izquierdo.
	for z in [-148.0,-152.0,-156.0]:
		box(chapel,"MarcoVitral",Vector3(54.35,2.85,z),Vector3(0.12,0.85,2.6),"wood")
		for i in range(6):
			box(chapel,"VidrioColorVitral",Vector3(54.43,2.85,z-1.05+i*0.42),Vector3(0.06,0.64,0.38),["blue","gold","cream","yellow","glass","blue"][i])
		box(chapel,"TravesanoVitral",Vector3(54.47,2.85,z),Vector3(0.04,0.04,2.5),"black")
	box(chapel,"AireAcondicionado",Vector3(62,5.7,-153),Vector3(2.2,0.25,2.2),"cream")
	for i in range(9):
		box(chapel,"RejillaAire",Vector3(62,5.55,-153.8+i*0.2),Vector3(1.7,0.025,0.055),"wall")
	for z in [-146.0,-149.0,-152.0,-155.0,-158.0,-161.0]:
		box(chapel,"FranjaClaraPasillo",Vector3(67.8,0.192,z),Vector3(2.6,0.018,1.35),"cream")
	for x in [57.0,62.0,67.0]:
		for z in [-147.0,-151.0,-155.0]:
			box(chapel,"PanelCieloMadera",Vector3(x,5.87,z),Vector3(4.8,0.1,3.8),"ceilingwood")
			box(chapel,"FocoEmpotrado",Vector3(x,5.79,z),Vector3(0.34,0.06,0.34),"lamp")
	for z in [-146.4,-149.2,-152.0,-154.8]:
		box(chapel,"AsientoBanco",Vector3(60.5,0.85,z),Vector3(8.0,0.19,1.05),"wood",true)
		for y in [1.35,1.72]:
			box(chapel,"RespaldoBanco",Vector3(60.5,y,z+0.5),Vector3(8.0,0.24,0.13),"wood",true)
		box(chapel,"Reclinatorio",Vector3(60.5,0.3,z+1),Vector3(7.6,0.12,0.32),"wood",true)
		for x in [57.0,60.5,64.0]:
			box(chapel,"PataBanco",Vector3(x,0.46,z),Vector3(0.17,0.74,0.85),"wood",true)
			box(chapel,"SoporteRespaldo",Vector3(x,1.1,z+0.5),Vector3(0.14,1.35,0.14),"wood")
	box(chapel,"Presbiterio",Vector3(62.5,0.3,-159.5),Vector3(15.8,0.35,4.8),"cream",true)
	box(chapel,"MesaAltar",Vector3(61.8,1.5,-159.3),Vector3(7.2,0.2,2.1),"white",true)
	box(chapel,"MantelAltar",Vector3(61.8,1.03,-158.25),Vector3(7.25,1.1,0.045),"white")
	for x in [59.0,64.6]:
		box(chapel,"BaseAltar",Vector3(x,0.9,-159.3),Vector3(0.25,1.1,1.5),"wood",true)
	box(chapel,"NichoAltar",Vector3(61.8,3.5,-161.95),Vector3(7.5,4.3,0.15),"wall")
	cross_at(chapel,Vector3(61.8,4,-161.72),1.5,"wood")
	box(chapel,"AltarPosterior",Vector3(61.8,1.65,-161.1),Vector3(7,0.3,0.9),"cream")
	box(chapel,"Sagrario",Vector3(61.8,2.3,-161.15),Vector3(0.85,1,0.7),"gold")
	cross_at(chapel,Vector3(61.8,2.3,-160.77),0.28,"wood")
	for x in [59.0,64.5]:
		box(chapel,"Candelabro",Vector3(x,1.95,-159.2),Vector3(0.12,0.6,0.12),"gold")
		box(chapel,"Vela",Vector3(x,2.32,-159.2),Vector3(0.13,0.22,0.13),"white")
		box(chapel,"Llama",Vector3(x,2.47,-159.2),Vector3(0.06,0.08,0.06),"lamp")
	for x in [58.8,64.8]:
		box(chapel,"Florero",Vector3(x,2.04,-161),Vector3(0.32,0.48,0.32),"gold")
		for i in range(5):
			var flower := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.15
			sphere.height = 0.3
			flower.mesh = sphere
			flower.material_override = mats.white
			flower.position = Vector3(x+sin(i*2.4)*0.3,2.5+cos(i*1.7)*0.12,-161+cos(i*2.4)*0.25)
			chapel.add_child(flower)
			flower.owner = scene
	# Confesionario a la derecha del altar, con ventanilla cuadriculada.
	box(chapel,"Confesionario",Vector3(69,2,-159),Vector3(2.8,3.7,2.4),"cream",true)
	box(chapel,"MarcoConfesionario",Vector3(69,2.25,-157.77),Vector3(1.8,2.5,0.06),"black")
	box(chapel,"VidrioConfesionario",Vector3(69,2.25,-157.72),Vector3(1.55,2.25,0.025),"frost")
	for i in range(7):
		box(chapel,"RejillaHorizontal",Vector3(69,1.2+i*0.35,-157.68),Vector3(1.55,0.025,0.025),"black")
	for i in range(5):
		box(chapel,"RejillaVertical",Vector3(68.3+i*0.35,2.25,-157.68),Vector3(0.025,2.25,0.025),"black")
	label(chapel,"CONFESIONARIO",Vector3(69,4.3,-157.72),"wood",0.0035)
	for z in [-147.0,-153.0,-159.0]:
		light(chapel,Vector3(62,5.4,z),true)
	# Al entrar desde el pasillo (-Z), el fondo litúrgico queda a la derecha (+X).
	# Se gira el mobiliario y sus colisiones sin mover los muros ni la entrada.
	var pivot := Vector3(62.5,0,-153)
	var turn := Basis(Vector3.UP,-PI/2)
	for child in chapel.get_children():
		var title := str(child.name)
		if child is OmniLight3D or title.begins_with("Pared") or title.begins_with("Piso") or title.begins_with("Cielo") or title.begins_with("PanelCielo") or title.begins_with("FocoEmpotrado") or title.begins_with("AireAcondicionado") or title.begins_with("RejillaAire"):
			continue
		child.position = pivot + turn * (child.position-pivot) + Vector3(-0.9,0,0)
		child.basis = turn * child.basis
	chapel.set_meta("orientacion","Altar y confesionario hacia la derecha al entrar (+X)")
	corridorRoot.set_meta("referencias","WhatsApp 2026-10-09: pasillo derecho y capilla; última puerta izquierda al recorrer hacia +X")
	var packed := PackedScene.new()
	var error := packed.pack(scene)
	if error == OK:
		error = ResourceSaver.save(packed,"res://Main.tscn")
	print("PASILLO_CAPILLA_SAVE=",error)
	scene.free()
	quit(error)
