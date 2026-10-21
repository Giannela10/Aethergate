const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');const i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\t# Apply the same classroom expansion on the opposite side, floors 3 and 4.
\tfor level in [3,4]:
\t\tvar west_wall := campus.get_node("Piso %d/Front_Left piso %d sur4" % [level,level]) as MeshInstance3D
\t\tvar wb: AABB = west_wall.global_transform*west_wall.get_aabb()
\t\twest_wall.global_position.x += -18.33-wb.end.x
\t\tfor suffix in ["d","d2"]:
\t\t\tvar end_wall := campus.get_node("Piso %d/Delantera_piso %d%s" % [level,level,suffix]) as MeshInstance3D
\t\t\tvar eb: AABB = end_wall.global_transform*end_wall.get_aabb()
\t\t\tif eb.end.x < -18.33:
\t\t\t\tvar extension := -18.33-eb.end.x
\t\t\t\tvar extended_mesh := end_wall.mesh.duplicate() as BoxMesh
\t\t\t\textended_mesh.size.x += extension/absf(end_wall.global_basis.x.x)
\t\t\t\tend_wall.mesh = extended_mesh
\t\t\t\tend_wall.global_position.x += extension*0.5
\t\t\t\tfor col in end_wall.find_children("*","CollisionShape3D",true,false):
\t\t\t\t\tvar extended_shape := col.shape.duplicate() as BoxShape3D
\t\t\t\t\textended_shape.size.x = extended_mesh.size.x
\t\t\t\t\tcol.shape = extended_shape
\t\tvar west_patch := campus.get_node("ContinuidadPisos/Piso%d_Cierre%d" % [level,1 if level==3 else 2]) as MeshInstance3D
\t\twest_patch.visible = false
\t\tfor col in west_patch.find_children("*","CollisionShape3D",true,false): col.disabled = true
\t\tvar west_floor := campus.get_node("Piso %d/Building_Floor Piso %db" % [level,level]) as MeshInstance3D
\t\tvar fb: AABB = west_floor.global_transform*west_floor.get_aabb()
\t\tmats["piso_sala_oeste"] = west_floor.get_active_material(0)
\t\tbox(hall,"AmpliacionSalaOestePiso%d" % level,Vector3((fb.end.x-18.5)*0.5,fb.get_center().y,fb.get_center().z),Vector3(-18.5-fb.end.x,fb.size.y,fb.size.z),"piso_sala_oeste",true)
\t\tfor rail in campus.get_node("BarandasPasillosTodosLosPisos/Piso%d" % level).find_children("*","MeshInstance3D",true,false):
\t\t\tvar rb: AABB = rail.global_transform*rail.get_aabb()
\t\t\tif rb.position.x > -18.75 and rb.end.x < -18.35 and rb.position.z>=-122.1 and rb.end.z<=-97.7:
\t\t\t\trail.visible = false
\t\t\t\tfor col in rail.find_children("*","CollisionShape3D",true,false): col.disabled = true
`+s.slice(i);fs.writeFileSync(p,s);
