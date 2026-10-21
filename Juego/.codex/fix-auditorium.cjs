const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');let a=s.indexOf('\told_landing.visible = false',s.indexOf('func ampliar_recinto'));let b=s.indexOf('\tvar hall :=',a);s=s.slice(0,a)+`\told_landing.visible = true
\told_landing.use_collision = true
\tvar patch := campus.get_node("ContinuidadPisos/Piso2_Cierre3") as MeshInstance3D
\tvar patch_mesh := patch.mesh.duplicate() as BoxMesh
\tpatch_mesh.size.x = 11.2
\tpatch.position.x = 31.2
\tpatch.mesh = patch_mesh
\tfor col in patch.find_children("*","CollisionShape3D",true,false):
\t\tvar patch_shape := col.shape.duplicate() as BoxShape3D
\t\tpatch_shape.size.x = 11.2
\t\tcol.shape = patch_shape
`+s.slice(b);
const replacements=[['var left := 32.35','var left := 42.85'],['var front := -80.3','var front := -86.75'],['Vector3(37.7,8.32735,(back+front)*0.5),Vector3(10.5,0.1453,front-back-0.4)','Vector3(45.65,8.97735,(back+front)*0.5),Vector3(5.4,1.4453,front-back-0.4)'],['Vector3(32.6,13.8,-102)','Vector3(43.05,13.8,-104)'],['Vector3(36.5,9.1,-112)','Vector3(45,10.4,-112)'],[',-87.5,-85.6,-83.7',',-87.7'],['for row in range(12):','for row in range(9):'],['44.4+row*1.55','49.7+row*1.55'],['8.55+row*0.29','8.55+row*0.4'],['Vector2(-88.5,-82.7)','Vector2(-88.5,-87.05)'],['var run := 20.9','var run := 15.5'],['Vector3(53.45,','Vector3(56.15,'],['for x in [37.0,48.0,59.0]:','for x in [46.0,54.0,62.0]:'],['for z in [-114.0,-96.0,-85.0]:','for z in [-114.0,-104.0,-91.0]:'],['"butacas",156','"butacas",99'],['"butacas":156','"butacas":99']];for(const [x,y]of replacements)s=s.replace(x,y);
s=s.replace('\tfor x in [46.0,54.0,62.0]:',`\tfor z in [-118.5,-104.5,-90.5]:
\t\tvar stage_angle := atan(1.3/2.2)
\t\tvar access := box(hall,"AccesoTarima"+str(z),Vector3(47.3,9.05-0.06/cos(stage_angle),z),Vector3(sqrt(2.2*2.2+1.3*1.3),0.12,2.4),"piso",true)
\t\taccess.rotation.z = -stage_angle
\tfor x in [46.0,54.0,62.0]:`);
a=s.indexOf('\tvar room_volume :=',s.indexOf('func ampliar_recinto'));b=s.indexOf('\thall.set_meta',a);s=s.slice(0,a)+`\tvar previous_volume := AABB(Vector3(32.2,11.6,-122.2),Vector3(36.25,4.5,42.2))
\tvar room_volume := AABB(Vector3(left-0.1,11.6,back-0.1),Vector3(right-left+0.5,4.5,front-back+0.2))
\tfor rail in rails.find_children("*","MeshInstance3D",true,false):
\t\tvar bounds: AABB = rail.global_transform*rail.get_aabb()
\t\tif bounds.intersects(previous_volume):
\t\t\tvar inside := bounds.intersects(room_volume)
\t\t\trail.visible = not inside
\t\t\tfor col in rail.find_children("*","CollisionShape3D",true,false): col.disabled = inside
`+s.slice(b);fs.writeFileSync(p,s);let t=fs.readFileSync('.codex/check_auditorium.gd','utf8').replaceAll('Vector3(37,8.5,z)','Vector3(45,9.8,z)');fs.writeFileSync('.codex/check_auditorium.gd',t);
