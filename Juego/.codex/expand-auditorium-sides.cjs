const fs=require('fs');const p='auditorio_piso_2e.gd';let s=fs.readFileSync(p,'utf8');s=s.replace('\tbox(hall,"CierreEscenario",Vector3(left,top*0.5,(back+front)*0.5),Vector3(0.16,top,front-back),"madera",true)',`\t# The extension follows the stair landing, keeping its circulation intact.
\tvar wing_left := 32.35
\tvar wing_front := -97.55
\tvar wing_width := left-wing_left
\tvar wing_depth := wing_front-back
\tbox(hall,"BaseAmpliacionLateral",Vector3((wing_left+left)*0.5,base*0.5,(back+wing_front)*0.5),Vector3(wing_width,base,wing_depth),"piso",true)
\tbox(hall,"LateralCompleto",Vector3(wing_left,top*0.5,(back+wing_front)*0.5),Vector3(0.16,top,wing_depth),"madera",true)
\tbox(hall,"FondoAmpliacion",Vector3((wing_left+left)*0.5,top*0.5,back),Vector3(wing_width,top,0.16),"madera",true)
\tbox(hall,"CierreJuntoDescanso",Vector3((wing_left+left)*0.5,top*0.5,wing_front),Vector3(wing_width,top,0.16),"madera",true)
\tbox(hall,"CierreEscenario",Vector3(left,top*0.5,(wing_front+front)*0.5),Vector3(0.16,top,front-wing_front),"madera",true)
\tbox(hall,"TechoAmpliacion",Vector3((wing_left+left)*0.5,top+0.05,(back+wing_front)*0.5),Vector3(wing_width,0.18,wing_depth),"metal",true)
\tbox(hall,"TarimaLateralAmpliada",Vector3((wing_left+left)*0.5,8.97735,(back+wing_front)*0.5),Vector3(wing_width,1.4453,wing_depth-0.2),"piso",true)
\t# Close the empty side below the landing; nothing extends onto the steps.
\tbox(hall,"CierreInferiorDescanso",Vector3((32.3+left)*0.5,entry_y*0.5,(-97.31-86.7)*0.5),Vector3(left-32.3,entry_y,10.61),"madera",true)`);
s=s.replace('Vector3(43.05,13.8,-104)','Vector3(32.55,13.8,-109.7)').replace('Vector3(45,10.4,-112)','Vector3(36.5,10.4,-112)');
s=s.replace('\t\t\tvar inside := bounds.intersects(room_volume)','\t\t\tvar wing_volume := AABB(Vector3(32.25,11.6,back-0.1),Vector3(left-32.25,4.5,wing_front-back+0.2))\n\t\t\tvar inside := bounds.intersects(room_volume) or bounds.intersects(wing_volume)');
s=s.replace('\thall.set_meta("entradas_z"',`\tbox(hall,"LuzTarimaSoporte",Vector3(36,22,-110),Vector3(0.1,0.1,0.1),"metal")
\tvar stage_light := OmniLight3D.new()
\tstage_light.name = "LuzAmpliacionTarima"
\tstage_light.position = Vector3(37,19,-110)
\tstage_light.omni_range = 18
\tstage_light.light_energy = 1.2
\thall.add_child(stage_light)
\tstage_light.owner = owner
\thall.set_meta("superficie_m2",(right-left)*(front-back)+wing_width*wing_depth)
\thall.set_meta("entradas_z"`);
s=s.replace('"ancho":right-left,"profundidad":front-back','"ancho_maximo":right-wing_left,"superficie_m2":(right-left)*(front-back)+wing_width*wing_depth,"profundidad":front-back');
fs.writeFileSync(p,s);
