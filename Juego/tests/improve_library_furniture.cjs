// Scoped scene migration: reuse furniture; complete room closures with local resources.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const file='Main.tscn', source=fs.readFileSync(file,'utf8');
if(source.includes('name="MejorasBiblioteca"')) {require('./refine_library_layout.cjs');console.log('Library improvement already applied.');process.exit(0);}
const root='Piso2/Biblioteca', photo=root+'/MobiliarioReferenciaFoto';
const blocks=source.split(/(?=^\[)/m), before=[...blocks];
const res=new Map(blocks.filter(b=>b.startsWith('[sub_resource ')).map(b=>[b.match(/id="([^"]+)"/)[1],b]));
const records=blocks.map((b,i)=>({i,b,name:b.match(/^\[node name="([^"]+)"/)?.[1],parent:b.match(/^\[node .*parent="([^"]+)"/)?.[1]})).filter(n=>n.name);
const byPath=new Map(records.map(n=>[n.parent+'/'+n.name,n]));
const additions=[],resources=[];let serial=0;
const R=id=>'SubResource("'+id+'")', E=id=>'ExtResource("'+id+'")';
const wood=R('merge_local_StandardMaterial3D_qwha1'), metal=R('merge_local_StandardMaterial3D_rngq8'), black=R('merge_local_StandardMaterial3D_owb1o'), white=R('merge_local_StandardMaterial3D_aubwi');
function transform(n) {return blocks[n.i].match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number)||[1,0,0,0,1,0,0,0,1,0,0,0];}
function set(n,key,value) {
 const pattern=new RegExp('^'+key+' = .*$', 'm');
 blocks[n.i]=pattern.test(blocks[n.i])?blocks[n.i].replace(pattern,key+' = '+value):blocks[n.i].replace(/\n/, '\n'+key+' = '+value+'\n');
}
function move(n,t) {set(n,'transform','Transform3D('+t.map(v=>Number(v.toFixed(7))).join(', ')+')');}
function hide(n) {set(n,'visible','false'); for(const child of records.filter(c=>c.parent?.startsWith(n.parent+'/'+n.name+'/') && c.b.includes('type="CollisionShape3D"'))) set(child,'disabled','true');}
function cloneResource(id,size) {
 const name='library_layout_'+(++serial);assert(res.has(id),id);
 const b=res.get(id).replace('id="'+id+'"','id="'+name+'"').replace(/size = Vector3\([^)]+\)/,'size = Vector3('+size.join(', ')+')');
 resources.push(b);return name;
}
function meshSize(n,size) {
 const id=blocks[n.i].match(/mesh = SubResource\("([^"]+)"\)/)?.[1];assert(id,n.name);
 set(n,'mesh',R(cloneResource(id,size)));
 for(const c of records.filter(c=>c.parent?.startsWith(n.parent+'/'+n.name+'/') && c.b.includes('type="CollisionShape3D"'))) {
   const shape=c.b.match(/shape = SubResource\("([^"]+)"\)/)?.[1];
   if(shape && res.get(shape)?.startsWith('[sub_resource type="BoxShape3D"')) set(c,'shape',R(cloneResource(shape,size)));
 }
}
function group(name,parent,pos=[0,0,0],angle=0) {
 const c=Math.cos(angle),s=Math.sin(angle);
 additions.push(`[node name="${name}" type="Node3D" parent="${parent}"]\ntransform = Transform3D(${c}, 0, ${s}, 0, 1, 0, ${-s}, 0, ${c}, ${pos.join(', ')})\n\n`);
 return parent+'/'+name;
}
function box(name,parent,pos,size,mat,solid=false) {
 const id='library_layout_'+(++serial);
 resources.push(`[sub_resource type="BoxMesh" id="${id}"]\nsize = Vector3(${size.join(', ')})\n\n`);
 additions.push(`[node name="${name}" type="MeshInstance3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${pos.join(', ')})\nmaterial_override = ${mat}\nmesh = ${R(id)}\n\n`);
 if(solid) {
  resources.push(`[sub_resource type="BoxShape3D" id="${id}_shape"]\nsize = Vector3(${size.join(', ')})\n\n`);
  additions.push(`[node name="Cuerpo" type="StaticBody3D" parent="${parent}/${name}"]\n\n[node name="Colision" type="CollisionShape3D" parent="${parent}/${name}/Cuerpo"]\nshape = ${R(id+'_shape')}\n\n`);
 }
}
function label(name,parent,pos,text) {
 additions.push(`[node name="${name}" type="Label3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${pos.join(', ')})\ntext = "${text}"\nfont_size = 48\npixel_size = 0.004\nmodulate = Color(0.06, 0.10, 0.19, 1)\n\n`);
}
// Preserve every original resource, including all shared architectural materials.
// Use the first room's tall glass frontage and absent false ceiling as the reference.
const ceiling=byPath.get(root+'/AcabadosReferencia/FondoCieloMadera');
const ceilingY=transform(ceiling)[10]-.03;
for(let roomIndex=1;roomIndex<=6;roomIndex++) {
 const path=root+'/SalasEstudio/SalaEstudio'+roomIndex;
 for(const n of records.filter(n=>n.parent===path)) {
  const id=n.b.match(/mesh = SubResource\("([^"]+)"\)/)?.[1];
  const size=res.get(id)?.match(/size = Vector3\(([^)]+)\)/)?.[1].split(',').map(Number);
  if(!size)continue;
  const t=transform(n);
  const wall=['ParedLateral','ParedFinal','ParedFondo','FrenteVidriado'].includes(n.name) || (size[1]>=4.1 && size[0]===2.3 && size[2]===.09);
  if(wall) {size[1]=ceilingY;t[10]=ceilingY/2;move(n,t);meshSize(n,size);}
  if(n.name==='Dintel') {const bottom=t[10]-size[1]/2;size[1]=ceilingY-bottom;t[10]=bottom+size[1]/2;move(n,t);meshSize(n,size);}
  if(n.name==='TechoBox') hide(n);
 }
}
// Correct the single giant glazed perimeter wall with the existing wall finish.
set(byPath.get(root+'/ParedIzquierdaVidrio'),'material',E('18_oye8v'));
for(const n of records.filter(n=>n.parent===photo)) {
 const t=transform(n);
 if(t[9]<-84.5 && t[9]>-84.7) hide(n); // only glazing vinyl/mullions on that wall
}
// Keep all 19 PC stations, grouped along two perimeter walls, facing their wall.
const pcs=records.filter(n=>n.parent===root+'/PuestosComputadores');assert.equal(pcs.length,19);
pcs.forEach((n,i)=>{
 const t=i<9 ? [0,0,1,0,1,0,-1,0,0,-82,0,-116+i*3.6] : [-1,0,0,0,1,0,0,0,-1,-81+(i-9)*2.85,0,-78.9];
 move(n,t);
 const path=n.parent+'/'+n.name;
 if(!byPath.has(path+'/Mouse')) box('Mouse',path,[.62,1.235,.2],[.14,.07,.22],black);
});
// Four existing shelves become parallel rows; keep their original colored books.
const shelves=records.filter(n=>n.parent===root+'/Estanterias');assert.equal(shelves.length,4);
shelves.forEach((n,i)=>{
 move(n,[1,0,0,0,1,0,0,0,1,-75,0,-119+i*3.5]);
 const path=n.parent+'/'+n.name;
 label('Categoria',path,[0,2.45,.39],['CONSULTA','LITERATURA','CIENCIAS','FORMACIÓN GENERAL'][i]);
 for(const book of records.filter(b=>b.parent===path && b.name.startsWith('Libros'))) {
  const size=book.b.match(/size = Vector3\(([^)]+)\)/)?.[1].split(',').map(Number);
  if(!size)continue;
  const match=book.name.match(/Libros(\d+)_(\d+)/), column=Number(match[1]),row=Number(match[2]);
  const h=.42+((column+row+i)%4)*.045;
  const t=transform(book);t[10]=[.25,.90,1.55][row-1]+h/2;size[0]=.18+((column+i)%4)*.035;size[1]=h;
  move(book,t);set(book,'size','Vector3('+size.join(', ')+')');
  if(column%3===0) box('EtiquetaLomo'+column+'_'+row,path,[t[9],t[10]-.07,.272],[size[0]*.65,.045,.009],white);
 }
});
// Reuse the existing open oval counter, keeping the NPC and its gameplay anchor.
const counter=photo+'/MesonOvaladoAbierto';
set(byPath.get(counter+'/CubiertaOscuraOvalada'),'material_override',wood);
set(byPath.get(counter+'/MesaTrabajoInterior'),'material_override',wood);
for(const part of ['BaseMonitorAtencion','SoporteMonitor','MonitorBibliotecaria','PantallaBibliotecaria','Teclado']) {
 const n=byPath.get(counter+'/'+part);assert(n,part);
 const t=transform(n);t[9]=1.2;move(n,t);
 // Reuse the original equipment for a second staff position.
 let b=n.b.replace('name="'+part+'"','name="Segundo'+part+'"').replace(/ unique_id=\d+/,'');
 const second=transform(n);second[9]=-1.2;
 b=b.replace(/transform = Transform3D\([^)]+\)/,'transform = Transform3D('+second.join(', ')+')');
 additions.push(b);
}
box('MouseAtencion',counter,[1.9,1.08,-1.8],[.14,.07,.22],black);
box('SegundoMouseAtencion',counter,[-.5,1.08,-1.8],[.14,.07,.22],black);
// Reuse an existing office chair model without touching its original assembly.
const template='Piso1/InteriorCoordinacion/SillaOficina';
for(let i=0;i<2;i++) {
 const path=group('SillaPersonal'+(i+1),counter,[i===0?1.2:-1.2,0,-.55]);
 for(const n of records.filter(n=>n.parent===template || n.parent?.startsWith(template+'/'))) {
  additions.push(n.b.replace(/ unique_id=\d+/,'').replace('parent="'+n.parent+'"','parent="'+path+n.parent.slice(template.length)+'"'));
 }
}
// Of six existing round study tables, adapt two to rectangular group tables.
const tables=records.filter(n=>n.parent===photo && byPath.has(photo+'/'+n.name+'/TableroMadera'));
assert.equal(tables.length,6);
for(const [i,table] of tables.entries()) {
 const path=photo+'/'+table.name;
 if(i===4 || i===5) {
  const top=byPath.get(path+'/TableroMadera');
  const meshId='library_layout_'+(++serial),shapeId=meshId+'_shape';
  resources.push(`[sub_resource type="BoxMesh" id="${meshId}"]\nsize = Vector3(3.6, 0.14, 2.4)\n\n[sub_resource type="BoxShape3D" id="${shapeId}"]\nsize = Vector3(3.6, 0.14, 2.4)\n\n`);
  set(top,'mesh',R(meshId));
  for(const c of records.filter(n=>n.parent?.startsWith(path+'/TableroMadera/') && n.b.includes('type="CollisionShape3D"'))) set(c,'shape',R(shapeId));
  for(const part of ['PedestalBlanco','BaseCircular']) hide(byPath.get(path+'/'+part));
  for(const x of [-1.5,1.5]) for(const z of [-.9,.9]) box('PataMesa'+x+'_'+z,path,[x,.56,z],[.09,1.12,.09],metal);
 }
 box('LibroConsulta',path,[.35,1.29,0],[.46,.09,.62],R('merge_local_StandardMaterial3D_qlp2w'));
 box('PaginasLibro',path,[.35,1.29,.025],[.42,.06,.59],white);
}
group('MejorasBiblioteca',root);
// Verify the permitted scope against the exact working scene, not against HEAD.
for(let i=0;i<blocks.length;i++) {
 if(blocks[i]===before[i])continue;
 const n=records.find(n=>n.i===i);assert(n && n.parent?.startsWith(root),'Out-of-scope edit');
 assert(!n.b.includes('type="OmniLight3D"') && !n.b.includes('type="SpotLight3D"'),'Existing light changed');
 assert(n.name!=='FondoCieloMadera' && n.name!=='BossBibliotecaria','Protected object changed');
}
let result=blocks.join('');const firstNode=result.indexOf('[node ');
result=result.slice(0,firstNode)+resources.join('')+result.slice(firstNode);
const connections=result.indexOf('[connection ');
result=connections<0?result+additions.join(''):result.slice(0,connections)+additions.join('')+result.slice(connections);
fs.writeFileSync(file,result.trimEnd()+'\n');
console.log('LIBRARY_SCOPE_OK original_resources/materials/ceiling/lights/NPC/outside_sectors preserved');
console.log('LIBRARY_UPDATE_OK PCs=19 shelves=4 study_rooms=6 tables=6 (4 round + 2 rectangular) staff_chairs=2');
require('./refine_library_layout.cjs');
