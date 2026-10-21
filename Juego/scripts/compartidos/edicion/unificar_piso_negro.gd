@tool
extends Node3D
const HEIGHTS: Array[float]=[0,0,12.058386,23.967669,35.674416,47.974850,60.158504,71.942184,83.913551]
func bounds(n:Node3D) -> AABB:
	if n is MeshInstance3D: return n.global_transform*n.get_aabb()
	if n is CSGBox3D: return n.global_transform*AABB(-n.size*0.5,n.size)
	return AABB()
func candidates(fi:int) -> Array[Node3D]:
	var result:Array[Node3D]=[]
	var campus:Node=get_tree().edited_scene_root
	var floor_root:Node=campus.get_node("Piso%d"%fi)
	for n in floor_root.find_children("*","Node3D",true,false):
		if not(n is MeshInstance3D or n is CSGBox3D): continue
		if n is MeshInstance3D and n.mesh==null: continue
		var path:String=str(floor_root.get_path_to(n)).to_lower()
		if path.contains("nariz") or path.contains("tactil") or path.contains("borde") or path.contains("guia"): continue
		if path.contains("escalera") and not(path.contains("descanso") or path.contains("desembarco") or path.contains("losa")): continue
		if fi==2 and (path.contains("biblioteca") or path.contains("auditorio") or path.contains("impresiones")): continue
		var furniture:=false
		for word in ["silla","butaca","cojin","asiento","mesa","meson","mostrador","repisa","estante","mueble","congelador","refrigerador","frio","vitrina","pata","banco","sillon","computador"]:
			if path.contains(word): furniture=true; break
		if furniture: continue
		var a:AABB=bounds(n)
		if a.size.y>2.2 or a.size.x*a.size.z<1.0: continue
		if minf(a.size.x,a.size.z)<0.35: continue
		if absf(a.end.y-HEIGHTS[fi])>0.80: continue
		if a.size.y>minf(a.size.x,a.size.z)*0.45: continue
		result.append(n)
	return result
func audit() -> Dictionary:
	var report:Dictionary={}
	for fi in range(2,9):
		var rows:Array=[]
		for n in candidates(fi):
			var m:Material=n.material_override if n is MeshInstance3D else n.material
			var shader:String=m.shader.resource_path if m is ShaderMaterial and m.shader!=null else ""
			if shader.ends_with("piso_fotos.gdshader"): continue
			rows.append({"path":str(get_tree().edited_scene_root.get_path_to(n)),"material":str(m),"shader":shader,"bounds":str(bounds(n))})
		report[str(fi)]={"candidates":candidates(fi).size(),"different":rows}
	return report
func apply_reference() -> Dictionary:
	var campus:Node=get_tree().edited_scene_root
	var reference:MeshInstance3D=campus.get_node("Piso3/AcabadosPasillos/PasilloEste")
	var surface:Material=reference.material_override
	if surface==null: return {"error":"reference_material_missing"}
	var report:Dictionary={"reference":"Piso3/AcabadosPasillos/PasilloEste","floors":{},"collisions_modified":0}
	for fi in range(2,9):
		var count:=0
		var added:=0
		for n in candidates(fi):
			var prior:Material=n.material_override if n is MeshInstance3D else n.material
			if prior!=surface: added+=1
			if n is MeshInstance3D:
				n.material_override=surface
				n.material_overlay=null
			else: n.material=surface
			n.set_meta("black_floor_reference",true)
			count+=1
		report.floors[str(fi)]={"surfaces":count,"assigned_shared_reference":added}
	var f:=FileAccess.open("res://reports/pisos_negros_unificados.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	return report
