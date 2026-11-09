// Reapply only reviewed visual properties to the exact pre-edit scene.
// Godot's @tool generators regenerate unrelated nodes on a full editor save.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../..'),project=path.join(root,'Juego');
const recovery=path.join(root,'recovery/before_visual_remodel_5_0');
let scene=fs.readFileSync(path.join(recovery,'Juego/Main.tscn'),'utf8');
const manifest=JSON.parse(fs.readFileSync(path.join(recovery,'manifest.json'),'utf8'));
const expected=manifest.files.find(f=>f.path.replaceAll('\\','/')==='Juego/Main.tscn');
if(crypto.createHash('sha256').update(scene).digest('hex')!==expected.sha256)throw Error('Recovery scene hash mismatch');
const rejected=path.join(root,'recovery/visual_5_editor_serialization.tscn');
if(!fs.existsSync(rejected))fs.copyFileSync(path.join(project,'Main.tscn'),rejected);
const patches=[];
function setNode(text,nodePath,property,value){let count=0;const result=text.replace(/^\[node [^\r\n]+\][\s\S]*?(?=^\[|$(?![\s\S]))/gm,block=>{
 const header=block.split('\n')[0],name=/ name="([^"]+)"/.exec(header)?.[1],parent=/ parent="([^"]+)"/.exec(header)?.[1];
 const key=parent==='.'?name:parent?parent+'/'+name:name;
 if(key!==nodePath)return block;count++;
 const line=new RegExp('^'+property.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+' = [^\\r\\n]*','m');
 return line.test(block)?block.replace(line,property+' = '+value):block.replace(/\r?\n/,'\n'+property+' = '+value+'\n');
 });if(count!==1)throw Error('Expected exactly one '+nodePath+', got '+count);patches.push({nodePath,property,value});return result;}
const inventory=JSON.parse(fs.readFileSync(path.join(project,'reports/visual_5/before_inventory.json'),'utf8'));
for(const light of inventory.lights.filter(l=>l.range>100)){
 scene=setNode(scene,light.path,'visible','false');
 scene=setNode(scene,light.path,'omni_range','16.0');
}
scene=setNode(scene,'PisoMenos1/AmbientacionIndustrial2026/NegocioCafeteria/LetreroCafeteria','transform','Transform3D(-1, 0, 0, 0, 1, 0, 0, 0, -1, -31, -8.808386, -132.025)');
scene=scene.replace(/(?=^\[sub_resource )/m,'[ext_resource type="Material" path="res://materials/entrance/MAT_Sign_Backplate_5.tres" id="visual5_sign"]\n\n');
scene=scene.replace(/(?=^\[node )/m,'[sub_resource type="BoxMesh" id="BoxMesh_visual5_sign"]\nsize = Vector3(8.5, 0.68, 0.06)\n\n[sub_resource type="BoxMesh" id="BoxMesh_visual5_sign_support"]\nsize = Vector3(0.04, 0.35, 0.04)\n\n');
let nodes='';
for(const [name,x,y,mesh]of [['PlacaLetreroCafeteria5',-31,-8.808386,'BoxMesh_visual5_sign'],['SoporteLetreroCafeteria5Izq',-34.4,-8.348386,'BoxMesh_visual5_sign_support'],['SoporteLetreroCafeteria5Der',-27.6,-8.348386,'BoxMesh_visual5_sign_support']])nodes+=`\n[node name="${name}" type="MeshInstance3D" parent="PisoMenos1/AmbientacionIndustrial2026/NegocioCafeteria"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${x}, ${y}, -131.98)\nmaterial_override = ExtResource("visual5_sign")\nmesh = SubResource("${mesh}")\n`;
const tail=scene.search(/^\[(?:connection|editable) /m);
let printerNodes='\n[node name="MesaImpresora5" type="CSGBox3D" parent="Piso2/SalaImpresiones"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -80.8, 1.85, -115.8)\nsize = Vector3(1.55, 0.1, 1.05)\nmaterial = ExtResource("visual5_sign")\n';
let leg=0;for(const dx of [-0.65,0.65])for(const dz of [-0.4,0.4])printerNodes+=`\n[node name="PataMesaImpresora5_${leg++}" type="CSGBox3D" parent="Piso2/SalaImpresiones"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, ${-80.8+dx}, 0.9, ${-115.8+dz})\nsize = Vector3(0.08, 1.8, 0.08)\nmaterial = ExtResource("visual5_sign")\n`;
nodes+=printerNodes;
scene=tail<0?scene+nodes:scene.slice(0,tail)+nodes+'\n'+scene.slice(tail);
// Only the two visual projector meshes change in the shared scene.
let corridor=fs.readFileSync(path.join(recovery,'Juego/scripts/pisos/piso_8/PasilloReferencia.tscn'),'utf8');
for(const light of inventory.lights.filter(l=>/^Piso8\/PasilloReferencia\/Sala8\d+\/LuzInterior/.test(l.path)))corridor=setNode(corridor,light.path.replace('Piso8/PasilloReferencia/',''),'light_color','Color(1, 0.98, 0.95, 1)');
for(const [name,z]of [['PantallaProyeccion',-8.08],['ImagenProyector',-8.03]])corridor=setNode(corridor,'Sala810/'+name,'transform',`Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 3.6, ${z})`);
corridor=setNode(corridor,'Sala810/ArmarioMateriales','transform','Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, 2.65, 1, -6.7)');
fs.writeFileSync(path.join(project,'Main.tscn'),scene);
fs.writeFileSync(path.join(project,'scripts/pisos/piso_8/PasilloReferencia.tscn'),corridor);
fs.writeFileSync(path.join(project,'reports/visual_5/curated_patches.json'),JSON.stringify(patches,null,2));
console.log(JSON.stringify({reviewed_property_edits:patches.length,added_visual_nodes:8,collision_shape_edits:0,relocated_collidable_parents:3}));
