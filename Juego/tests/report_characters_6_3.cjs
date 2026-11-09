const fs=require('fs'),path=require('path');
const project=path.resolve(__dirname,'..'),dir=path.join(project,'reports/characters_6_3');
const read=name=>JSON.parse(fs.readFileSync(path.join(dir,name),'utf8'));
const inventory=read('inventory_runtime.json'),coverage=read('batch3_coverage.json');
const checks=[];
for(const row of coverage.filter(x=>Object.keys(x.remodel||{}).length)){
 checks.push({path:row.path,id:row.id,rig:row.bone_count===53,skin:row.mesh_skin_valid===true,
  finite:Object.keys(row.poses||{}).length===6&&Object.values(row.poses||{}).every(p=>Object.keys(p).length===5&&Object.values(p).every(b=>b.finite===true))});
}
const summary={generated_at:new Date().toISOString(),batch:3,inventory_count:inventory.length,
 remodelled:checks.length,checks,dialogue:read('batch3_dialogue.json'),
 performance_gate:{passed:false,reason:'30 NPC: frame time and video memory still exceed the previous representation; batches 4-7 remain disabled.'}};
fs.writeFileSync(path.join(dir,'resume_validation.json'),JSON.stringify(summary,null,2));
// Search all production scene/script sources, including secondary scenes and scripted factories.
const sources=[];
function walk(folder){for(const e of fs.readdirSync(folder,{withFileTypes:true})){
 if(['.godot','addons','assets','reports','tests'].includes(e.name))continue;
 const file=path.join(folder,e.name);if(e.isDirectory())walk(file);
 else if(/\.(gd|tscn)$/.test(file)){
  fs.readFileSync(file,'utf8').split(/\r?\n/).forEach((line,i)=>{
   if(/student_visual\.gd|humanoid\.gd|digital_model\(|npc\.gd|campus_enemy\.gd|CharacterBody3D\.new/.test(line))
    sources.push({file:path.relative(project,file).replaceAll('\\','/'),line:i+1,source:line.trim()});
  });
 }
}}
walk(project);fs.writeFileSync(path.join(dir,'character_factories.json'),JSON.stringify(sources,null,2));
const esc=x=>String(x??'').replaceAll('|','/').replaceAll('\n',' ');
const table=inventory.map(row=>{
 const current=coverage.find(x=>x.path===row.path),id=current?.id||row.profile?.visual_id||row.npc_id||row.path.split('/').at(-2);
 const role=current?.role||row.profile?.role||'Sin clasificar; conservar';
 const isPlayer=row.script?.endsWith('/player.gd');
 const status=isPlayer?'Protagonista 6.2 + pies 6.3':Object.keys(current?.remodel||{}).length?'Humano 6.3, lote 3':'Visual anterior / excluido';
 const floor=row.floor===0?-1:row.floor;
 return `| ${floor} | ${esc(id)} | ${esc(role)} | ${esc(row.path)} | ${status} | ${esc(row.interaction)} |`;
}).join('\n');
const before=read('benchmark_resume_before.json'),after=read('benchmark_resume_optimized.json');
const bench=[1,5,15,30].map(count=>{
 const old=after.find(x=>x.count===count&&x.variant==='before'),prior=before.find(x=>x.count===count&&x.variant==='after'),now=after.find(x=>x.count===count&&x.variant==='after');
 return `| ${count} | ${old.median_ms.toFixed(3)} | ${prior.median_ms.toFixed(3)} | ${now.median_ms.toFixed(3)} | ${now.fps_from_median.toFixed(1)} | ${now.draw_calls} | ${(now.video_memory/1048576).toFixed(1)} |`;
}).join('\n');
const text=`# DuocGames 6.3 — estado real y continuación del 6 de noviembre

**Entrega parcial, con expansión detenida por rendimiento.** Los pies y los pilotos ya estaban implementados al retomar. Se conservaron; no se rehízo 6.2. La configuración real sigue en lote 3. No se afirma que todos los personajes estén remodelados.

## 1. Recuperación y alcance

Se verificó el commit c7ea875 del protagonista 6.2 y el checkpoint existente recovery/characters_6_3/checkpoint.json. Antes de esta continuación se copiaron los scripts visuales, configuración y benchmark a recovery/characters_6_3_resume_20261106_122113. El árbol e índice Git ya contenían numerosos cambios ajenos; no se hizo reset, commit general ni push.

Se utilizó Godot MCP Toolkit mediante tests/visual_mcp_5.cjs, puente oficial con GODOT_MCP_PROJECT_PATH apuntando a Juego. El conector directo buscaba erróneamente Aethergate y devolvía AUTH_FAILED. No se modificó el controlador ni la física.

## 2. Causa de los pies y corrección conservada

El retargeting anterior aplanaba el segmento tobillo-dedos, que en bind pose desciende. Eso inclinaba la suela. human_student_6_2.gd conserva ahora únicamente su rumbo horizontal para calcular la orientación. Además algunas superficies decorativas visibles están por encima de su colisión; character_ground_6_3.gd mide esas superficies para corregir solo la representación.

Comparar before_feet.json / after_feet.json y before_overlap_surface.json. La cápsula, escala física, velocidades y controlador no se alteran para compensar el defecto.

## 3. Calzado e integración

character_footwear_6_3.gd ya contiene zapatillas de geometría modelada por secciones: puntera redondeada, cubierta, suela, talón, lengüeta y cordones. Tres superficies y skin con cuatro binds foot_l/ball_l/foot_r/ball_r. Se oculta el calzado importado anterior y se recorta la parte cubierta de los pies; el original permanece recuperable.

La corrección visual de apoyo incluye solución de pierna y apoyo temporal, limitado por alcance. No equivale a una certificación de ausencia de sliding en toda la campaña. feet_gate.json registra las pruebas anteriores, incluidas escaleras y ascensor; no se presentan como ejecutadas nuevamente en esta continuación.

## 4. Inventario y arquitectura

Se encontraron ${inventory.length} representaciones en Main instanciado, incluyendo modelos educativos activos y sus representaciones heredadas ocultas. No equivale a ${inventory.length} NPC únicos. [Inventario completo](reports/characters_6_3/inventory_runtime.json) conserva escena/nodo, scripts, perfiles, grupos e interacciones. [Fábricas y escenas secundarias](reports/characters_6_3/character_factories.json) recoge ${sources.length} referencias de producción, incluidas creación procedural, rescate, guardias, ambientación y simulaciones. Los casos sin clasificación siguen excluidos.

## 5. Personajes remodelados

${checks.length} representaciones tienen metadatos remodel63 y fueron comprobadas por el fixture de lote 3. Incluye pilotos Auxiliar/Estudiante y profesores/mentores elegibles; la tabla individual siguiente es la cobertura efectiva. Los NPC conservan su actor, ID, señales e interacción. No se crearon nuevos profesores ni se convirtieron mentores en combatientes.

## 6. Visuales conservados y lotes pendientes

Lotes 4–7 siguen pendientes: estudiantes ambientales de todos los niveles, funcionarios adicionales, humanos de encuentros y revisión independiente de especiales. Los enemigos digitales y bugs de misión no se convierten en humanos. Guardia/bibliotecaria y cualquier actor no elegible conservan su representación previa. No se activa un lote nuevo con la regresión actual de 30 NPC.

## 7. Rostros y cuerpos

human_npc_6_3.gd configura morphs de nariz, mandíbula, mentón, pómulos, ojos, labios, boca, orejas y frente, además de sexo/proporciones/edad moderados. La semilla procede del identificador estable, no de un sorteo por carga. Las variaciones se hornean una vez conservando pesos; no son solo colores de polera. Falta validar visualmente cada combinación y persistencia durante una sesión completa de guardado/carga.

## 8. Cabellos

Ocho recursos compartidos: short02, short04, bob02, long01, ponytail01, braid01, bob01 y afro01. Colores naturales del perfil y opción sin cabello. No se afirma que todos los peinados estén libres de intersecciones en todas las poses.

## 9. Ropa y accesorios

Recursos de polera, polerón, camisa, chaqueta y jeans. Se preservan mochila, lentes, credenciales y props funcionales/visuales de rol. En esta continuación se sustituyó la gabardina de Odontología por camisa clínica blanca: la captura anterior mostraba una prenda larga deformada con superposición. No se presenta esa camisa como bata médica nueva.

## 10. Animaciones y optimización

Se reutiliza el rig de 53 huesos con retargeting de los estados existentes; no se introduce IA. Cada actor necesita Skeleton3D independiente para su pose, mientras scripts, PackedScene, mallas base y materiales se comparten. Se generan LOD de malla y se reducen frecuencia, sombras y visibilidad según distancia/nivel; SLEEP del visual existente se conserva.

Cambio de esta continuación: actualización de rig NPC cercano a un máximo nominal de 30 Hz (antes sin límite), manteniendo 0,12 s a media distancia y 0,40 s lejos. El controlador, señales y animación funcional de ataques no se ralentizan: el límite afecta solo al modelo secundario.

## 11. Assets y licencias

Datos GLB de CharacterCreator/MakeHuman, Kasper Olesen/kblood. LICENSE-NOTES.md local declara CC0-1.0 para cuerpo, ropa, cabello, texturas y animaciones generadas con fuentes CC0. El generador tiene GPL separada; no se incorpora su código. Procedencia y hashes en assets/characters/shared_6_3/provenance.json y main_6_2/SOURCE.md. El calzado 6.3 es geometría creada para este proyecto. No se descargaron recursos nuevos en esta continuación.

## 12. Archivos modificados en esta continuación

- scripts/juego/npc_visual_6_3.gd: frecuencia visual y prenda de Odontología, editados mediante MCP script_edit; validación sin diagnósticos.
- tests/resume_6_3_edits.cjs y resume_6_3_jobs.json: registro de las ediciones MCP aplicadas (no reejecutar sobre spans ya cambiados).
- tests/report_characters_6_3.cjs: inventario de fábricas, comprobación de cobertura y este informe.
- reports/characters_6_3: nueva medición, cobertura y capturas actualizadas; se conserva before_resume_docente_odontologia_front.png.
- CHARACTERS_REMODEL_6_3.md: este informe.

Las modificaciones 6.3 previas estaban presentes al iniciar esta continuación; no se atribuyen como nuevas.

## 13. Capturas

- [Pies corregidos, costado](reports/characters_6_3/after_feet_idle_right.png), [frente](reports/characters_6_3/after_feet_idle_front.png), [antes](reports/characters_6_3/before_feet_idle_right.png).
- [Auxiliar](reports/characters_6_3/batch3_Auxiliar_front.png), [rostro del estudiante](reports/characters_6_3/batch3_Estudiante_face.png).
- [Odontología antes de continuar](reports/characters_6_3/before_resume_docente_odontologia_front.png), [Odontología actual](reports/characters_6_3/batch3_docente_odontologia_front.png).

Los PNG de Main se obtienen instanciando Main en NPCValidation63 con persistencia desactivada, cámaras de diagnóstico y actores congelados; no representan un recorrido manual de la campaña.

## 14. Rendimiento comparativo real

Benchmark63 ejecutado dos veces mediante MCP en esta continuación. Vsync desactivado, 180 muestras por caso, animación solicitada con delta fijo 1/60. FPS es 1000/mediana, no un promedio de FPS de campaña. Recursos de vídeo son el monitor del motor durante cada caso, con posible historial/caché; no memoria incremental exclusiva.

| NPC | Anterior ms | 6.3 sin límite ms | 6.3 a 30 Hz ms | FPS derivados | Draw calls 6.3 | Vídeo MiB 6.3 |
|---|---:|---:|---:|---:|---:|---:|
${bench}

[Medición antes](reports/characters_6_3/benchmark_resume_before.json), [medición optimizada](reports/characters_6_3/benchmark_resume_optimized.json). El coste sigue siendo importante: la optimización es parcial y NO habilita una remodelación masiva. Se mantiene el visual anterior para los lotes no activados.

## 15. Pruebas automáticas y visuales

MCP script_check aprobado para human_npc_6_3.gd, npc_visual_6_3.gd y npc_validation_6_3.gd. NPCValidation63 ejecutado nuevamente sobre Main. resume_validation.json comprueba rig de 53 huesos, skin asociado y transformaciones finitas en walk/run/crouch/attack/read/computer. Abrir diálogo del Auxiliar conserva exactamente [E] Hablar con Auxiliar y no acepta su misión. Estas comprobaciones de poses no prueban por sí solas ausencia de clipping.

Revisión visual de esta continuación: pies en captura cercana, defecto de prenda de Odontología y captura actual de esa docente tras terminar el fixture. La camisa ya no produce la falda larga deformada; todavía se necesita revisión de ropa clínica, manos y accesorios en movimiento. No se infiere aprobación artística general del mero éxito de skinning.

## 16. Pruebas pendientes

Recorrido completo con movimiento, cámaras, saltos, escaleras y ascensor; armas/inventario de todas las opciones; diálogos de cada NPC; misiones y preguntas completas; guardado/carga con servicios; estabilidad de apariencia en varias sesiones; benchmarking representativo con física e IA activas; revisión visual por lote y por nivel. No se probaron ni modificaron Supabase/login/roles/economía.

## 17. Problemas conocidos y cobertura por nivel/personaje

Regresión importante a 30 NPC, memoria de vídeo alta, prendas/accesorios aún sin revisión exhaustiva y visuales heredados excluidos o pendientes. El índice floor del fixture representa alturas de 12 m; se traduce 0 a -1 en la tabla. Las entradas ocultas históricas no son personajes adicionales ni se reubican por su temática.

| Nivel | Identificador | Rol | Nodo | Representación actual | Interacción |
|---|---|---|---|---|---|
${table}
`;
fs.writeFileSync(path.join(project,'CHARACTERS_REMODEL_6_3.md'),text);
console.log(JSON.stringify({inventory:inventory.length,remodelled:checks.length,failures:checks.filter(x=>!x.rig||!x.skin||!x.finite),sources:sources.length,performance_gate:false}));
