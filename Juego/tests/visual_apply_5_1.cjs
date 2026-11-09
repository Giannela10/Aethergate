// Surgical visual changes. Does not save/regenerate Main through @tool builders.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../..'),project=path.join(root,'Juego');
const recovery=path.join(root,'recovery/before_visual_remodel_5_1');
const manifest=JSON.parse(fs.readFileSync(path.join(recovery,'manifest.json'),'utf8'));
const baseline=manifest.files.find(f=>f.path.replaceAll('\\','/')==='Juego/Main.tscn');
let scene=fs.readFileSync(path.join(project,'Main.tscn'),'utf8');
if(crypto.createHash('sha256').update(scene).digest('hex')!==baseline.sha256)throw Error('Main changed since the 5.1 recovery point; refusing to overwrite it.');
const changes=[];
const escape=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
function setNode(nodePath,property,value){let count=0;
 scene=scene.replace(/^\[node [^\r\n]+\][\s\S]*?(?=^\[|$(?![\s\S]))/gm,block=>{
  const header=block.split('\n')[0],name=/ name="([^"]+)"/.exec(header)?.[1],parent=/ parent="([^"]+)"/.exec(header)?.[1];
  const key=parent==='.'?name:parent?parent+'/'+name:name;if(key!==nodePath)return block;count++;
  if(!/type="(?:Label3D|MeshInstance3D)"/.test(header))throw Error('Not a visual-only node: '+key);
  const line=new RegExp('^'+escape(property)+' = (?:"(?:[^"\\\\]|\\\\.)*"|[^\\r\\n]*)','m');
  const old=line.exec(block)?.[0]??null;
  changes.push({nodePath,property,before:old,after:value});
  return old?block.replace(line,property+' = '+value):block.replace(/\r?\n/,'\n'+property+' = '+value+'\n');
 });if(count!==1)throw Error('Expected exactly one '+nodePath+', found '+count);
}
for(const z of ['-118_5','-90_5']){
 const old='Piso2/AuditorioPiso2e/EntradasAuditorio/LetreroEntrada'+z;
 setNode(old,'visible','false');setNode(old,'double_sided','false');
 const active='Piso2/AuditorioPiso2e/AuditorioAmpliado/LetreroEntrada'+z;
 setNode(active,'double_sided','false');setNode(active,'pixel_size','0.0042');setNode(active,'outline_size','0');
 setNode(active,'transform',`Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 71.26724, 16.25, ${z.replace('_','.')})`);
}
for(let f=2;f<=8;f++){
 const prefix=`Piso${f}/VestibuloAscensores/`;
 setNode(prefix+'PlanoPisos','text',JSON.stringify(`PLANO DE LOS PISOS\nPISO ${f} · USTED ESTÁ AQUÍ\n\nPISO 1\nCasino · Coordinación\n\nPISO 2\nBiblioteca · Auditorio`));
 setNode(prefix+'PlanoPisos','pixel_size','0.003');setNode(prefix+'PlanoPisos','outline_size','0');
 if(f>=5){
  for(const [name,x,y]of [['CartelPlano',-19.92,2.15],['CabeceraPlano',-19.81,3.8],['PlanoPisos',-19.835,2.3]])setNode(prefix+name,'transform',`Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, ${x}, ${y}, -143)`);
 }
}
// Reuse the 5.0 matte sign material. All added nodes are render meshes only.
if(!scene.includes('id="visual5_sign"'))throw Error('Existing reusable sign material not found');
const resources='[sub_resource type="BoxMesh" id="BoxMesh_visual51_auditorium"]\nsize = Vector3(0.05, 0.56, 3.24)\n\n[sub_resource type="BoxMesh" id="BoxMesh_visual51_directory_leg"]\nsize = Vector3(0.08, 0.35, 0.08)\n\n[sub_resource type="BoxMesh" id="BoxMesh_visual51_directory_base"]\nsize = Vector3(0.55, 0.06, 2.9)\n\n';
scene=scene.replace(/(?=^\[node )/m,resources);
let nodes='';
function addMesh(name,parent,pos,mesh){nodes+=`\n[node name="${name}" type="MeshInstance3D" parent="${parent}"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${pos.join(', ')})\nmaterial_override = ExtResource("visual5_sign")\nmesh = SubResource("${mesh}")\n`;}
for(const [name,z]of [['PlacaEntrada51Norte',-118.5],['PlacaEntrada51Sur',-90.5]])addMesh(name,'Piso2/AuditorioPiso2e/AuditorioAmpliado',[71.23224,16.25,z],'BoxMesh_visual51_auditorium');
for(const [name,z]of [['SoporteDirectorio51Norte',-143.8],['SoporteDirectorio51Sur',-142.2]])addMesh(name,'Piso5/VestibuloAscensores',[-19.92,0.175,z],'BoxMesh_visual51_directory_leg');
addMesh('BaseDirectorio51','Piso5/VestibuloAscensores',[-19.92,0.03,-143],'BoxMesh_visual51_directory_base');
const tail=scene.search(/^\[(?:connection|editable) /m);
scene=tail<0?scene+nodes:scene.slice(0,tail)+nodes+'\n'+scene.slice(tail);
fs.writeFileSync(path.join(project,'Main.tscn'),scene);
fs.writeFileSync(path.join(project,'reports/visual_5_1/visual_patches.json'),JSON.stringify(changes,null,2));
console.log(JSON.stringify({reviewed_properties:changes.length,hidden_duplicate_labels:2,active_auditorium_labels:2,updated_directories:7,relocated_directory_panels:4,added_render_meshes:5,collision_changes:0}));
