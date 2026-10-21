const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');s=s.replace('patch_mesh.size.x = 11.2','patch_mesh.size.x = 6.65').replace('patch.position.x = 31.2','patch.position.x = 28.925').replace('patch_shape.size.x = 11.2','patch_shape.size.x = 6.65');const key='\tbox(hall,"TechoCompleto"';let i=s.indexOf(key,s.indexOf('func ampliar_recinto'));s=s.slice(0,i)+`\t# Finish the recessed corner with a diagonal tip, behind the stair edge.
\tvar tip := CSGPolygon3D.new()
\ttip.name = "PuntaLateralCompleta"
\ttip.polygon = PackedVector2Array([Vector2(wing_left,wing_front),Vector2(left,wing_front),Vector2(left,front)])
\ttip.depth = top
\ttip.rotation.x = PI*0.5
\ttip.position.y = top
\ttip.material = mats["madera"]
\ttip.use_collision = true
\thall.add_child(tip)
\ttip.owner = owner
`+s.slice(i);fs.writeFileSync(p,s);
