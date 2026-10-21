@tool
extends Node3D
## Constructor manual: guarda geometría estática, nunca reconstruye al jugar.
var root: Node
var floor_mat: ShaderMaterial
var wood: ShaderMaterial
var black: Material
var silver: Material
var white: Material
var yellow: Material
var stats := {}
func mat(c: Color, rough: float = 0.75, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=c; m.roughness=rough; m.metallic=metal
	return m
func owned(n: Node, p: Node) -> void:
	p.add_child(n,true); n.owner=root
func group(p: Node, title: String) -> Node3D:
	var n:=Node3D.new()
	n.name=title; owned(n,p); return n
func box(p: Node, title: String, pos: Vector3, size_v: Vector3, material: Material) -> MeshInstance3D:
	var n:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size_v; n.name=title; n.mesh=mesh; n.material_override=material
	owned(n,p); n.position=pos; n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n
func cylinder(p: Node, title: String, pos: Vector3, radius: float, height: float, material: Material, top: float=-1.0) -> MeshInstance3D:
	var n:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.bottom_radius=radius; mesh.top_radius=radius if top<0 else top; mesh.height=height
	mesh.radial_segments=16; mesh.rings=1
	n.name=title; n.mesh=mesh; n.material_override=material; owned(n,p); n.position=pos
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n
func sphere(p: Node, title: String, pos: Vector3, size_v: Vector3, material: Material) -> MeshInstance3D:
	var n:=MeshInstance3D.new()
	var mesh:=SphereMesh.new()
	mesh.radius=0.5; mesh.height=1.0; mesh.radial_segments=20; mesh.rings=12
	n.name=title; n.mesh=mesh; n.material_override=material; owned(n,p); n.position=pos; n.scale=size_v
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n
func text(p: Node, title: String, words: String, pos: Vector3, font_size: int=40, color: Color=Color.WHITE, pixel: float=0.008) -> Label3D:
	var n:=Label3D.new()
	n.name=title; n.text=words; n.font_size=font_size; n.pixel_size=pixel; n.modulate=color
	n.outline_size=0; n.no_depth_test=false; n.shaded=false
	owned(n,p); n.position=pos; return n
func setup() -> void:
	root=get_tree().edited_scene_root
	floor_mat=ShaderMaterial.new(); floor_mat.shader=load("res://materials/entrance/piso_fotos.gdshader")
	wood=ShaderMaterial.new(); wood.shader=load("res://materials/entrance/madera_salas_fotos.gdshader")
	black=mat(Color("181d20")); silver=mat(Color("aeb3b5"),0.35,0.75)
	white=mat(Color("dddedd")); yellow=mat(Color("ecc633"))
func snapshot() -> Dictionary:
	root=get_tree().edited_scene_root
	var data: Dictionary={"nodes":[],"collisions":{}}
	for n in root.find_children("*","",true,false):
		data.nodes.append(str(root.get_path_to(n)))
		if n is CollisionShape3D:
			data.collisions[str(root.get_path_to(n))]={"transform":str(n.global_transform),"disabled":n.disabled}
	var f:=FileAccess.open("res://reports/arquitectura_antes.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	return {"nodes":data.nodes.size(),"collisions":data.collisions.size()}
func census() -> Array:
	root=get_tree().edited_scene_root
	var result: Array=[]
	for n in root.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("puerta_vidrio_salas.gd"):
			result.append(str(root.get_path_to(n)))
	return result
func mark_editable() -> void:
	for n in root.find_children("*","",true,false):
		if not n.scene_file_path.is_empty(): root.set_editable_instance(n,true)
func floor_of(n: Node) -> int:
	var path:=str(root.get_path_to(n))
	for i in range(2,9):
		if path.begins_with("Piso%d/"%i): return i
	return 0
func room_number(n: Node) -> String:
	var p: Node=n.get_parent()
	var rx:=RegEx.new()
	rx.compile("^(Sala)?([2-8][0-9][0-9][AB]?)$")
	while p!=null and p!=root:
		var found:=rx.search(str(p.name))
		if found:
			var number:=found.get_string(2)
			var floor_i:=floor_of(n)
			if floor_i>=6: number=str(floor_i)+number.substr(1)
			return number
		p=p.get_parent()
	return ""
func make_door(door: Node3D, number: String) -> void:
	if door.has_meta("photo_hinged"): return
	var left:=door.get_node("HojaIzquierda") as AnimatableBody3D
	var right:=door.get_node("HojaDerecha") as AnimatableBody3D
	var h:float=2.76
	for s in left.find_children("*","CollisionShape3D",true,false):
		if s.shape is BoxShape3D: h=maxf(h,s.shape.size.y)
	var width:float=float(door.get("ancho"))
	for leaf in [left,right]:
		for s in leaf.find_children("*","CollisionShape3D",true,false): s.disabled=true
		for v in leaf.find_children("*","VisualInstance3D",true,false): v.visible=false
	right.visible=false; right.collision_layer=0
	left.position=Vector3(-width*0.5,0,0)
	left.rotation=Vector3.ZERO
	var face:=group(left,"PuertaMaderaReferencia")
	box(face,"HojaMaple",Vector3(width*0.5,h*0.5,0),Vector3(width-0.045,h-0.025,0.095),wood)
	for side in [-1.0,1.0]:
		var vent:=box(face,"RejillaInferior",Vector3(width*0.5,0.34,side*0.053),Vector3(width*0.64,0.38,0.025),mat(Color("786b58")))
		for j in range(6):
			box(vent,"Lama",Vector3(0,-0.145+j*0.058,side*0.019),Vector3(width*0.60,0.023,0.023),silver)
		box(face,"PlacaCerradura",Vector3(width-0.19,h*0.49,side*0.065),Vector3(0.10,0.29,0.025),silver)
		box(face,"Manilla",Vector3(width-0.29,h*0.50,side*0.12),Vector3(0.28,0.045,0.065),silver)
		box(face,"FichaBlanca",Vector3(width*0.51,h*0.69,side*0.052),Vector3(0.27,0.37,0.008),white)
		for j in range(5):
			box(face,"LineaFicha",Vector3(width*0.51,h*0.69+0.1-j*0.045,side*0.058),Vector3(0.19,0.008,0.003),black)
	var collision:=CollisionShape3D.new()
	collision.name="ColisionHojaMadera"
	var shape:=BoxShape3D.new()
	shape.size=Vector3(width-0.045,h-0.025,0.10)
	collision.shape=shape; owned(collision,left); collision.position=Vector3(width*0.5,h*0.5,0)
	var front:=group(door,"FrenteSalaReferencia")
	for side in [-1.0,1.0]:
		box(front,"MarcoNegro",Vector3(side*(width*0.5+0.035),h*0.5,0),Vector3(0.07,h+0.12,0.14),black)
	box(front,"DintelNegro",Vector3(0,h+0.04,0),Vector3(width+0.14,0.08,0.14),black)
	# Señales mirando hacia el pasillo; las hojas conservan las rutas de campaña.
	var sign:=group(front,"CartelSala")
	sign.position=Vector3(-width*0.5-0.65,h*0.73,0.13)
	box(sign,"PlacaBlanca",Vector3.ZERO,Vector3(1.02,0.32,0.035),white)
	box(sign,"BandaVerde",Vector3(-0.39,0,0.025),Vector3(0.23,0.32,0.025),mat(Color("369241")))
	text(sign,"Sala","SALA",Vector3(-0.39,0,0.045),20,Color.WHITE,0.0036)
	text(sign,"Numero",number,Vector3(0.10,0,0.045),32,Color.BLACK,0.005)
	box(sign,"Informacion",Vector3(0,-0.34,0),Vector3(0.72,0.18,0.025),black)
	text(sign,"Info","INFORMACIÓN",Vector3(0,-0.34,0.025),20,Color("e8a436"),0.0026)
	box(sign,"Horario",Vector3(0,-0.86,0),Vector3(0.66,0.71,0.025),white)
	box(sign,"TituloHorario",Vector3(0,-0.57,0.025),Vector3(0.66,0.13,0.015),mat(Color("d68632")))
	text(sign,"Titulo","HORARIO DE CLASES",Vector3(0,-0.57,0.04),20,Color.WHITE,0.0019)
	for j in range(8): box(sign,"Renglon",Vector3(0,-0.67-j*0.065,0.02),Vector3(0.61,0.006,0.005),silver)
	for j in range(4): box(sign,"Columna",Vector3(-0.23+j*0.15,-0.91,0.02),Vector3(0.005,0.53,0.005),silver)
	door.set_meta("photo_hinged",true)
	door.set_meta("photo_room",number)
	stats.doors+=1
func build() -> Dictionary:
	setup()
	if has_meta("built"): return {"status":"already_built","stats":get_meta("stats")}
	mark_editable()
	stats={"floors":0,"doors":0,"classrooms":0,"stair_edges":0}
	var heights: Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
	var rooms: Dictionary={}
	for n in root.find_children("*","MeshInstance3D",true,false):
		var fi:=floor_of(n)
		if fi==0 or n.mesh==null: continue
		var a: AABB=n.global_transform*n.get_aabb()
		if a.size.y<0.65 and a.size.x*a.size.z>1.0 and absf(a.end.y-heights[fi])<0.55:
			n.material_override=floor_mat; n.set_meta("photo_floor",true); stats.floors+=1
		# Las aulas conservan su equipamiento y especialidad.
		if str(n.name).contains("RevestimientoBeige"):
			n.material_override=wood
	for n in root.find_children("*","Node3D",true,false):
		if floor_of(n)==0 or n.get_script()==null: continue
		if not str(n.get_script().resource_path).ends_with("puerta_vidrio_salas.gd"): continue
		var number:=room_number(n)
		if number.is_empty(): continue
		make_door(n,number)
		rooms[n.get_parent().get_path()]=n.get_parent()
	for room in rooms.values(): decorate_room(room)
	add_stairs()
	refine_cafe()
	build_entry()
	set_meta("built",true); set_meta("stats",stats)
	return stats
func decorate_room(room: Node3D) -> void:
	if room.get_node_or_null("DetallesSalaFotos")!=null: return
	var g:=group(room,"DetallesSalaFotos")
	var sx:float=10.0
	var depth:float=14.0
	var floor_y:float=0.0
	for n in room.find_children("*","MeshInstance3D",true,false):
		var title:=str(n.name).to_lower()
		if n.mesh==null: continue
		if title.contains("tablero") or title.contains("tableromesa"): n.material_override=white
		if title.contains("asiento") or title.contains("respaldo"): n.material_override=black
		if title.contains("suelo") or title.contains("piso"):
			var a: AABB=room.global_transform.affine_inverse()*n.global_transform*n.get_aabb()
			if a.size.x>5 and a.size.z>5:
				sx=a.size.x; depth=a.size.z; floor_y=a.end.y
	var ceiling_y:float=9.7
	for n in room.find_children("*","MeshInstance3D",true,false):
		if str(n.name).to_lower().contains("techo") and n.mesh!=null:
			var a: AABB=room.global_transform.affine_inverse()*n.global_transform*n.get_aabb()
			ceiling_y=clampf(a.position.y-0.6,3.6,10.3)
	# Tramos estrechos suspendidos: bandejas de cable y luminarias, sin nuevos obstáculos.
	for row in [0.3,0.7]:
		var z:float=-depth*float(row)
		box(g,"BandejaCables",Vector3(0,ceiling_y,z),Vector3(sx*0.84,0.08,0.34),silver)
		for i in range(8):
			box(g,"TravesanoBandeja",Vector3(-sx*0.38+i*sx*0.108,ceiling_y+0.06,z),Vector3(0.035,0.10,0.42),silver)
		for xside in [-0.23,0.23]:
			var x:float=sx*float(xside)
			box(g,"SuspensionLED",Vector3(x,ceiling_y-0.28,z),Vector3(0.025,0.55,0.025),black)
			box(g,"CarcasaLED",Vector3(x,ceiling_y-0.59,z),Vector3(2.4,0.14,0.20),silver)
			var glow:=mat(Color("f4f2dd"))
			glow.emission_enabled=true; glow.emission=Color("fff9df"); glow.emission_energy_multiplier=0.7
			box(g,"DifusorLED",Vector3(x,ceiling_y-0.67,z),Vector3(2.3,0.025,0.16),glow)
	stats.classrooms+=1
func add_stairs() -> void:
	for n in root.find_children("Step*","MeshInstance3D",true,false):
		if floor_of(n)==0 or n.mesh==null: continue
		var path:=str(n.get_path())
		if not path.to_lower().contains("escalera"): continue
		var a:AABB=n.global_transform*n.get_aabb()
		if a.size.y>1.0 or a.size.x*a.size.z<1: continue
		n.material_override=mat(Color("25292c"),0.56)
		var parent:=group(self,"BordePeldaño")
		parent.global_position=a.get_center()
		var along_x:bool=a.size.x<a.size.z
		var sz:=Vector3(0.10,0.035,a.size.z*0.98) if along_x else Vector3(a.size.x*0.98,0.035,0.10)
		# Ambas aristas garantizan lectura de seguridad sin alterar la colisión.
		for side in [-1.0,1.0]:
			var pos:=Vector3(side*(a.size.x*0.5-0.055),a.size.y*0.5+0.022,0) if along_x else Vector3(0,a.size.y*0.5+0.022,side*(a.size.z*0.5-0.055))
			box(parent,"NarizAmarilla",pos,sz,yellow)
		stats.stair_edges+=1
func refine_cafe() -> void:
	var cafe:=root.get_node_or_null("Piso3/LocalComidaReferencia") as Node3D
	if cafe==null: return
	var g:=group(cafe,"DetallesParadisoFotos")
	for label in cafe.find_children("*","Label3D",true,false):
		if str(label.name).contains("RotuloLocal"):
			label.text="paradiso Café"; label.modulate=Color("e9423e"); label.outline_modulate=Color("fff3dd"); label.outline_size=12
	for n in cafe.find_children("*","MeshInstance3D",true,false):
		if str(n.name).contains("Mostrador") or str(n.name).contains("PanelMadera"): n.material_override=wood
	var counter:=cafe.get_node_or_null("MostradorYProductos") as Node3D
	if counter==null: return
	var detail:=group(counter,"EquipamientoCafeFotos")
	box(detail,"CafeteraAcero",Vector3(3.1,3.35,-0.9),Vector3(1.65,0.85,0.72),silver)
	box(detail,"FrenteCafetera",Vector3(3.1,3.45,-0.48),Vector3(1.45,0.48,0.07),black)
	box(detail,"BandejaCafetera",Vector3(3.1,2.98,-0.31),Vector3(1.55,0.08,0.38),silver)
	for x in [2.7,3.1,3.5]:
		cylinder(detail,"SalidaCafe",Vector3(float(x),3.15,-0.35),0.04,0.16,silver)
		cylinder(detail,"Taza",Vector3(float(x),3.10,-0.22),0.105,0.18,white)
	for i in range(12):
		cylinder(detail,"VasoExhibicion",Vector3(-5.5+i*0.29,5.16,-0.9),0.11,0.25,mat(Color("ecae50") if i%3==0 else Color("f4eee1")))
	for row in range(2):
		for col in range(7):
			sphere(detail,"Pasteleria",Vector3(-5.4+col*0.55,2.65+row*0.65,0.02),Vector3(0.40,0.20,0.28),mat(Color("bd8044")))
	var fridge:=group(g,"CabeceraBebidas")
	fridge.position=Vector3(9.55,4.65,-37.43)
	box(fridge,"FranjaNaranja",Vector3.ZERO,Vector3(2.7,0.44,0.10),mat(Color("eb8b2f")))
	text(fridge,"Bebidas","BEBIDAS FRÍAS",Vector3(0,0,0.065),34,Color.WHITE,0.005)
func build_entry() -> void:
	var exterior:=root.get_node("Exterior") as Node3D
	var g:=group(exterior,"JardinYEntradaFotos")
	g.set_meta("reference","WhatsApp 2026-10-19 09.24.09 y 09.24.10")
	var stone:=mat(Color("797c7a"),0.9)
	var grass:=mat(Color("485e37"))
	# Estatua devocional en jardín lateral, fuera del acceso principal.
	var statue:=group(g,"EstatuaJardin")
	statue.position=Vector3(62,0.18,-60)
	box(statue,"Base",Vector3(0,0.14,0),Vector3(1.8,0.28,1.6),stone)
	box(statue,"Pedestal",Vector3(0,0.92,0),Vector3(1.15,1.3,1.04),white)
	box(statue,"Cornisa",Vector3(0,1.62,0),Vector3(1.38,0.14,1.25),stone)
	var robe:=lathe_robe()
	var n:=MeshInstance3D.new()
	n.name="TunicaPliegues"; n.mesh=robe; n.material_override=stone; owned(n,statue); n.position.y=1.70
	sphere(statue,"Torso",Vector3(0,3.70,0),Vector3(0.70,1.15,0.43),stone)
	sphere(statue,"Cabeza",Vector3(0,4.48,0.02),Vector3(0.43,0.55,0.40),stone)
	sphere(statue,"Velo",Vector3(0,4.37,-0.12),Vector3(0.65,0.90,0.40),white)
	sphere(statue,"Rostro",Vector3(0,4.46,0.16),Vector3(0.35,0.44,0.26),stone)
	sphere(statue,"Nariz",Vector3(0,4.45,0.30),Vector3(0.075,0.14,0.09),stone)
	for side in [-1.0,1.0]:
		var arm:=sphere(statue,"Manga",Vector3(side*0.48,3.52,0.03),Vector3(0.27,0.98,0.30),stone)
		arm.rotation.z=side*0.43
		var hand:=sphere(statue,"ManoAbierta",Vector3(side*0.76,3.12,0.14),Vector3(0.19,0.32,0.10),stone)
		hand.rotation.z=side*0.40
		for j in range(4):
			sphere(statue,"Dedo",Vector3(side*(0.71+j*0.032),3.00,0.16),Vector3(0.032,0.17,0.042),stone)
	box(g,"ParterreEstatua",Vector3(62,0.195,-60),Vector3(5.8,0.10,4.3),grass)
	for i in range(8):
		sphere(g,"SetoEstatua",Vector3(59.2+i*0.8,0.63,-57.7),Vector3(1.0,0.8,0.9),grass)
	# Banderas y mobiliario del jardín de acceso.
	for i in range(3):
		var x:float=-62+i*3.4
		cylinder(g,"Mastil",Vector3(x,4.2,-42),0.065,11.0,silver)
		cylinder(g,"PieMastil",Vector3(x,-1.1,-42),0.32,0.5,stone)
		if i==1:
			box(g,"BanderaBlanca",Vector3(x+0.85,8.2,-42),Vector3(1.6,0.6,0.025),white)
			box(g,"BanderaRoja",Vector3(x+0.85,7.6,-42),Vector3(1.6,0.6,0.025),mat(Color("c73838")))
			box(g,"CantonAzul",Vector3(x+0.34,8.2,-41.98),Vector3(0.6,0.6,0.025),mat(Color("234d89")))
			text(g,"Estrella","★",Vector3(x+0.34,8.2,-41.95),40,Color.WHITE,0.009)
	for x in [33.0,45.0]:
		var table:=group(g,"MesaPicnic")
		table.position=Vector3(x,0.18,-47)
		box(table,"Tablero",Vector3(0,1.18,0),Vector3(3.5,0.16,1.6),wood)
		for side in [-1.0,1.0]:
			box(table,"Banco",Vector3(0,0.62,side*1.25),Vector3(3.6,0.13,0.52),wood)
			for xx in [-1.1,1.1]:
				var leg:=box(table,"Pata",Vector3(xx,0.55,side*0.65),Vector3(0.14,1.3,0.18),black)
				leg.rotation.x=side*0.35
		cylinder(table,"ParasolCerrado",Vector3(0,2.5,0),0.11,2.5,mat(Color("c4b598")),0.04)
	var bin:=group(g,"ReciclajeMorado")
	bin.position=Vector3(-47,0.18,-35)
	cylinder(bin,"BaseContenedor",Vector3(0,0.75,0),0.85,1.5,mat(Color("78628d")),0.70)
	sphere(bin,"Campana",Vector3(0,1.54,0),Vector3(1.4,1.2,1.4),mat(Color("78628d")))
	box(bin,"Boca",Vector3(0,1.75,0.68),Vector3(0.58,0.20,0.04),black)
	text(bin,"Etiqueta","RECICLAJE",Vector3(0,0.95,0.86),28,Color.WHITE,0.006)
	var welcome:=group(g,"BienvenidaSede")
	welcome.position=Vector3(42,1.1,-70)
	box(welcome,"PanelAmarillo",Vector3(0,1.9,0),Vector3(10,4.4,0.15),yellow)
	text(welcome,"Texto","¡BIENVENIDO\nA TU SEDE!",Vector3(0,1.9,0.09),72,Color("24282d"),0.012)
	# Pasos táctiles visibles; los pavimentos físicos existentes siguen intactos.
	for i in range(18):
		box(g,"GuiaTactil",Vector3(8,0.21,-35-i*1.8),Vector3(0.65,0.035,1.7),yellow)
func lathe_robe() -> ArrayMesh:
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[Vector2]=[Vector2(0.63,0),Vector2(0.59,0.35),Vector2(0.46,0.95),Vector2(0.34,1.5),Vector2(0.30,1.9),Vector2(0.34,2.12)]
	for r in range(rings.size()-1):
		for j in range(48):
			var points: Array[Vector3]=[]
			for pair in [Vector2i(r,j),Vector2i(r+1,j),Vector2i(r+1,j+1),Vector2i(r,j+1)]:
				var angle:float=float(pair.y)*TAU/48.0
				var radius:float=rings[pair.x].x*(1.0+0.075*cos(angle*12.0))
				points.append(Vector3(cos(angle)*radius,rings[pair.x].y,sin(angle)*radius))
			for idx in [0,1,2,0,2,3]: st.add_vertex(points[idx])
	st.generate_normals()
	st.index()
	return st.commit()

func finish_pass() -> Dictionary:
	setup()
	var csg_count:=0
	for n in root.find_children("*","CSGBox3D",true,false):
		var fi:=floor_of(n)
		if fi==0: continue
		var a:AABB=n.global_transform*AABB(-n.size*0.5,n.size)
		var heights:Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
		if a.size.y<0.8 and a.size.x*a.size.z>1 and absf(a.end.y-heights[fi])<0.6:
			n.material=floor_mat; n.set_meta("photo_floor",true); csg_count+=1
	for room in root.find_children("*","Node3D",true,false):
		if not room.has_meta("planta"): continue
		var g:=room.get_node_or_null("DetallesSalaFotos") as Node3D
		if g==null: continue
		var rect:Rect2=room.get_meta("planta")
		# Las salas del piso 4 usan origen central, distinto al origen frontal de las superiores.
		for n in g.get_children():
			if n is Node3D: n.position.z=clampf(n.position.z+rect.size.y*0.5,-rect.size.y*0.4,rect.size.y*0.4)
	for n in root.find_children("*","MeshInstance3D",true,false):
		if floor_of(n)==0: continue
		var title:=str(n.name)
		if title.begins_with("FranjaDuoc"): n.material_override=mat(Color("369241"))
		if title.begins_with("EsmeriladoJuntoPuerta") or title.begins_with("EsmeriladoEstudio"):
			n.material_override=mat(Color("bac5bf"),0.82)
	return {"csg_floors":csg_count}
func spatial_details() -> Dictionary:
	setup()
	var data:Dictionary={}
	for path in ["Piso3/LocalComidaReferencia","Piso3/LocalComidaReferencia/MostradorYProductos","Piso3/SalaDetrasLocal/Sala303","Piso3/SalaDetrasLocal/Sala303/PuertaSala","Exterior/Floor"]:
		var n:Node3D=root.get_node(path)
		data[path]={"position":str(n.global_position),"rotation":str(n.global_rotation)}
	var cs:Array=[]
	for n in root.find_children("*","CSGBox3D",true,false):
		if floor_of(n)!=0 and n.size.y<1 and n.size.x*n.size.z>10: cs.append({"path":str(root.get_path_to(n)),"position":str(n.global_position),"size":str(n.size)})
	data.csg=cs
	return data

func final_details() -> Dictionary:
	setup()
	if has_meta("final_details"): return {"status":"already_built"}
	var heights:Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
	for n in root.find_children("*","Node3D",true,false):
		if not n.has_meta("photo_hinged"): continue
		var room:Node=n.get_parent()
		for title in ["PlacaSala","NumeroSala","FranjaDuoc"]:
			var old:Node3D=room.get_node_or_null(title)
			if old!=null: old.visible=false
	# Orientación común sobre el acceso a la escalera, con temática de cada piso.
	for fi in range(2,9):
		var floor_root:Node3D=root.get_node("Piso%d"%fi)
		var g:=group(floor_root,"SenaleticaEscaleraFotos")
		g.position=Vector3(-20,heights[fi]+4.8,-124.5)
		box(g,"PlacaSuspendida",Vector3.ZERO,Vector3(7.0,1.45,0.10),white)
		box(g,"BloqueAmarillo",Vector3(-2.8,0,0.065),Vector3(1.25,1.45,0.035),yellow)
		text(g,"Piso",str(fi),Vector3(-2.8,0,0.095),84,Color("20262a"),0.009)
		var words:String={2:"BIBLIOTECA · SALAS DE ESTUDIO",3:"INFORMÁTICA Y TELECOMUNICACIONES",4:"ENFERMERÍA · ODONTOLOGÍA / DOCENTES",5:"FORMACIÓN GENERAL · TERRAZA",6:"INGLÉS · ÉTICA",7:"COMUNICACIÓN · MATEMÁTICAS",8:"DIRECTOR · FORMACIÓN GENERAL"}[fi]
		text(g,"Direccion",words+"\nSALAS  →     ASCENSORES  ←",Vector3(0.6,0,0.072),32,Color("252b2e"),0.005)
		for x in [-2.5,2.5]:
			box(g,"Tensor",Vector3(x,1.65,0),Vector3(0.035,2.0,0.035),silver)
		var safety:=group(floor_root,"SeguridadEscaleraFotos")
		safety.position=Vector3(-27,heights[fi],-124.5)
		box(safety,"GabineteDEA",Vector3(0,1.9,0),Vector3(0.70,0.85,0.20),mat(Color("39885c")))
		text(safety,"DEA","DEA\n♥",Vector3(0,1.9,0.12),36,Color.WHITE,0.006)
		box(safety,"GabineteIncendio",Vector3(1.05,1.4,0),Vector3(0.65,0.90,0.22),mat(Color("a9332f")))
		for i in range(2):
			cylinder(safety,"PapeleraReciclaje",Vector3(2.5+i*0.9,0.65,0),0.36,1.3,silver)
			cylinder(safety,"TapaReciclaje",Vector3(2.5+i*0.9,1.32,0),0.38,0.12,mat(Color("3c8e59") if i==0 else Color("c7a944")))
	# El terreno importado de la entrada está más alto que el antiguo césped decorativo.
	var garden:Node3D=root.get_node("Exterior/JardinYEntradaFotos")
	var ground_y:float=0.18
	garden.get_node("EstatuaJardin").position.y=ground_y
	garden.get_node("EstatuaJardin").position.z=-60
	var stone:=mat(Color("797c7a"),0.82)
	for n in garden.get_node("EstatuaJardin").find_children("*","MeshInstance3D",true,false): n.material_override=stone
	for n in garden.get_children():
		var title:=str(n.name)
		if title.begins_with("SetoEstatua"): n.position.y=ground_y+0.45; n.position.z-=7
		elif title=="ParterreEstatua": n.position.y=ground_y+0.005; n.position.z-=7
		elif title.begins_with("MesaPicnic") or title=="ReciclajeMorado": n.position.y=ground_y
		elif title.begins_with("PieMastil"): n.position.y=ground_y+0.15
		elif title.begins_with("GuiaTactil"): n.position.y=ground_y+0.03
	var paving:=mat(Color("777a77"),0.92)
	for i in range(5):
		box(garden,"CaminoJardin",Vector3(28+i*8.0,ground_y+0.025,-59),Vector3(7.85,0.03,1.35),paving)
	# Pavimento modular gris, no el mármol de los pisos interiores.
	var entry_mesh:MeshInstance3D=root.get_node_or_null("Exterior/Floor/MeshInstance3D")
	if entry_mesh!=null:
		var m:=ShaderMaterial.new()
		m.shader=load("res://materials/entrance/pavimento_exterior_fotos.gdshader")
		entry_mesh.material_override=m
	var cafe:Node3D=root.get_node("Piso3/LocalComidaReferencia")
	var label:Label3D=cafe.find_child("RotuloLocal",true,false)
	if label!=null: label.font_size=104; label.pixel_size=0.009
	# Cabecera visible del refrigerador existente.
	var header:Node3D=cafe.get_node("DetallesParadisoFotos/CabeceraBebidas")
	header.position.z=-35.95
	set_meta("final_details",true)
	return {"signs":7,"safety_points":7}
func compare_editor() -> Dictionary:
	root=get_tree().edited_scene_root
	var before:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://reports/arquitectura_antes.json"))
	var missing:Array=[]
	var changed:Array=[]
	for path in before.nodes:
		if not root.has_node(path): missing.append(path)
	for path in before.collisions:
		var n:CollisionShape3D=root.get_node_or_null(path) as CollisionShape3D
		if n==null: continue
		if str(n.global_transform)!=before.collisions[path].transform or n.disabled!=before.collisions[path].disabled:
			changed.append(path)
	var data:Dictionary={"missing":missing,"changed_collisions":changed,"floors":{},"doors":0}
	for n in root.find_children("*","",true,false):
		if n.has_meta("photo_floor"):
			var fi:String=str(root.get_path_to(n)).get_slice("/",0)
			data.floors[fi]=int(data.floors.get(fi,0))+1
		if n.has_meta("photo_hinged"): data.doors+=1
	var f:=FileAccess.open("res://reports/arquitectura_editor_validacion.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(data,"  "))
	return {"missing":missing.size(),"changed_collisions":changed.size(),"floors":data.floors,"doors":data.doors}

func optimize_new_details() -> Dictionary:
	setup()
	if has_meta("optimized"): return {"status":"already_optimized"}
	var heights:Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
	for n in get_children():
		if not str(n.name).begins_with("BordePelda"): continue
		var fi:=2
		for i in range(2,9):
			if n.global_position.y>=heights[i]-0.1: fi=i
		n.reparent(root.get_node("Piso%d"%fi),true)
		n.owner=root
	var merged:=0
	for title in ["PuertaMaderaReferencia","FrenteSalaReferencia","DetallesSalaFotos","SeguridadEscaleraFotos","JardinYEntradaFotos","EquipamientoCafeFotos"]:
		for g in root.find_children(title,"Node3D",true,false):
			merged+=merge_visuals(g)
	set_meta("optimized",true)
	return {"removed_draw_nodes":merged,"stair_details_follow_floor_visibility":true}
func merge_visuals(g: Node3D) -> int:
	var batches:Dictionary={}
	for n in g.find_children("*","MeshInstance3D",true,false):
		if n.mesh==null or n.material_override==null: continue
		var key:int=n.material_override.get_instance_id()
		if not batches.has(key): batches[key]=[]
		batches[key].append(n)
	var removed:=0
	for key in batches:
		var nodes:Array=batches[key]
		if nodes.size()<2: continue
		var st:=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for n in nodes: st.append_from(n.mesh,0,g.global_transform.affine_inverse()*n.global_transform)
		var mesh: ArrayMesh=st.commit()
		var merged:=MeshInstance3D.new()
		merged.name="DetalleCombinado"; merged.mesh=mesh; merged.material_override=nodes[0].material_override
		merged.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		owned(merged,g)
		for n in nodes: n.free()
		removed+=nodes.size()-1
	return removed

func remove_panel_flicker() -> Dictionary:
	setup()
	var count:=0
	for n in root.find_children("RevestimientoBeige*","MeshInstance3D",true,false):
		if floor_of(n)==0 or n.has_meta("offset_photo"): continue
		n.position.z+=0.06
		n.set_meta("offset_photo",true); count+=1
	return {"panels_offset":count}

func fix_garden_and_visibility() -> Dictionary:
	setup()
	var old:Node=root.get_node("Exterior/JardinYEntradaFotos")
	old.free()
	build_entry()
	var garden:Node3D=root.get_node("Exterior/JardinYEntradaFotos")
	var paving:=mat(Color("777a77"),0.92)
	for i in range(5):
		box(garden,"CaminoJardin",Vector3(28+i*8.0,0.205,-59),Vector3(7.85,0.03,1.35),paving)
	merge_visuals(garden)
	var count:=0
	var heights:Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
	for n in get_children():
		if not n is Node3D: continue
		var fi:=2
		for i in range(2,9):
			if n.global_position.y>=heights[i]-0.1: fi=i
		n.reparent(root.get_node("Piso%d"%fi),true); n.owner=root; count+=1
	return {"remaining_stair_details_moved":count,"garden_rebuilt":true}

func classroom_computers() -> Dictionary:
	setup()
	var count:=0
	var room:Node3D=root.get_node("Piso3/SalaDetrasLocal/Sala303")
	if room.has_node("LaboratorioInformaticaFotos"): return {"status":"already_built"}
	var g:=group(room,"LaboratorioInformaticaFotos")
	var screen:=mat(Color("202b32"),0.42)
	for n in room.find_children("MesaAlumno*","MeshInstance3D",true,false):
		if count>=32: break
		var a:AABB=room.global_transform.affine_inverse()*n.global_transform*n.get_aabb()
		var center:=a.get_center()
		var top:float=a.end.y
		box(g,"Monitor",Vector3(center.x,top+0.30,center.z-0.13),Vector3(0.57,0.38,0.055),black)
		box(g,"Pantalla",Vector3(center.x,top+0.30,center.z-0.097),Vector3(0.52,0.32,0.008),screen)
		box(g,"SoporteMonitor",Vector3(center.x,top+0.09,center.z-0.13),Vector3(0.07,0.18,0.07),black)
		box(g,"PieMonitor",Vector3(center.x,top+0.025,center.z-0.12),Vector3(0.28,0.035,0.16),black)
		box(g,"Teclado",Vector3(center.x-0.03,top+0.025,center.z+0.16),Vector3(0.38,0.035,0.13),black)
		box(g,"Mouse",Vector3(center.x+0.29,top+0.026,center.z+0.16),Vector3(0.06,0.035,0.10),black)
		count+=1
	merge_visuals(g)
	return {"computer_stations":count}

func orient_stair_signs() -> Dictionary:
	setup()
	for fi in range(2,9):
		var g:Node3D=root.get_node("Piso%d/SenaleticaEscaleraFotos"%fi)
		g.rotation.y=-PI*0.5
		g.position.x=-24
		g.position.z=-127.8
		var safety:Node3D=root.get_node("Piso%d/SeguridadEscaleraFotos"%fi)
		safety.position.z=-122.8
		safety.rotation.y=-PI*0.5
	return {"oriented_signs":7}

func final_geometry_fixes() -> Dictionary:
	setup()
	var restored:=0
	for n in root.find_children("RevestimientoBeige*","MeshInstance3D",true,false):
		if not n.has_meta("offset_photo") or n.has_meta("collision_restored"): continue
		for c in n.get_children():
			if c is CollisionObject3D: c.position.z-=0.06; restored+=1
		n.set_meta("collision_restored",true)
	var statue:Node3D=root.get_node("Exterior/JardinYEntradaFotos/EstatuaJardin")
	if statue.get_node_or_null("TunicaExteriorFinal")==null:
		var robe:=MeshInstance3D.new()
		robe.name="TunicaExteriorFinal"; robe.mesh=lathe_robe()
		var stone:=mat(Color("797c7a"),0.90)
		stone.cull_mode=BaseMaterial3D.CULL_DISABLED
		robe.material_override=stone; owned(robe,statue); robe.position.y=1.70
	return {"wall_collisions_restored":restored,"robe_indexed":true}

func entrance_column_details() -> Dictionary:
	setup()
	var parent:Node3D=root.get_node("Exterior/JardinYEntradaFotos")
	if parent.has_node("PendonSanJose"): return {"status":"already_built"}
	var g:=group(parent,"PendonSanJose")
	g.position=Vector3(16,5.9,-76.17)
	box(g,"PendonBlanco",Vector3.ZERO,Vector3(1.15,5.6,0.06),white)
	text(g,"Sede","DuocUC\nSEDE SAN JOAQUÍN",Vector3(0,2.18,0.05),30,Color("20344a"),0.0044)
	text(g,"Patrono","San José\nPatrono de Duoc UC",Vector3(0,0.95,0.05),28,Color("39434a"),0.004)
	box(g,"RelieveFondo",Vector3(0,-1.05,0.06),Vector3(0.98,2.16,0.06),black)
	var stone:=mat(Color("979b97"))
	sphere(g,"FiguraPatrono",Vector3(-0.12,-1.05,0.15),Vector3(0.49,1.35,0.12),stone)
	sphere(g,"CabezaPatrono",Vector3(-0.12,-0.22,0.15),Vector3(0.30,0.38,0.14),stone)
	sphere(g,"Nino",Vector3(0.16,-0.83,0.21),Vector3(0.25,0.62,0.14),stone)
	sphere(g,"CabezaNino",Vector3(0.16,-0.43,0.22),Vector3(0.20,0.23,0.14),stone)
	merge_visuals(g)
	return {"entrance_banner":true,"relief":"representación simplificada"}

func ceiling_and_stair_materials() -> Dictionary:
	setup()
	var rooms_adjusted:=0
	var concrete:=mat(Color("777b79"),0.93)
	for g in root.find_children("DetallesSalaFotos","Node3D",true,false):
		if g.has_meta("height_fixed"): continue
		var room:Node3D=g.get_parent()
		for ceiling in room.find_children("CieloSala*","MeshInstance3D",true,false):
			var a:AABB=room.global_transform.affine_inverse()*ceiling.global_transform*ceiling.get_aabb()
			g.position.y=a.position.y-0.13-9.7
			ceiling.material_override=concrete
			rooms_adjusted+=1
			break
		g.set_meta("height_fixed",true)
	var panels:=0
	for g in root.find_children("AcabadosEscaleraCentral","Node3D",true,false):
		if floor_of(g)==0: continue
		for n in g.find_children("*","MeshInstance3D",true,false):
			n.material_override=concrete; panels+=1
	return {"ceilings_adjusted":rooms_adjusted,"stair_side_panels":panels}

func finish_front_paving() -> Dictionary:
	setup()
	var m:=ShaderMaterial.new()
	m.shader=load("res://materials/entrance/pavimento_exterior_fotos.gdshader")
	var plaza:Node3D=root.get_node("Exterior/EntradaReferenciaDuoc/ExplanadaFrontalReferenciaAerea")
	var count:=0
	for n in plaza.find_children("*","MeshInstance3D",true,false):
		var title:=str(n.name)
		if title.begins_with("Sendero") or title=="VeredaFrontal" or title=="AndenFachada" or title=="PlazaCentral":
			n.material_override=m; count+=1
	return {"front_paving_pieces":count}
