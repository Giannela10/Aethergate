// Scoped migration: one meeting enclosure, eight reused desks, unchanged finishes.
const fs=require('fs'),assert=require('assert'),crypto=require('crypto');
const file='Main.tscn',source=fs.readFileSync(file,'utf8');
if(source.includes('name="SalaReuniones" type="Node3D" parent="Piso1/InteriorCoordinacion"')){console.log('Meeting layout already applied.');process.exit(0);}
const root='Piso1/InteriorCoordinacion',blocks=source.split(/(?=^\[)/m),before=[...blocks];
const nodes=blocks.map((b,i)=>({b,i,name:b.match(/^\[node name="([^"]+)"/)?.[1],parent:b.match(/^\[node .*parent="([^"]+)"/)?.[1]})).filter(n=>n.name);
const paths=new Map(nodes.map(n=>[n.parent+'/'+n.name,n]));
const resources=[],added=[];
const top=4.94,floor=.12,height=top-floor;
function trans(n){return blocks[n.i].match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number)||[1,0,0,0,1,0,0,0,1,0,0,0];}
function set(n,key,value){const rx=new RegExp('^'+key+' = .*$','m');blocks[n.i]=rx.test(blocks[n.i])?blocks[n.i].replace(rx,key+' = '+value):blocks[n.i].replace(/\n/,'\n'+key+' = '+value+'\n');}
function move(n,t){set(n,'transform','Transform3D('+t.map(v=>Number(v.toFixed(7))).join(', ')+')');}
function pose(x,z,angle=0){const c=Math.cos(angle),s=Math.sin(angle);return [c,0,s,0,1,0,-s,0,c,x,0,z];}
function hide(n){set(n,'visible','false');for(const c of nodes.filter(c=>c.parent?.startsWith(n.parent+'/'+n.name+'/'))){if(c.b.includes('type="CollisionShape3D"'))set(c,'disabled','true');}}
// Retain the ceiling while the external auditorium constraint is unresolved.
const ceiling=paths.get(root+'/TechoCoordinacion'),ct=trans(ceiling);ct[10]=top+.05;move(ceiling,ct);
// The auditorium base is outside this migration's scope and remains untouched.
const frontGlass=nodes.find(n=>n.parent===root&&Math.abs(trans(n)[11]+100.7)<.01&&n.b.includes('material_override = SubResource("merge_local_StandardMaterial3D_llcqu")'));
const copier=paths.get(root+'/Fotocopiadora');assert(frontGlass&&copier);
let removed=0;
for(const n of nodes.filter(n=>n.parent===root&&n.i>=frontGlass.i&&n.i<copier.i)){
 if(n.b.includes('type="MeshInstance3D"')||n.b.includes('type="Label3D"')){hide(n);removed++;}
}
const desks=nodes.filter(n=>n.parent===root&&paths.has(root+'/'+n.name+'/TableroMadera'));assert.equal(desks.length,8);
const chairs=nodes.filter(n=>n.parent===root&&paths.has(root+'/'+n.name+'/Piston')&&paths.has(root+'/'+n.name+'/Asiento')&&trans(n)[11]>-109);
assert.equal(chairs.length,8);
const used=new Set(),assignment=[];
desks.forEach((desk,i)=>{
 const old=trans(desk),expected=[old[9],old[11]+(i<4?1.65:-1.65)];
 const chair=chairs.filter(c=>!used.has(c)).sort((a,b)=>Math.hypot(trans(a)[9]-expected[0],trans(a)[11]-expected[1])-Math.hypot(trans(b)[9]-expected[0],trans(b)[11]-expected[1]))[0];
 used.add(chair);
 const coords=i===3?[75.9,-101.8,0]:i===7?[79.2,-101.8,0]:[[43,-105.4,0],[53,-105.4,0],[63,-105.4,0],null,[43,-97.4,Math.PI],[53,-97.4,Math.PI],[63,-97.4,Math.PI]][i];
 move(desk,pose(...coords));
 move(chair,pose(coords[0],coords[1]+(coords[2]===0?1.65:-1.65),coords[2]));
 // Recenter reused chair components while retaining every wheel and armrest.
 const seat=paths.get(root+'/'+chair.name+'/Asiento'),offset=trans(seat);
 for(const c of nodes.filter(n=>n.parent===root+'/'+chair.name)){const t=trans(c);t[9]-=offset[9];t[11]-=offset[11];move(c,t);}
 assignment.push({desk:desk.name,chair:chair.name,x:coords[0],z:coords[1],meeting:i===3||i===7});
});
for(const [name,x,z] of [['Archivador1',45.3,-105.4],['Archivador2',55.3,-105.4],['Archivador3',45.3,-97.4]]){
 const n=paths.get(root+'/MobiliarioAdministrativo/'+name);assert(n);move(n,pose(x,z));
}
resources.push('[sub_resource type="StandardMaterial3D" id="coord_meeting_glass"]\ntransparency = 1\ncull_mode = 2\nalbedo_color = Color(0.62, 0.72, 0.75, 0.14)\nroughness = 0.16\n\n');
const glass='SubResource("coord_meeting_glass")',black='SubResource("coord_furniture_dark")';
let serial=0;
function group(name,parent,p=[0,0,0],angle=0,type='Node3D',properties=''){
 const c=Math.cos(angle),s=Math.sin(angle);
 added.push(`[node name="${name}" type="${type}" parent="${parent}"]\ntransform = Transform3D(${c}, 0, ${s}, 0, 1, 0, ${-s}, 0, ${c}, ${p.join(', ')})\n${properties}\n\n`);
 return parent+'/'+name;
}
function box(name,parent,p,size,mat,solid=false){
 const id='coord_meeting_box_'+(++serial);
 resources.push(`[sub_resource type="BoxMesh" id="${id}"]\nsize = Vector3(${size.join(', ')})\n\n`);
 added.push(`[node name="${name}" type="MeshInstance3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${p.join(', ')})\nmaterial_override = ${mat}\nmesh = SubResource("${id}")\n\n`);
 if(solid){resources.push(`[sub_resource type="BoxShape3D" id="${id}_shape"]\nsize = Vector3(${size.join(', ')})\n\n`);added.push(`[node name="Cuerpo" type="StaticBody3D" parent="${parent}/${name}"]\n\n[node name="Colision" type="CollisionShape3D" parent="${parent}/${name}/Cuerpo"]\nshape = SubResource("${id}_shape")\n\n`);}
 return id;
}
const meeting=group('SalaReuniones',root);
// West entrance, immediately on the left (+X) after the existing reception door.
const x0=72.4,x1=82.9,z0=-109.2,z1=-94.1,doorZ=-106.2;
const spans=[[z0,doorZ-1.3],[doorZ+1.3,z1]];
for(let i=0;i<spans.length;i++){
 const [a,b]=spans[i];box('VidrioAcceso'+i,meeting,[x0,floor+height/2,(a+b)/2],[.08,height,b-a],glass,true);
 for(const y of [floor+.05,top-.05])box('PerfilAcceso'+i+'_'+y,meeting,[x0,y,(a+b)/2],[.12,.1,b-a],black);
}
box('VidrioSobrePuerta',meeting,[x0,(top+3.2)/2,doorZ],[.08,top-3.2,2.6],glass,true);
for(const z of [z0,z1,doorZ-1.35,doorZ+1.35])box('MontanteOeste'+z,meeting,[x0,floor+height/2,z],[.12,height,.12],black,true);
box('MarcoSuperiorPuerta',meeting,[x0,3.2,doorZ],[.12,.1,2.8],black);
box('VidrioEste',meeting,[x1,floor+height/2,(z0+z1)/2],[.08,height,z1-z0],glass,true);
for(const z of [z0,z1]){
 box('VidrioCierre'+z,meeting,[(x0+x1)/2,floor+height/2,z],[x1-x0,height,.08],glass,true);
 for(const y of [floor+.05,top-.05])box('PerfilCierre'+z+'_'+y,meeting,[(x0+x1)/2,y,z],[x1-x0,.1,.12],black);
 box('MontanteEste'+z,meeting,[x1,floor+height/2,z],[.12,height,.12],black,true);
}
for(const y of [floor+.05,top-.05])box('PerfilEste'+y,meeting,[x1,y,(z0+z1)/2],[.12,.1,z1-z0],black);
const doorExt=blocks.find(b=>b.startsWith('[ext_resource ')&&b.includes('path="res://scripts/compartidos/puerta_vidrio_salas.gd"')).match(/ id="([^"]+)"/)[1];
const door=group('PuertaVidrio',meeting,[x0,floor,doorZ],Math.PI/2,'Node3D',`script = ExtResource("${doorExt}")\nancho = 2.6`);
for(const [name,sign] of [['HojaIzquierda',-1],['HojaDerecha',1]]){
 const leaf=group(name,door,[sign*.65,0,0],0,'AnimatableBody3D');
 const id=box('Cristal',leaf,[0,1.54,0],[1.3,3.08,.06],glass);
 resources.push(`[sub_resource type="BoxShape3D" id="${id}_door_shape"]\nsize = Vector3(1.3, 3.08, 0.06)\n\n`);
 added.push(`[node name="Colision" type="CollisionShape3D" parent="${leaf}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.54, 0)\nshape = SubResource("${id}_door_shape")\n\n`);
 box('Tirador',leaf,[-sign*.48,1.45,.07],[.055,.65,.055],black);
}
added.push(`[node name="Rotulo" type="Label3D" parent="${meeting}"]\ntransform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 72.28, 3.6, ${doorZ})\ntext = "SALA DE REUNIONES"\nfont_size = 56\npixel_size = 0.0035\nmodulate = Color(0.08, 0.12, 0.17, 1)\n\n`);
// Two extra participant chairs reuse a complete existing model, not extra desks.
const template=root+'/'+chairs[0].name;
for(let i=0;i<2;i++){
 const chair=group('SillaParticipante'+(i+1),meeting,[75.9+i*3.3,0,-103.4],Math.PI);
 for(const n of nodes.filter(n=>n.parent===template||n.parent?.startsWith(template+'/'))){
  added.push(blocks[n.i].replace(/ unique_id=\d+/,'').replace('parent="'+n.parent+'"','parent="'+chair+n.parent.slice(template.length)+'"'));
 }
}
for(let i=0;i<blocks.length;i++)if(blocks[i]!==before[i]){const n=nodes.find(n=>n.i===i);assert(n&&n.parent?.startsWith(root),'Out-of-scope modification');}
const outside=arr=>arr.filter(b=>b.startsWith('[node ')&&!b.match(/parent="([^"]+)"/)?.[1].startsWith(root)).join('');
const digest=s=>crypto.createHash('sha256').update(s).digest('hex');
assert.equal(digest(outside(before)),digest(outside(blocks)));
let result=blocks.join('');const first=result.indexOf('[node ');result=result.slice(0,first)+resources.join('')+result.slice(first);
const connection=result.indexOf('[connection ');result=connection<0?result+added.join(''):result.slice(0,connection)+added.join('')+result.slice(connection);
fs.writeFileSync(file,result.trimEnd()+'\n');
fs.writeFileSync('reports/coordinacion_meeting_layout.json',JSON.stringify({ceiling_underside:top,requested_ceiling_underside:11.558385849,ceiling_adjustment_applied:false,previous_ceiling_underside:4.94,auditorium_base_preserved:true,removed_glass_components:removed,desks:assignment,outside_scene_hash:digest(outside(before))},null,2)+'\n');
console.log('COORD_MEETING_SCOPE_OK exterior/library/chapel/auditorium/material_resources/lights preserved');
console.log('COORD_MEETING_LAYOUT_OK desks=8 open=6 meeting=2 participants=4 ceiling_underside='+top+' auditorium_overlap_pending');
