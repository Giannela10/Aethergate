const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'../..'),snapshot=path.join(root,'recovery/before_characters_remodel_6_0'),out=path.join(root,'Juego/reports/characters_6_0');
const manifest=JSON.parse(fs.readFileSync(path.join(snapshot,'manifest.json')));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const allowed=['Juego/scripts/juego/humanoid.gd','Juego/scripts/juego/student_visual.gd','Juego/scripts/juego/procedural_appearance_adapter.gd','Juego/scripts/juego/character_appearance.gd','Juego/scripts/juego/character_visual_presets.gd','Juego/scripts/juego/character_activity_visual.gd','Juego/scripts/campaign/appearance_menu.gd'];
const changed=[],missing=[];
for(const row of manifest.files){const p=row.path.replaceAll('\\','/');if(!fs.existsSync(path.join(root,p)))missing.push(p);else if(hash(fs.readFileSync(path.join(root,p)))!==row.sha256)changed.push(p);}
function fn(s,name){const m=s.match(new RegExp('^func '+name+'\\([\\s\\S]*?(?=^func |$(?![\\s\\S]))','m'));if(!m)throw Error('Missing function '+name);return m[0].trim();}
const preserved=[];
for(const [file,names]of Object.entries({'Juego/scripts/juego/humanoid.gd':['_animate_pose','start_punch','is_punching','_punch_weights','_swing_pose'],'Juego/scripts/juego/student_visual.gd':['equip','unequip','animate'],'Juego/scripts/juego/character_appearance.gd':[]})){
 const before=fs.readFileSync(path.join(snapshot,file),'utf8'),after=fs.readFileSync(path.join(root,file),'utf8');
 for(const name of names)preserved.push({file,function:name,identical:fn(before,name)===fn(after,name)});
}
const report={status:!missing.length&&changed.every(p=>allowed.includes(p))&&preserved.every(x=>x.identical)?'PASS AUTOMÁTICO':'FAIL',changed_existing_sources:changed,missing_sources:missing,unexpected_changes:changed.filter(p=>!allowed.includes(p)),functional_methods:preserved,main_and_existing_scenes_unchanged:!changed.some(p=>p.endsWith('.tscn')),protected_sources_byte_identical:changed.every(p=>allowed.includes(p)),new_production_source:'Juego/scripts/juego/character_surface_6.gd',recovery_files:manifest.files.length};
fs.writeFileSync(path.join(out,'source_audit.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report,null,2));
const before=JSON.parse(fs.readFileSync(path.join(out,'before_performance.json'))),after=JSON.parse(fs.readFileSync(path.join(out,'after_performance.json')));
const median=a=>{const b=a.slice().sort((a,b)=>a-b);return(b[44]+b[45])/2;};
const stats=a=>Object.fromEntries(['ms','fps','draw_calls','primitives'].map(k=>[k,median(a.samples.map(s=>s[k]))]));
const perf={method:'Isolated rendered studio, same scene/camera/FOV45/resolution/seed600; 1.5s warm-up and 90 frame-post-draw intervals. Existing idle animation and LOD logic; no campus or shadows. 75 FPS plateau, no evidence of higher FPS. Native primitives counter, not independent triangle capture.',pairs:before.map((b,i)=>({npc:b.npc,actors:b.npc+1,before:stats(b),after:stats(after[i])}))};
fs.writeFileSync(path.join(out,'performance_comparison.json'),JSON.stringify(perf,null,2));
