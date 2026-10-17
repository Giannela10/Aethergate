// Replace only the three seating groups directly beyond the reception counter.
const fs=require('fs'),assert=require('assert');
const file='Main.tscn',source=fs.readFileSync(file,'utf8');
if(source.includes('name="PasillosEstanterias"')){require('./library_double_sided_shelves.cjs');console.log('Shelf aisles already applied.');process.exit(0);}
const root='Piso2/Biblioteca',photo=root+'/MobiliarioReferenciaFoto';
const blocks=source.split(/(?=^\[)/m),before=[...blocks];
const nodes=blocks.map((b,i)=>({b,i,name:b.match(/^\[node name="([^"]+)"/)?.[1],parent:b.match(/^\[node .*parent="([^"]+)"/)?.[1]})).filter(n=>n.name);
const paths=new Map(nodes.map(n=>[n.parent+'/'+n.name,n]));
const added=[];
function t(n){return n.b.match(/transform = Transform3D\(([^)]+)\)/)?.[1].split(',').map(Number)||[1,0,0,0,1,0,0,0,1,0,0,0];}
function set(n,key,value){const rx=new RegExp('^'+key+' = .*$','m');blocks[n.i]=rx.test(blocks[n.i])?blocks[n.i].replace(rx,key+' = '+value):blocks[n.i].replace(/\n/,'\n'+key+' = '+value+'\n');}
function hideTree(n){
 set(n,'visible','false');const path=n.parent+'/'+n.name;
 for(const child of nodes.filter(c=>c.parent===path||c.parent?.startsWith(path+'/'))){
  if(child.b.includes('type="CollisionShape3D"'))set(child,'disabled','true');
  if(child.b.includes('use_collision = true'))set(child,'use_collision','false');
 }
}
const tables=nodes.filter(n=>n.parent===photo&&paths.has(photo+'/'+n.name+'/TableroMadera'));
const replaced=tables.filter(n=>Math.abs(t(n)[9]+60)<.1);
assert.equal(replaced.length,3,'Expected the three tables straight ahead of the curved counter');
let chairsRemoved=0;
for(const table of replaced){
 const pos=t(table);hideTree(table);
 for(const n of nodes.filter(n=>n.parent===photo&&paths.has(photo+'/'+n.name+'/AsientoAzul'))){
  const p=t(n);if(Math.hypot(p[9]-pos[9],p[11]-pos[11])<2.4){hideTree(n);chairsRemoved++;}
 }
}
assert.equal(chairsRemoved,12);
function group(name,parent,pos,angle=0,yscale=1){
 const c=Math.cos(angle),s=Math.sin(angle);
 added.push(`[node name="${name}" type="Node3D" parent="${parent}"]\ntransform = Transform3D(${c}, 0, ${s}, 0, ${yscale}, 0, ${-s}, 0, ${c}, ${pos.join(', ')})\n\n`);
 return parent+'/'+name;
}
const collection=group('PasillosEstanterias',root,[0,0,0]);
function shelfModule(name,parent,pos,sourceIndex,category){
 const path=group(name,parent,pos);
 const old=root+'/Estanterias/Estante'+sourceIndex;
 for(const n of nodes.filter(n=>n.parent===old||n.parent?.startsWith(old+'/'))){
  let b=n.b.replace(/ unique_id=\d+/,'').replace('parent="'+n.parent+'"','parent="'+path+n.parent.slice(old.length)+'"');
  if(n.name==='Categoria')b=b.replace(/^text = .*$/m,'text = "'+category+'"');
  added.push(b);
 }
}
// Four horizontal rows, with 4.8 m clear aisles; shelves remain character-height.
for(let i=0;i<4;i++){
 const row=group('EstanteriaCentral0'+(i+1),collection,[-61.5,0,-104.5+i*5.5],0,.95);
 const title=['LITERATURA','CIENCIAS Y TECNOLOGÍA','HUMANIDADES','FORMACIÓN GENERAL'][i];
 shelfModule('ModuloA',row,[-2.05,0,0],i+1,title);
 shelfModule('ModuloB',row,[2.05,0,0],i+1,title);
}
// A longitudinal passage in front of the rows, flanked by two more shelves.
const left=group('EstanteriaLateralIzquierda',collection,[-64,0,-85],Math.PI/2,.95);
const right=group('EstanteriaLateralDerecha',collection,[-59,0,-85],-Math.PI/2,.95);
shelfModule('Modulo',left,[0,0,0],2,'LECTURA');
shelfModule('Modulo',right,[0,0,0],3,'CONSULTA');
// Retain a mixed study area: reuse the rectangular top and legs from a removed
// table on the middle surviving round table, without duplicating its chairs.
const target=tables.find(n=>Math.abs(t(n)[9]+72)<.1&&Math.abs(t(n)[11]+92)<.1);
const rectangle=replaced.find(n=>nodes.some(c=>c.parent===photo+'/'+n.name&&c.name.startsWith('PataMesa')));
assert(target&&rectangle);
const targetPath=photo+'/'+target.name,rectanglePath=photo+'/'+rectangle.name;
const targetTop=paths.get(targetPath+'/TableroMadera'),sourceTop=paths.get(rectanglePath+'/TableroMadera');
set(targetTop,'mesh',sourceTop.b.match(/^mesh = (.*)$/m)[1]);
const sourceShape=nodes.find(n=>n.parent?.startsWith(rectanglePath+'/TableroMadera/')&&n.b.includes('type="CollisionShape3D"'));
for(const n of nodes.filter(n=>n.parent?.startsWith(targetPath+'/TableroMadera/')&&n.b.includes('type="CollisionShape3D"')))set(n,'shape',sourceShape.b.match(/^shape = (.*)$/m)[1]);
for(const name of ['PedestalBlanco','BaseCircular'])hideTree(paths.get(targetPath+'/'+name));
for(const n of nodes.filter(n=>n.parent===rectanglePath&&n.name.startsWith('PataMesa'))){
 added.push(n.b.replace(/ unique_id=\d+/,'').replace('parent="'+rectanglePath+'"','parent="'+targetPath+'"'));
}
for(let i=0;i<blocks.length;i++)if(blocks[i]!==before[i]){
 const n=nodes.find(n=>n.i===i);assert(n&&n.parent?.startsWith(photo),'Unexpected out-of-scope modification');
}
let result=blocks.join('');const connections=result.indexOf('[connection ');
result=connections<0?result+added.join(''):result.slice(0,connections)+added.join('')+result.slice(connections);
fs.writeFileSync(file,result.trimEnd()+'\n');
console.log('LIBRARY_AISLES_OK removed_visible_tables=3 removed_chairs=12 central_shelves=4 flanking_shelves=2; original_resources/walls/ceiling/lights/NPC/19_PCs preserved');
require('./library_double_sided_shelves.cjs');
