const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');s=s.replace('var right := 68.05','var right := 71.12624').replace('Vector3(68.1,entry_y-0.07,z)','Vector3(right+0.05,entry_y-0.07,z)').replace('Vector3(68.2,15.4,z)','Vector3(right+0.15,15.4,z)').replace('Vector3(65.975,entry_y-0.1,(back+front)*0.5),Vector3(4.15','Vector3(right-2.075,entry_y-0.1,(back+front)*0.5),Vector3(4.15').replace('var run := 15.5','var run := 18.57624').replace('Vector3(56.15,','Vector3(57.68812,').replace('Vector2(63.9,68.05)','Vector2(right-4.15,right)');s=s.replace('side_wall.global_position.x += 25.43-side_bounds.position.x','side_wall.global_position.x += 32.35-side_bounds.position.x').replace('if front_bounds.position.x>25.43:','if absf(front_bounds.position.x-32.35)>0.001:').replace('var extension := front_bounds.position.x-25.43','var extension := front_bounds.position.x-32.35');let i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\tuniformizar_pasillos(hall,campus)
`+s.slice(i);s+=`
func uniformizar_pasillos(hall: Node3D,campus: Node3D) -> void:
\tvar width := 13.2072
\tvar heights: Array[float] = [0.0,12.058385849,23.967668533,35.674415588]
\tvar floor_ref := campus.get_node("Piso 3/Building_Floor Piso 3c2") as MeshInstance3D
\tmats["piso_pasillos"] = floor_ref.get_active_material(0)
\tvar standardized := Node3D.new()
\tstandardized.name = "PasillosUniformesPisos1a4"
\thall.add_child(standardized)
\tstandardized.owner = owner
\tfor level in range(4):
\t\tvar y := heights[level]
\t\tvar level_node := Node3D.new()
\t\tlevel_node.name = "Piso%d" % (level+1)
\t\tstandardized.add_child(level_node)
\t\tlevel_node.owner = owner
\t\tfor side in [-1,1]:
\t\t\tvar wall_x := -32.16 if side<0 else 32.35
\t\t\tvar edge_x := wall_x-side*width
\t\t\tvar center_x := (wall_x+edge_x)*0.5
\t\t\tvar deck := box(level_node,"PasilloOeste" if side<0 else "PasilloEste",Vector3(center_x,y-0.15,-109.925),Vector3(width,0.3,24.15),"piso_pasillos",level>0)
\t\t\tdeck.set_meta("ancho_libre",width)
\t\t\tif level==0:
\t\t\t\tdeck.position.y = -0.16
\t\t\t\tcontinue
\t\t\tvar old_rails := campus.get_node("BarandasPasillosTodosLosPisos/Piso%d" % (level+1))
\t\t\tfor rail in old_rails.find_children("*","MeshInstance3D",true,false):
\t\t\t\tvar rb: AABB = rail.global_transform*rail.get_aabb()
\t\t\t\tif rb.size.x<0.2 and rb.position.z>=-122.1 and rb.end.z<=-97.7 and ((side<0 and rb.position.x>-19.2 and rb.end.x < -18.3) or (side>0 and rb.position.x>18.8 and rb.end.x<25.8)):
\t\t\t\t\trail.visible = false
\t\t\t\t\tfor col in rail.find_children("*","CollisionShape3D",true,false): col.disabled = true
\t\t\tfor segment in range(8):
\t\t\t\tvar z := -122+(segment+0.5)*24.15/8
\t\t\t\tbox(level_node,"Cristal%d_%d" % [side,segment],Vector3(edge_x,y+0.8,z),Vector3(0.06,1.6,24.15/8),"vidrio_borde",true)
\t\t\t\tbox(level_node,"Pasamanos%d_%d" % [side,segment],Vector3(edge_x,y+1.64,z),Vector3(0.06,0.08,24.15/8),"metal_borde")
\t\t\tfor post in range(9):
\t\t\t\tbox(level_node,"Poste%d_%d" % [side,post],Vector3(edge_x,y+0.82,-122+post*24.15/8),Vector3(0.07,1.68,0.07),"metal_borde")
\tstandardized.set_meta("ancho_referencia",width)
`;fs.writeFileSync(p,s);
