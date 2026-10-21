const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');const i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\t# Incorporate the marked third-floor lateral corridor into the classroom.
\tvar side_wall := campus.get_node("Piso 3/Front_Left piso 3 sur8") as MeshInstance3D
\tvar side_bounds: AABB = side_wall.global_transform*side_wall.get_aabb()
\tside_wall.global_position.x += 25.43-side_bounds.position.x
\tvar front_wall := campus.get_node("Piso 3/Delantera_piso 3c") as MeshInstance3D
\tvar front_bounds: AABB = front_wall.global_transform*front_wall.get_aabb()
\tif front_bounds.position.x>25.43:
\t\tvar extension := front_bounds.position.x-25.43
\t\tvar wall_mesh := front_wall.mesh.duplicate() as BoxMesh
\t\twall_mesh.size.x += extension/absf(front_wall.global_basis.x.x)
\t\tfront_wall.mesh = wall_mesh
\t\tfront_wall.global_position.x -= extension*0.5
\t\tfor col in front_wall.find_children("*","CollisionShape3D",true,false):
\t\t\tvar wall_shape := col.shape.duplicate() as BoxShape3D
\t\t\twall_shape.size.x = wall_mesh.size.x
\t\t\tcol.shape = wall_shape
\tvar lateral_patch := campus.get_node("ContinuidadPisos/Piso3_Cierre4") as MeshInstance3D
\tlateral_patch.visible = false
\tfor col in lateral_patch.find_children("*","CollisionShape3D",true,false): col.disabled = true
\tvar room_floor := campus.get_node("Piso 3/Building_Floor Piso 3c") as MeshInstance3D
\tmats["piso_sala_3"] = room_floor.get_active_material(0)
\tbox(hall,"AmpliacionPisoSala3",Vector3((25.6+30.893495)*0.5,23.717668533,(-122.0441-97.7283)*0.5),Vector3(30.893495-25.6,0.5,24.3158),"piso_sala_3",true)
\tvar third_rails := campus.get_node("BarandasPasillosTodosLosPisos/Piso3")
\tfor rail in third_rails.find_children("*","MeshInstance3D",true,false):
\t\tvar rb: AABB = rail.global_transform*rail.get_aabb()
\t\tif rb.position.x>25.4 and rb.end.x<25.75 and rb.position.z>=-122.1 and rb.end.z<=-97.7:
\t\t\trail.visible = false
\t\t\tfor col in rail.find_children("*","CollisionShape3D",true,false): col.disabled = true
`+s.slice(i);fs.writeFileSync(p,s);
