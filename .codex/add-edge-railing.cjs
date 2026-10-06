const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');const i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\t# Glass railing follows the new front edge from the corridor to the auditorium.
\tmats["vidrio_borde"] = rails.get_node("VidrioPasillo013").get_active_material(0)
\tmats["metal_borde"] = rails.get_node("Pasamanos013").get_active_material(0)
\tvar railing := Node3D.new()
\trailing.name = "BarandaBordePasilloRecortado"
\thall.add_child(railing)
\trailing.owner = owner
\tvar edge_left := 25.6
\tvar edge_right := 42.7
\tvar sections := 6
\tvar section_width := (edge_right-edge_left)/sections
\tfor section in range(sections):
\t\tvar x := edge_left+(section+0.5)*section_width
\t\tbox(railing,"Vidrio"+str(section),Vector3(x,entry_y+0.8,-86.5),Vector3(section_width,1.6,0.06),"vidrio_borde",true)
\t\tbox(railing,"Pasamanos"+str(section),Vector3(x,entry_y+1.64,-86.5),Vector3(section_width,0.08,0.06),"metal_borde")
\tfor post in range(sections+1):
\t\tbox(railing,"Poste"+str(post),Vector3(edge_left+post*section_width,entry_y+0.82,-86.5),Vector3(0.07,1.68,0.07),"metal_borde")
`+s.slice(i);fs.writeFileSync(p,s);
