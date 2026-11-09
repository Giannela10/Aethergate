const fs=require('fs'),crypto=require('crypto'),path=require('path');
const out='Juego/reports/main_character_6_2/',assets='Juego/assets/characters/main_6_2/';
const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const files=['humanoid.gd','student_visual.gd','main_character_visual_6.gd','procedural_appearance_adapter.gd','character_appearance.gd'];
const audit=Object.fromEntries(files.map(f=>[f,hash('Juego/scripts/juego/'+f)===hash('recovery/main_character_6_2/Juego/scripts/juego/'+f)]));
audit['Main.tscn']=hash('Juego/Main.tscn')===hash('recovery/main_character_6_2/Juego/Main.tscn');
const before=fs.readFileSync('recovery/main_character_6_2/Juego/scripts/juego/player.gd','utf8');
audit.player_only_visual_preload_changed=before===fs.readFileSync('Juego/scripts/juego/player.gd','utf8').replace('main_character_visual_6_2.gd','main_character_visual_6.gd');
const mb=fs.readFileSync('recovery/main_character_6_2/Juego/scripts/campaign/appearance_menu.gd','utf8'),ma=fs.readFileSync('Juego/scripts/campaign/appearance_menu.gd','utf8');
audit.appearance_save_confirm_unchanged=mb.slice(mb.indexOf('func _confirm'))===ma.slice(ma.indexOf('func _confirm'));
fs.writeFileSync(out+'source_audit.json',JSON.stringify(audit,null,2));
let manifest=[];for(const folder of ['source','native'])for(const f of fs.readdirSync(assets+folder).filter(f=>/\.(glb|scn)$/.test(f)))manifest.push({file:folder+'/'+f,bytes:fs.statSync(assets+folder+'/'+f).size,sha256:hash(assets+folder+'/'+f)});
fs.writeFileSync(out+'local_assets_manifest.json',JSON.stringify(manifest,null,2));
const b=JSON.parse(fs.readFileSync(out+'before_metrics.json')),a=JSON.parse(fs.readFileSync(out+'after_metrics.json'));
const median=values=>{values.sort((x,y)=>x-y);const m=Math.floor(values.length/2);return values.length%2?values[m]:(values[m-1]+values[m])/2;};
const summary=x=>({vertices:x.vertices,surfaces:x.surfaces,frame_ms_median:median(x.samples.map(s=>s.ms)),draw_calls_median:median(x.samples.map(s=>s.draw_calls)),fps_monitor_median:median(x.samples.map(s=>s.fps))});
const perf={before_6_0:summary(b),after_6_2:summary(a),method:'90 frame_post_draw intervals in same Main wrapper, matched outfit/profile, same camera and frozen actors, GTX1050 Compatibility. 75Hz cap. FPS monitor includes startup history. No claim of full gameplay/GPU benchmark.'};
if(fs.existsSync(out+'before_animated_performance.json')&&fs.existsSync(out+'after_animated_performance.json')){
 perf.animated={};for(const phase of ['before','after']){const x=JSON.parse(fs.readFileSync(out+phase+'_animated_performance.json'));perf.animated[phase]={warmup_seconds:x.warmup_seconds,samples:x.samples.length,frame_ms_median:median(x.samples.map(s=>s.frame_ms)),process_ms_median:median(x.samples.map(s=>s.process_ms)),fps_monitor_median:median(x.samples.map(s=>s.fps)),draw_calls_median:median(x.samples.map(s=>s.draw_calls))};}perf.animated.method='Walk-in-place pose animated every frame in Main, 3-second warmup and 180 intervals, fixed campus entrance camera; NPC physics/process frozen; 75Hz cap. Includes visual animation cost, not full gameplay.';
}
fs.writeFileSync(out+'performance_comparison.json',JSON.stringify(perf,null,2));
let html='<!doctype html><meta charset="utf-8"><title>DuocGames 6.2 — evidencia</title><style>body{font:16px system-ui;background:#14202c;color:#edf3f7;margin:24px}section{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:24px}h2{grid-column:1/-1}img{width:100%}figure{margin:0}a{color:#8adacb}</style><h1>Protagonista 6.2</h1><p>Referencia suministrada por el usuario. Los ejemplos de animación de la referencia son ilustraciones, no pruebas del juego.</p><a href="reference.png"><img src="reference.png" style="max-width:1000px"></a>';
for(const angle of ['front','left','back','face','game_camera','walking_campus'])html+=`<section><h2>${angle}</h2><figure><a href="before_${angle}.png"><img src="before_${angle}.png"></a><figcaption>6.0 — visual anterior</figcaption></figure><figure><a href="after_${angle}.png"><img src="after_${angle}.png"></a><figcaption>6.2 — humano con skinning</figcaption></figure></section>`;
html+='<h2>Movimiento real, campus, equipamiento y personalización</h2>';
html+='<h2>Arranque directo de Main</h2><a href="main_direct.png"><img src="main_direct.png" style="max-width:1000px"></a>';
for(const f of fs.readdirSync(out).filter(f=>/^after_(live_|zone_|equipped|personalization)/.test(f)&&f.endsWith('.png')))html+=`<figure style="display:inline-block;width:48%;margin:1%"><a href="${f}"><img src="${f}"></a><figcaption>${f}</figcaption></figure>`;
fs.writeFileSync(out+'comparison.html',html);
console.log(JSON.stringify({audit,perf},null,2));
