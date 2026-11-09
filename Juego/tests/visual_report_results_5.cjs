const fs=require('node:fs'),path=require('node:path');
const project=path.resolve(__dirname,'..'),dir=path.join(project,'reports/visual_5'),file=path.join(project,'VISUAL_REMODEL_5_0.md');
let text=fs.readFileSync(file,'utf8').split('\n<!-- GENERATED_RESULTS -->')[0];
const metrics=JSON.parse(fs.readFileSync(path.join(dir,'performance_comparison.json'),'utf8'));
const fmt=n=>Number(n.toFixed(2));
const table=['| Mediana de las muestras comparadas | Antes | Después |','|---|---:|---:|',...Object.entries({fps:'FPS informados por Godot',frame_ms:'Tiempo de frame (ms)',draw_calls:'Draw calls',primitives:'Primitivas renderizadas'}).map(([key,label])=>`| ${label} | ${fmt(metrics.before[key])} | ${fmt(metrics.after[key])} |`),`| Luces habilitadas y con energía en el árbol completo | ${metrics.visible_lights_before} | ${metrics.visible_lights_after} |`].join('\n');
text=text.replace(/\| Mediana de las muestras comparadas \| Antes \| Después \|[\s\S]*?(?=\n\n)/,table);
const floor=id=>metrics.floors.find(f=>f.floor===id);
text=text.replace(/La mediana general de FPS fue[\s\S]*?(?=\n\nNo se tocaron)/,`La mediana general de FPS fue ${metrics.after.fps>metrics.before.fps?'mayor':'igual o menor'} en esta sesión; **no se demuestra una mejora estable de FPS**. El editor y las rutinas de NPC no son una carga perfectamente reproducible; el editor tenía Login abierto al inicio y Main en las comparaciones posteriores. Por tanto las muestras sirven como observación del recorrido, no como benchmark controlado. Pisos 2 y 3: ${fmt(floor(2).before.fps)}→${fmt(floor(2).after.fps)} y ${fmt(floor(3).before.fps)}→${fmt(floor(3).after.fps)} FPS; piso 1: ${fmt(floor(1).before.fps)}→${fmt(floor(1).after.fps)} FPS. El piso 4 registra ${fmt(floor(4).after.frame_ms)} ms por frame y sigue siendo un sector pesado. No se ocultan las variaciones ni se interpretan como una optimización garantizada.`);
text+='\n<!-- GENERATED_RESULTS -->\n\n## Resultados finales ejecutados\n\n| Prueba | Estado | Evidencia |\n|---|---|---|\n';
for(const group of ['regressions.json','access_regressions.json','rendered_regressions.json','final_regressions.json']){
 if(!fs.existsSync(path.join(dir,group)))continue;
 for(const row of JSON.parse(fs.readFileSync(path.join(dir,group),'utf8'))){text+=`| ${row.suite} | ${row.status} | Exit ${row.exit_code}; errores de motor ${row.engine_errors}; ${row.timeout?'TIMEOUT':(row.elapsed_ms/1000).toFixed(1)+' s'} |\n`;}
}
text+='\nLos PASS de guardado de nube y cola persistente usan fixtures: la base remota no se probó. Los PASS visuales automatizados se complementan con inspección de las capturas; no sustituyen una revisión humana de todo el campus.\n';
text+='\n## Capturas seleccionadas\n\n| Sector | Antes | Después |\n|---|---|---|\n';
for(const [label,id]of [['Vidrio y reflejos, piso 4','floor_4.0_room_028_south'],['Pizarra y armario, sala 810','floor_8.0_room_062_north']])text+=`| ${label} | ![Antes](reports/visual_5/before_${id}.png) | ![Después](reports/visual_5/after_${id}.png) |\n`;
text+='\nCartel de cafetería instalado, vista frontal posterior:\n\n![Cartel de cafetería](reports/visual_5/after_cafe_front.png)\n';
text+='\nSoporte de impresora (par adicional desde la misma cámara):\n\n| Antes | Después |\n|---|---|\n| ![Impresora sin apoyo](reports/visual_5/before_printer_support.png) | ![Impresora con mesa](reports/visual_5/after_stationery_free_view.png) |\n';
fs.writeFileSync(file,text);console.log('Updated VISUAL_REMODEL_5_0.md from executed results.');
