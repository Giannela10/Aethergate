const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../..'),project=path.join(root,'Juego'),snapshot=path.join(root,'recovery/before_visual_remodel_5_1');
const manifest=JSON.parse(fs.readFileSync(path.join(snapshot,'manifest.json'),'utf8'));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const allowed=['Juego/Main.tscn','Juego/scripts/pisos/piso_2/auditorio_piso_2e.gd','Juego/scripts/compartidos/edicion/interiores_referencia_campus.gd'];
const changed=manifest.files.filter(f=>fs.existsSync(path.join(root,f.path))&&hash(fs.readFileSync(path.join(root,f.path)))!==f.sha256).map(f=>f.path.replaceAll('\\','/'));
const missing=manifest.files.filter(f=>!fs.existsSync(path.join(root,f.path))).map(f=>f.path);
function sections(s){return new Map(s.split(/(?=^\[(?:node|sub_resource|ext_resource|connection|editable) )/m).map(b=>[b.split('\n')[0].trim(),b.trim()]));}
const oldText=fs.readFileSync(path.join(snapshot,'Juego/Main.tscn'),'utf8'),newText=fs.readFileSync(path.join(project,'Main.tscn'),'utf8');
const before=sections(oldText),after=sections(newText);
const removed=[...before.keys()].filter(k=>!after.has(k));
const changes=[...before].filter(([k,v])=>after.has(k)&&after.get(k)!==v).map(([header])=>header);
const additions=[...after.keys()].filter(k=>!before.has(k));
const protectedChanges=changes.filter(k=>/type="(?:Collision|BoxShape|CapsuleShape|SphereShape|StaticBody|CharacterBody|Area3D)/.test(k));
const idLines=s=>s.split('\n').filter(l=>/world_id\s*=|boss_id\s*=|mission_id\s*=/.test(l)).sort();
const ids=JSON.stringify(idLines(oldText))===JSON.stringify(idLines(newText));
const report={status:missing.length===0&&removed.length===0&&protectedChanges.length===0&&ids&&changed.every(p=>allowed.includes(p))?'PASS AUTOMÁTICO':'FAIL',changed_existing_files:changed,missing_files:missing,removed_scene_sections:removed,changed_scene_nodes:changes,added_scene_sections:additions,collision_or_actor_changes:protectedChanges,persistent_identifiers_unchanged:ids,protected_sources_byte_identical:changed.every(p=>allowed.includes(p)),notes:'Only two visual builders and reviewed visual nodes in Main may differ. No removed nodes, modified collision bodies/shapes, gameplay scripts or personal saves.'};
fs.writeFileSync(path.join(project,'reports/visual_5_1/source_audit.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
