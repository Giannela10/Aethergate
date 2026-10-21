// Additive furniture-only scene edit. Does not regenerate the architectural interior.
const fs = require('fs');
const assert = require('assert');
const file = 'Main.tscn';
const source = fs.readFileSync(file, 'utf8');
if (source.includes('id="coord_furniture_laminate"')) {
  // Repair/reapply the laminate only to the three tall storage carcasses and doors.
  const sections=source.split(/(?=^\[)/m);
  for(let i=0;i<sections.length;i++) {
    const b=sections[i];
    if(!b.startsWith('[node ') || !b.includes('parent="Piso1/InteriorCoordinacion"')) continue;
    const mesh=b.match(/mesh = SubResource\("([^"]+)"\)/)?.[1];
    const res=sections.find(v=>v.startsWith('[sub_resource ') && v.includes('id="'+mesh+'"'));
    if(res && /size = Vector3\((0.75, 3.25, 3.05|0.06, 3.15, 1.46)\)/.test(res)) {
      sections[i]=b.replace(/material_override = SubResource\("[^"]+"\)/,'material_override = SubResource("coord_furniture_laminate")');
    }
  }
  fs.writeFileSync(file,sections.join('').trimEnd()+'\n');
  console.log('Furniture already present; tall cabinet laminate synchronized.'); process.exit(0);
}
const root = 'Piso1/InteriorCoordinacion';
const originalBlocks = source.split(/(?=^\[)/m);
const blocks = [...originalBlocks];
const nodes = blocks.map((b,i)=>({b,i,name:b.match(/^\[node name="([^"]+)"/)?.[1],parent:b.match(/^\[node .*parent="([^"]+)"/)?.[1]})).filter(n=>n.name);
const direct = nodes.filter(n=>n.parent===root);
const desks = direct.filter(n=>n.b.includes('type="Node3D"') && nodes.some(c=>c.parent===root+'/'+n.name && c.name==='TableroMadera'));
assert.equal(desks.length,8);
const resources=[]; const additions=[];
const fmt = v=>Number(v.toFixed(6));
function material(id,color) {
  resources.push(`[sub_resource type="StandardMaterial3D" id="coord_furniture_${id}"]\nalbedo_color = Color(${color.join(', ')}, 1)\nroughness = 0.72\n\n`);
  return 'coord_furniture_'+id;
}
const laminate=material('laminate',[.70,.66,.60]);
const dark=material('dark',[.045,.05,.055]);
const metal=material('metal',[.25,.27,.28]);
const white=material('white',[.90,.91,.90]);
const blue=material('folder_blue',[.10,.24,.39]);
const ochre=material('sofa',[.88,.53,.13]);
const green=material('leaves',[.20,.36,.18]);
const soil=material('soil',[.14,.10,.07]);
const screen=material('screen',[.13,.29,.34]);
function group(name,parent,pos=[0,0,0]) {
  additions.push(`[node name="${name}" type="Node3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${pos.map(fmt).join(', ')})\n\n`);
  return parent+'/'+name;
}
let serial=0;
function box(name,parent,pos,size,mat,solid=false) {
  const id='coord_furniture_box_'+(++serial);
  resources.push(`[sub_resource type="BoxMesh" id="${id}"]\nsize = Vector3(${size.join(', ')})\n\n`);
  additions.push(`[node name="${name}" type="MeshInstance3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${pos.map(fmt).join(', ')})\nmaterial_override = SubResource("${mat}")\nmesh = SubResource("${id}")\n\n`);
  if(solid) {
    resources.push(`[sub_resource type="BoxShape3D" id="${id}_shape"]\nsize = Vector3(${size.join(', ')})\n\n`);
    additions.push(`[node name="CuerpoMueble" type="StaticBody3D" parent="${parent}/${name}"]\n\n[node name="Colision" type="CollisionShape3D" parent="${parent}/${name}/CuerpoMueble"]\nshape = SubResource("${id}_shape")\n\n`);
  }
}
function assign(n,mat) {blocks[n.i]=blocks[n.i].replace(/material_override = SubResource\("[^"]+"\)/,'material_override = SubResource("'+mat+'")');}
// Only explicit furniture assemblies receive the new laminate. No shared material is edited.
for(const n of nodes) {
  if(n.parent===root+'/Recepcion' && ['MesonMadera','CubiertaMeson'].includes(n.name)) assign(n,laminate);
  if(desks.some(d=>n.parent===root+'/'+d.name) && n.name==='TableroMadera') assign(n,laminate);
  if(n.parent===root && (n.name==='ArmarioMadera' || n.b.includes('mesh = SubResource("BoxMesh_1kx8f")'))) assign(n,laminate);
  if(n.parent===root) {
    const id=n.b.match(/mesh = SubResource\("([^"]+)"\)/)?.[1];
    const resource=blocks.find(b=>b.startsWith('[sub_resource ') && b.includes('id="'+id+'"'));
    if(resource && /size = Vector3\((0.75, 3.25, 3.05|0.06, 3.15, 1.46)\)/.test(resource)) assign(n,laminate);
  }
}
const extra=group('MobiliarioAdministrativo',root);
// Low storage in front of the tall cabinets, with doors and metal pulls.
for(let i=0;i<3;i++) {
  const cabinet=group('ArmarioBajo'+(i+1),extra,[81.65,0,-119+i*3.2]);
  box('Cuerpo',cabinet,[0,.62,0],[1,1.24,2.8],laminate,true);
  box('Cubierta',cabinet,[0,1.28,0],[1.08,.08,2.88],laminate);
  for(let side of [-1,1]) {
    box('Puerta'+(side<0?'A':'B'),cabinet,[-.52,.66,side*.68],[.04,1.08,1.3],laminate);
    box('Tirador'+(side<0?'A':'B'),cabinet,[-.56,.76,side*.22],[.06,.28,.05],metal);
  }
}
// Eight existing desks and their chairs stay in place. Add restrained variation.
desks.forEach((desk,i)=>{
  const path=root+'/'+desk.name;
  if(i===1 || i===5) {
    // Reuse the complete existing monitor, duplicating only its four main parts.
    for(const part of ['BaseMonitor','PieMonitor','Monitor','Pantalla']) {
      const n=nodes.find(n=>n.parent===path && n.name===part);
      assert(n,part);
      let b=n.b.replace('name="'+part+'"','name="Segundo'+part+'"').replace(/ unique_id=\d+/,'');
      b=b.replace(/transform = Transform3D\(([^)]+)\)/,(_,v)=>{
        const t=v.split(',').map(Number);t[9]+=.96;return 'transform = Transform3D('+t.map(fmt).join(', ')+')';});
      additions.push(b);
    }
    // Move the pen holder away from the second display, preserving its contents.
    const holder=nodes.find(n=>n.parent===path && n.name==='PortaLapices');
    const holderIndex=nodes.indexOf(holder);
    for(const n of nodes.slice(holderIndex,holderIndex+4)) {
      if(n.parent!==path) continue;
      blocks[n.i]=blocks[n.i].replace(/transform = Transform3D\(([^)]+)\)/,(_,v)=>{const t=v.split(',').map(Number);t[9]-=1.95;return 'transform = Transform3D('+t.map(fmt).join(', ')+')';});
    }
  } else if(i===2 || i===6) {
    box('NotebookBase',path,[-.85,1.255,-.30],[.85,.06,.55],metal);
    box('NotebookPantalla',path,[-.85,1.56,-.55],[.85,.55,.045],dark);
    box('NotebookDisplay',path,[-.85,1.56,-.521],[.73,.44,.012],screen);
  }
  if(i%2===0) {
    box('Carpeta',path,[1.10,1.25,.12],[.46,.07,.55],blue);
    box('EtiquetaCarpeta',path,[1.10,1.291,.13],[.25,.008,.10],white);
  } else if(i!==1 && i!==5) {
    box('Organizador',path,[1.05,1.27,-.40],[.55,.13,.42],metal);
    box('DocumentosOrganizados',path,[1.05,1.35,-.40],[.47,.035,.34],white);
  }
});
// Small drawer cabinets alongside selected desks, clear of the glass doors.
for(const [i,x,z] of [[1,41.5,-105.2],[2,59.5,-105.2],[3,36.5,-96.7]]) {
  const cabinet=group('Archivador'+i,extra,[x,0,z]);
  box('Cuerpo',cabinet,[0,.54,0],[.85,1.08,.95],laminate,true);
  for(let j=0;j<3;j++) {
    box('Cajon'+j,cabinet,[0,.21+j*.32,.49],[.77,.28,.035],white);
    box('Tirador'+j,cabinet,[0,.22+j*.32,.53],[.28,.04,.05],metal);
  }
}
// Lounge against the free west wall of the open office, away from all doors.
const sofa=group('SofaMostaza',extra,[34.7,0,-112.6]);
box('Base',sofa,[0,.28,0],[1.5,.36,3.5],dark,true);
box('Respaldo',sofa,[-.61,1.00,0],[.25,1.20,3.5],ochre,true);
for(const side of [-1,1]) {
  box('Cojin'+(side<0?'A':'B'),sofa,[.08,.57,side*.78],[1.13,.25,1.47],ochre);
  box('Brazo'+(side<0?'A':'B'),sofa,[0,.79,side*1.65],[1.5,.65,.22],ochre,true);
}
const table=group('MesaAuxiliarBlanca',extra,[37.0,0,-112.6]);
box('Cubierta',table,[0,.65,0],[1.1,.10,1.3],white,true);
for(const x of [-.42,.42]) for(const z of [-.5,.5]) box('Pata'+x+'_'+z,table,[x,.31,z],[.07,.62,.07],metal);
function plant(name,pos) {
  const p=group(name,extra,pos);
  box('Macetero',p,[0,.33,0],[.62,.66,.62],white,true);
  box('Tierra',p,[0,.67,0],[.52,.025,.52],soil);
  box('Tallo',p,[0,1.03,0],[.06,.75,.06],green);
  for(let i=0;i<5;i++) {
    const a=i*Math.PI*2/5;
    box('Hoja'+i,p,[Math.cos(a)*.23,1.06+(i%2)*.28,Math.sin(a)*.23],[.24,.50,.20],green);
  }
}
plant('PlantaRecepcion',[81.7,0,-110.7]);
plant('PlantaOficinas',[45,0,-107.8]);
// Strong scope guard: only materials/transforms on the selected office furniture.
for(let i=0;i<blocks.length;i++) {
  if(blocks[i]===originalBlocks[i]) continue;
  assert(blocks[i].startsWith('[node '));
  assert(blocks[i].includes('parent="'+root));
  assert(!/name="(Piso|Techo|Pared|Mampara|Ventana|Puerta|Luz|Division|Perfil)/.test(blocks[i].split('\n')[0]));
}
let result=blocks.join('');
const firstNode=result.indexOf('[node ');
result=result.slice(0,firstNode)+resources.join('')+result.slice(firstNode);
// Append children after their existing parents and before the scene's connections.
const connection=result.indexOf('[connection ');
result=connection<0?result+additions.join(''):result.slice(0,connection)+additions.join('')+result.slice(connection);
fs.writeFileSync(file,result.trimEnd()+'\n');
console.log('COORDINACION_FURNITURE_OK desks=8 waiting_chairs=4 glass_offices=4; architecture/material resources/lighting untouched');
