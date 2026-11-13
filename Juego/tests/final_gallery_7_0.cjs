const fs=require('node:fs'),path=require('node:path');
const repo=path.resolve(__dirname,'../..');
const root=path.join(repo,fs.readFileSync(path.join(__dirname,'../reports/final_7_0/active_run.txt'),'utf8').trim());
const files=fs.readdirSync(root).filter(f=>f.endsWith('.png'));
const escape=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('"','&quot;');
const sequence=prefix=>files.filter(f=>new RegExp('^'+prefix+'_\\d{3}\\.png$').test(f)).sort();
const data={beforeWalk:sequence('before_walk'),afterWalk:sequence('verified_final_walk'),beforeRun:sequence('before_run'),afterRun:sequence('verified_final_run')};
const html=`<!doctype html><meta charset="utf-8"><title>DuocGames 7.0 · Evidencias reales</title>
<style>body{font:16px system-ui;background:#15202b;color:#eee;margin:24px}button,input{font:inherit}section{display:grid;grid-template-columns:1fr 1fr;gap:12px}img{max-width:100%;background:#283541}figure{margin:8px}figcaption{overflow-wrap:anywhere}#gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr))}a{color:#8bd6ff}</style>
<h1>DuocGames 7.0</h1><p>Capturas reales de Godot. La secuencia aislada traslada al actor y actualiza la animación sobre suelo físico; no demuestra por sí sola una ruta jugada. Las imágenes survey_game y route corresponden al controlador real.</p>
<button id="play">Pausar / reproducir</button> <label>Estado <select id="mode"><option>Walk</option><option>Run</option></select></label> <label>Fotograma <input id="frame" type="range" min="0" max="7" value="0"></label>
<section><figure><img id="before"><figcaption>Antes</figcaption></figure><figure><img id="after"><figcaption>Después</figcaption></figure></section>
<h2>Capturas por sector y pruebas</h2><label>Filtrar <input id="filter" placeholder="PisoMenos1, Casino, SalaEstudio1…"></label><div id="gallery"></div>
<script>const seq=${JSON.stringify(data)},files=${JSON.stringify(files)};let running=true;const frame=document.querySelector('#frame'),mode=document.querySelector('#mode');function draw(){for(const side of ['before','after'])document.getElementById(side).src=seq[side+mode.value][Number(frame.value)%seq[side+mode.value].length]}document.querySelector('#play').onclick=()=>running=!running;frame.oninput=draw;mode.onchange=draw;setInterval(()=>{if(running){frame.value=(Number(frame.value)+1)%8;draw()}},250);function gallery(){const q=document.querySelector('#filter').value.toLowerCase();document.querySelector('#gallery').innerHTML=files.filter(f=>f.toLowerCase().includes(q)&&!/^before_|^after_/.test(f)).map(f=>'<figure><a href="'+encodeURI(f)+'"><img loading="lazy" src="'+encodeURI(f)+'"></a><figcaption>'+f+'</figcaption></figure>').join('')}document.querySelector('#filter').oninput=gallery;draw();gallery();</script>`;
const target=path.join(root,'evidence_gallery_verified.html');
if(fs.existsSync(target))throw Error('Gallery already exists; preserve evidence.');
fs.writeFileSync(target,html);console.log(target);
