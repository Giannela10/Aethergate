@tool
extends "res://scripts/pisos/piso_4/piso_4_referencia.gd"
func apply() -> Dictionary:
	for c in get_children():
		remove_child(c)
		c.free()
	global_position = Vector3(0,HEIGHT,0)
	var campus := get_parent().get_parent()
	var names := ["Front_Left piso 4 sur6","Front_Left piso 4 sur7","Front_Left piso 4 sur4"]
	var xs := [-57.561,-45.271,-32.331]
	for i in range(3):
		var wall := CampusNodes.obtener(get_parent(), names[i]) as Node3D
		wall.global_position.x = xs[i]
	var rails := CampusNodes.obtener(campus, "BarandasPasillosTodosLosPisos")
	rails.glass = CampusNodes.obtener(campus, "Piso2/AcabadosZonaAscensores/BarandasAtrio/VidrioPasillo0").material_override
	rails.metal = load("res://materials/entrance/MAT_Metal_Dark.tres")
	var parent := CampusNodes.obtener(campus, "BarandasPasillosTodosLosPisos/Piso4") as Node3D
	var restored := 0
	# Recuperar los otros bordes del hueco, dejando retirado solo el lateral marcado.
	for edge in rails.make_plan(3):
		var axis: int = edge.axis
		var c: float = edge.c
		var start: float = edge.start
		var finish: float = edge.end
		if axis==0:
			if c<18.8 or c>25.8: continue
			start = maxf(start,-122)
			finish = minf(finish,-97.848)
		else:
			if c< -122.1 or c> -97.7: continue
			start = maxf(start,-18.5)
			finish = minf(finish,25.6)
		if finish-start<0.1: continue
		var pieces := ceili((finish-start)/3.6)
		var step := (finish-start)/pieces
		for i in range(pieces):
			var midpoint := start+(i+0.5)*step
			var p := Vector3(c,HEIGHT+0.8,midpoint) if axis==0 else Vector3(midpoint,HEIGHT+0.8,c)
			var size := Vector3(0.06,1.6,step) if axis==0 else Vector3(step,1.6,0.06)
			rails.box(parent,"CristalRestaurado"+str(restored),p,size,rails.glass,true)
			p.y=HEIGHT+1.64
			size.y=0.08
			rails.box(parent,"PasamanosRestaurado"+str(restored),p,size,rails.metal,false)
			var post := Vector3(c,HEIGHT+0.82,start+i*step) if axis==0 else Vector3(start+i*step,HEIGHT+0.82,c)
			rails.box(parent,"PosteRestaurado"+str(restored),post,Vector3(0.07,1.68,0.07),rails.metal,false)
			restored += 1
		var end_post := Vector3(c,HEIGHT+0.82,finish) if axis==0 else Vector3(finish,HEIGHT+0.82,c)
		rails.box(parent,"PosteFinalRestaurado"+str(restored),end_post,Vector3(0.07,1.68,0.07),rails.metal,false)
	return {"salas_restauradas":true,"relleno_retirado":true,"paneles_repuestos":restored,"solo_lateral_marcado_retirado":true}
