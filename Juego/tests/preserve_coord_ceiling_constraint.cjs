// Keep the existing ceiling until the auditorium overlap is explicitly resolved.
const fs=require('fs'),file='Main.tscn',blocks=fs.readFileSync(file,'utf8').split(/(?=^\[)/m);
const root='Piso1/InteriorCoordinacion',meeting=root+'/SalaReuniones',top=4.94;
const resources=new Map(blocks.map((b,i)=>[b.match(/^\[sub_resource .* id="([^"]+)"/)?.[1],i]));
for(let i=0;i<blocks.length;i++){
 const b=blocks[i];if(!b.startsWith('[node '))continue;
 const parent=b.match(/parent="([^"]+)"/)?.[1],name=b.match(/name="([^"]+)"/)[1];
 if(parent===root&&name==='TechoCoordinacion')blocks[i]=b.replace(/transform = Transform3D\(([^)]+)\)/,(_,v)=>{const t=v.split(',').map(Number);t[10]=top+.05;return 'transform = Transform3D('+t.join(', ')+')';});
 if(parent!==meeting||!b.includes('type="MeshInstance3D"'))continue;
 const id=b.match(/mesh = SubResource\("([^"]+)"\)/)?.[1],ri=resources.get(id);
 if(ri===undefined)continue;
 const size=blocks[ri].match(/size = Vector3\(([^)]+)\)/)?.[1].split(',').map(Number);
 const t=b.match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number);
 if(!size||!t)continue;
 if(size[1]>10){size[1]=top-.12;t[10]=.12+size[1]/2;}
 else if(name==='VidrioSobrePuerta'){size[1]=top-3.2;t[10]=(top+3.2)/2;}
 else if(t[10]>10)t[10]=top-.05;
 blocks[i]=b.replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+t.join(', ')+')');
 blocks[ri]=blocks[ri].replace(/size = Vector3\([^)]+\)/,'size = Vector3('+size.join(', ')+')');
 const shape=resources.get(id+'_shape');
 if(shape!==undefined)blocks[shape]=blocks[shape].replace(/size = Vector3\([^)]+\)/,'size = Vector3('+size.join(', ')+')');
}
fs.writeFileSync(file,blocks.join(''));
const report='reports/coordinacion_meeting_layout.json',data=JSON.parse(fs.readFileSync(report,'utf8'));
data.ceiling_underside=top;data.requested_ceiling_underside=11.558385849;data.ceiling_adjustment_applied=false;
data.ceiling_constraint='Auditorium base occupies y=4.94..8.2547 over part of Coordination; retain original ceiling until structural overlap is resolved.';
fs.writeFileSync(report,JSON.stringify(data,null,2)+'\n');
console.log('COORD_CEILING_PRESERVED meeting walls match existing ceiling; requested height remains pending due to auditorium structure');
