const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');const i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\t# Remove the upper front projections over the same atrium opening.
\tfor level in [3,4]:
\t\tvar slab := campus.get_node("Piso %d/Building_Floor Piso %d" % [level,level]) as MeshInstance3D
\t\tvar bounds: AABB = slab.global_transform*slab.get_aabb()
\t\tslab.visible = false
\t\tfor col in slab.find_children("*","CollisionShape3D",true,false): col.disabled = true
\t\tmats["losa_superior"] = slab.get_active_material(0)
\t\tvar portions := [Rect2(bounds.position.x,bounds.position.z,25.6-bounds.position.x,bounds.size.z),Rect2(68.05,bounds.position.z,bounds.end.x-68.05,bounds.size.z),Rect2(25.6,bounds.position.z,68.05-25.6,-86.75-bounds.position.z)]
\t\tfor part in range(portions.size()):
\t\t\tvar r: Rect2 = portions[part]
\t\t\tbox(hall,"LosaRecortadaPiso%dParte%d" % [level,part],Vector3(r.get_center().x,bounds.get_center().y,r.get_center().y),Vector3(r.size.x,bounds.size.y,r.size.y),"losa_superior",true)
`+s.slice(i);fs.writeFileSync(p,s);
