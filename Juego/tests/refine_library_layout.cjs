const fs=require('fs');
const file='Main.tscn',blocks=fs.readFileSync(file,'utf8').split(/(?=^\[)/m);
const root='Piso2/Biblioteca',photo=root+'/MobiliarioReferenciaFoto';
const nodes=blocks.map((b,i)=>({b,i,name:b.match(/^\[node name="([^"]+)"/)?.[1],parent:b.match(/^\[node .*parent="([^"]+)"/)?.[1]})).filter(n=>n.name);
const byPath=new Map(nodes.map(n=>[n.parent+'/'+n.name,n]));
function t(n) {return blocks[n.i].match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number)||[1,0,0,0,1,0,0,0,1,0,0,0];}
function move(n,value) {const line='transform = Transform3D('+value.map(v=>Number(v.toFixed(7))).join(', ')+')';blocks[n.i]=/^transform = .*$/m.test(blocks[n.i])?blocks[n.i].replace(/^transform = .*$/m,line):blocks[n.i].replace(/\n/,'\n'+line+'\n');}
// Respect the printing room occupying the north-west corner; it stays untouched.
nodes.filter(n=>n.parent===root+'/PuestosComputadores').forEach((pc,i)=>{
 if(i<9)move(pc,[0,0,1,0,1,0,-1,0,0,-82,0,-108+i*3]);
 for(const name of ['BaseMonitor','SoporteMonitor','Monitor','Pantalla','Teclado','Silla']) {
  const template=byPath.get(root+'/PuestosComputadores/Puesto01/'+name);
  const part=byPath.get(pc.parent+'/'+pc.name+'/'+name);
  if(template&&part)move(part,t(template));
 }
});
nodes.filter(n=>n.parent===root+'/Estanterias').forEach((n,i)=>move(n,[0,0,1,0,1,0,-1,0,0,-77.5+i*4,0,-107.5]));
// Keep the existing table and all four associated chairs as a single seating group.
const firstTable=byPath.get(photo+'/MesaRedonda');
const old=t(firstTable),dx=-74-old[9],dz=-99-old[11];
if(Math.abs(dx)+Math.abs(dz)>.001) {
 for(const n of nodes.filter(n=>n.parent===photo && n.b.includes('type="Node3D"'))) {
  const a=t(n);
  if(Math.hypot(a[9]-old[9],a[11]-old[11])<2.3){a[9]+=dx;a[11]+=dz;move(n,a);}
 }
}
// Move the magazine display against a solid portion between the study-room doors.
for(const n of nodes.filter(n=>n.parent===photo && !n.b.includes('type="Node3D"'))) {
 const a=t(n);
 if(Math.abs(a[9]+53.2)<.01 && Math.abs(a[11]+107.2)<.7){a[9]=-51.5;move(n,a);}
}
// The reused office-chair meshes had a manual offset in their source assembly.
// Center only the new copies, leaving all original coordination chairs unchanged.
for(let i=1;i<=2;i++) {
 const path=photo+'/MesonOvaladoAbierto/SillaPersonal'+i;
 const seat=byPath.get(path+'/Asiento'),offset=t(seat);
 for(const n of nodes.filter(n=>n.parent===path)) {
  const a=t(n);a[9]-=offset[9];a[11]-=offset[11];move(n,a);
 }
}
fs.writeFileSync(file,blocks.join(''));
console.log('LIBRARY_REFINEMENT_OK printing_room preserved, stations normalized, four parallel shelves, reading group and magazine display repositioned');
