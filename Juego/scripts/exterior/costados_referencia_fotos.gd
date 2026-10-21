@tool
class_name CostadosReferenciaFotos
extends Node3D
# Manual editor builder. Static geometry is saved; no runtime reconstruction.
var materials := {}
func material(color: Color, roughness: float = 0.85, metal: float = 0.0) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = roughness; m.metallic = metal
	return m
func box(parent: Node3D, title: String, center: Vector3, size_value: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh; node.material_override = mat; node.position = center
	parent.add_child(node); node.owner = get_tree().edited_scene_root
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node
func group(parent: Node, title: String) -> Node3D:
	var node := Node3D.new()
	node.name = title; parent.add_child(node); node.owner = get_tree().edited_scene_root
	return node
func wall_census() -> Array:
	var result := []
	for n in get_tree().edited_scene_root.find_children("*","MeshInstance3D",true,false):
		if n.mesh == null or not str(n.get_path()).contains("/Estructura/"): continue
		var aabb: AABB = n.global_transform*n.get_aabb()
		if aabb.size.y < 8 or aabb.size.z < 12: continue
		if absf(aabb.get_center().x) < 80: continue
		result.append({"path":str(n.get_path()),"center":str(aabb.get_center()),"min":str(aabb.position),"max":str(aabb.end)})
	return result
func build() -> Dictionary:
	if get_node_or_null("CostadoOeste") != null: return {"status":"already_built"}
	var concrete := ShaderMaterial.new()
	concrete.shader = load("res://materials/entrance/hormigon_costados.gdshader")
	var metal := material(Color("252a2a"),0.65,0.35)
	var glass := material(Color("315b61"),0.22,0.55)
	var glass_alt := material(Color("426b70"),0.28,0.4)
	var recess := material(Color("172d31"),0.45,0.2)
	var trim := material(Color("636866"),0.83)
	var top := 95.92
	for side in [-1.0,1.0]:
		var root := group(self,"CostadoOeste" if side < 0 else "CostadoEste")
		root.set_meta("reference","WhatsApp 2026-10-19 08.46.14 — ambos costados")
		var x: float = side*85.8
		# Two concrete masses and a recessed curtain-wall strip.
		box(root,"HormigonVolumenFrontal",Vector3(x,(47.95-1.3)*0.5,-93.4),Vector3(0.16,47.95+1.3,34.4),concrete)
		box(root,"HormigonVolumenPosterior",Vector3(x-side*0.08,(top-1.3)*0.5,-142.6),Vector3(0.16,top+1.3,43.2),concrete)
		box(root,"FondoFranjaAcristalada",Vector3(x-side*0.13,(47.95-1.3)*0.5,-115.8),Vector3(0.08,47.95+1.3,10.4),recess)
		for row in range(12):
			for col in range(3):
				box(root,"Vidrio_%02d_%d" % [row,col],Vector3(x+side*0.01,0.7+row*3.93,-112.4-col*3.45),Vector3(0.06,3.84,3.34),glass if (row+col)%4 else glass_alt)
		for z in [-110.65,-114.1,-117.55,-121.0]:
			box(root,"MontanteVidrio",Vector3(x+side*0.10,47.95*0.5,z),Vector3(0.13,47.95,0.13),metal)
		for i in range(13):
			box(root,"TravesanoVidrio",Vector3(x+side*0.11,i*3.93,-115.8),Vector3(0.13,0.10,10.5),metal)
		# Narrow offset slit windows: no repeated full-width bands.
		var windows := [[-86,7,5.4,1.7],[-102,17,6.3,1.5],[-91,28,4.5,1.4],[-104,38,6,1.5],[-86,48,5.6,1.6],[-98,59,5.8,1.4],[-88,70,4.9,1.5],[-102,81,5.9,1.5],[-91,90,4.7,1.4],
			[-131,10,6,1.6],[-153,23,5.2,1.5],[-136,35,5.7,1.4],[-155,46,6,1.5],[-133,57,5.3,1.6],[-150,70,5.8,1.4],[-139,82,5.5,1.5],[-155,91,4.8,1.3]]
		for i in windows.size():
			var w: Array = windows[i]
			var z: float = w[0]+(1.5 if side > 0 and i%2 == 0 else 0.0)
			var y: float = w[1]+(1.0 if side > 0 and i%3 == 0 else 0.0)
			if z > -121 and y > 46: continue
			box(root,"HuecoVentana_%02d"%i,Vector3(x+side*0.13,y,z),Vector3(0.10,w[3]+0.32,w[2]+0.40),metal)
			box(root,"CristalVentana_%02d"%i,Vector3(x+side*0.20,y,z),Vector3(0.035,w[3],w[2]),glass if i%4 else recess)
			box(root,"Vierteaguas_%02d"%i,Vector3(x+side*0.27,y-w[3]*0.5-0.10,z),Vector3(0.35,0.12,w[2]+0.50),trim)
		# Subtle vertical construction joints, plinth and rooftop railing.
		for z in [-81,-107,-128,-158]:
			var height: float = 47.95 if z > -121 else top
			box(root,"JuntaVertical",Vector3(x+side*0.095,height*0.5,z),Vector3(0.018,height,0.055),trim)
		box(root,"Zocalo",Vector3(x+side*0.12,-0.45,-120.3),Vector3(0.25,1.7,88.6),metal)
		for z in range(-162,-76,5):
			var height: float = 47.95 if z > -121 else top
			box(root,"PosteAzotea",Vector3(x,height+0.65,z),Vector3(0.065,1.3,0.065),metal)
		box(root,"PasamanosAzotea",Vector3(x,top+1.3,-142.6),Vector3(0.065,0.065,43.2),metal)
		# Basal guard glazing sits above the existing ground, without colliders.
		for z in range(-160,-78,4):
			box(root,"ProteccionVidrioBase",Vector3(x+side*1.1,0.3,z),Vector3(0.045,2.4,3.87),glass_alt)
			box(root,"PosteProteccionBase",Vector3(x+side*1.1,0.3,z+1.98),Vector3(0.07,2.5,0.07),metal)
		# Ventilation louvres below the glass spine, as in the references.
		box(root,"VentilacionBase",Vector3(x+side*0.20,1.5,-115.8),Vector3(0.12,3.0,9.8),metal)
		for i in range(12):
			box(root,"LamaVentilacion",Vector3(x+side*0.30,0.2+i*0.23,-115.8),Vector3(0.14,0.09,9.5),trim)
	set_meta("scope","Revestimiento exterior según fotos; sin cambios de colisiones, salas, campañas o accesos.")
	return validate()
func validate() -> Dictionary:
	var meshes := find_children("*","MeshInstance3D",true,false)
	return {"sides":get_child_count(),"meshes":meshes.size(),"collision_nodes":find_children("*","CollisionObject3D",true,false).size(),"runtime_generation":false,"references":4}
