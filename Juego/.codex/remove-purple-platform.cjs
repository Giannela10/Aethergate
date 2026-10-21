const fs=require('fs');let p='auditorio_piso_2e.gd',s=fs.readFileSync(p,'utf8');const a=s.indexOf('\tvar patch :=',s.indexOf('func ampliar_recinto')),b=s.indexOf('\tvar hall :=',a);s=s.slice(0,a)+`\tvar patch := campus.get_node("ContinuidadPisos/Piso2_Cierre3") as MeshInstance3D
\tpatch.visible = false
\tfor col in patch.find_children("*","CollisionShape3D",true,false): col.disabled = true
`+s.slice(b);const i=s.indexOf('\thall.set_meta("superficie_m2"');s=s.slice(0,i)+`\t# Remove the obsolete front platform railings together with the platform.
\tfor rail in rails.get_children():
\t\tvar obsolete := str(rail.name) in ["PosteFinal15","PosteFinal21","PosteFinal24"]
\t\tfor number in [13,14,18,19,20,21,22,23]:
\t\t\tif str(rail.name) in ["VidrioPasillo%03d" % number,"Pasamanos%03d" % number,"Poste%03d" % number]: obsolete = true
\t\tif obsolete:
\t\t\trail.visible = false
\t\t\tfor col in rail.find_children("*","CollisionShape3D",true,false): col.disabled = true
`+s.slice(i);fs.writeFileSync(p,s);
