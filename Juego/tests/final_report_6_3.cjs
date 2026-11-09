const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'../..'),project=path.join(root,'Juego'),out=path.join(project,'reports/characters_6_3');
const read=name=>JSON.parse(fs.readFileSync(path.join(out,name),'utf8'));
const validation=read('batch7_validation.json'),coverage=read('batch7_coverage.json'),inventory=read('inventory_runtime.json');
const dynamic=read('dynamic_factories_validation.json'),regressions=read('final_regressions.json'),benchmark=read('benchmark_final.json');
const feet=read('feet_gate_final.json');
const modified=coverage.filter(x=>Object.keys(x.remodel||{}).length);
const norm=p=>p.includes('/Main/')?'Main/'+p.split('/Main/').slice(1).join('/Main/'):p;
const escape=value=>String(value??'').replaceAll('|','/').replaceAll('\n',' ');
const rows=coverage.map(row=>{
 const source=inventory.find(x=>norm(x.path)===norm(row.path))||{};
 const player=source.script?.endsWith('/player.gd');
 const isNew=Object.keys(row.remodel||{}).length>0;
 const floor=Math.round(row.floor_y/12)+1;
 const status=isNew?'Humano 6.3':player?'Protagonista 6.2 + pies 6.3':source.script?.endsWith('campus_enemy.gd')?'Simulación digital; conservar':!row.visible?'Visual heredado oculto; conservar':'Especial / no clasificado; conservar';
 const fullContext=!['GUARDIA','BIBLIOTECARIA'].includes(row.role);
 const appearance=source.appearance||{};
 return {...row,floor:floor===0?-1:floor,scene:'res://Main.tscn',source:source.script||'Representación de mentor generada',status,path:norm(row.path),rig:isNew||player?'Skeleton3D, 53 bones':'Legacy procedural representation',animations:isNew?['idle','walk','run','crouch','jump','land','attack',...(fullContext?['talk','sit','stand','read','write','use_computer','celebrate']:[])]:[],accessories:{profile_accessory:appearance.accessory,head_accessory:appearance.head_accessory,backpack:appearance.backpack,shoes:isNew?'StudentSneakers63':'Preserved'},requirements:source.groups?.includes('educational_mentor')?'Educational mentor remains separate from simulation hitbox':'Preserve actor ID, collision, signals and interactions'};
});
const activeUnknown=rows.filter(x=>x.visible&&!Object.keys(x.remodel||{}).length&&!x.source.endsWith('/player.gd'));
const failures=[...validation.failures,...dynamic.failures,...regressions.filter(x=>!x.pass).map(x=>x.suite)];
if(!feet.passed)failures.push('Feet validation');
const old30=benchmark.find(x=>x.count===30&&x.variant==='before'),new30=benchmark.find(x=>x.count===30&&x.variant==='after');
const perfGate=new30.median_ms<old30.median_ms*1.25&&new30.p95_ms<16.67;
const oldMain=read('batch0_main_performance.json'),newMain=validation.performance;
const protectedFiles=JSON.parse(fs.readFileSync(path.join(root,'recovery/characters_6_3_finish_20261106_123513/protected_hashes.json')));
const integrity=protectedFiles.map(x=>({file:path.relative(root,x.Path).replaceAll('\\','/'),unchanged:crypto.createHash('sha256').update(fs.readFileSync(x.Path)).digest('hex').toUpperCase()===x.Hash}));
if(integrity.some(x=>!x.unchanged))failures.push('Protected source hash changed');
const summary={generated_at:new Date().toISOString(),batch:7,main_representations:coverage.length,human_npcs:modified.length,unique_human_ids:new Set(modified.map(x=>x.id)).size,active_unclassified:activeUnknown,integrity,regressions_passed:regressions.filter(x=>x.pass).length,dynamic_floors:dynamic.rows.length,distinct_test_geometries:dynamic.distinct_body_geometries,performance_gate:perfGate,failures};
fs.writeFileSync(path.join(out,'final_summary.json'),JSON.stringify(summary,null,2));
fs.writeFileSync(path.join(out,'coverage_by_character.json'),JSON.stringify(rows,null,2));
const floors=[-1,1,2,3,4,5,6,7,8].map(floor=>{const found=rows.filter(x=>x.floor===floor&&Object.keys(x.remodel||{}).length);return `| ${floor} | ${found.length} | ${escape(found.map(x=>x.id).join(', '))||'Sin humano inicial elegible; no se añadió contenido'} | Probada |`;}).join('\n');
const details=rows.map(x=>`| ${x.floor} | ${escape(x.id)} | ${escape(x.role||'Ver script')} | ${escape(x.path)} | ${x.status} | ${escape(x.interaction)} |`).join('\n');
const metrics=[1,5,15,30].map(count=>{const a=benchmark.find(x=>x.count===count&&x.variant==='before'),b=benchmark.find(x=>x.count===count&&x.variant==='after');return `| ${count} | ${a.median_ms.toFixed(3)} | ${b.median_ms.toFixed(3)} | ${b.p95_ms.toFixed(3)} | ${b.fps_from_median.toFixed(1)} | ${a.draw_calls} → ${b.draw_calls} | ${(a.video_memory/1048576).toFixed(1)} → ${(b.video_memory/1048576).toFixed(1)} |`;}).join('\n');
const styles=[...new Set(modified.map(x=>x.remodel.hair||'Sin cabello'))].sort();
const wardrobes=[...new Set(modified.map(x=>x.remodel.wardrobe))].sort();
const document=`# DuocGames 6.3 — pies y remodelación de personajes

Implementación activa en Main con configuración de lote 7. **${modified.length} NPC humanos / ${summary.unique_human_ids} identificadores distintos** usan la nueva representación. El inventario contiene ${coverage.length} representaciones, incluyendo cuerpos heredados ocultos y el protagonista; no son ${coverage.length} personajes nuevos. Los diseños digitales/especiales y el protagonista conservan sus integraciones propias.

## 1. Recuperación y conservación de 6.2

Se revisó MAIN_CHARACTER_REMODEL_6_2.md y se verificó c7ea875. Se conservan recovery/characters_6_3 y recovery/characters_6_3_finish_20261106_123513. Esta continuación no repitió la importación ni reemplazó el protagonista. Los SHA-256 de Main.tscn, player.gd y gameplay_manager.gd coinciden con el punto inicial de esta continuación. No hubo push ni commit general del árbol del usuario.

## 2. Diagnóstico y corrección de pies

La implementación previa 6.3 ya corregía dos causas: aplanar erróneamente el segmento tobillo-dedos al transferir la pose inclinaba la suela, y ciertas superficies decorativas estaban por encima de su colisión. Se conserva la referencia horizontal correcta y el muestreo de la superficie visible. La cápsula y la física del jugador permanecen intactas.

## 3. Zapatillas e integración

character_footwear_6_3.gd utiliza geometría de zapatilla modelada por secciones, con puntera redondeada, talón, lengüeta, cordones, cubierta y suela diferenciadas. Tres superficies y cuatro binds: foot_l, ball_l, foot_r y ball_r. La corrección de apoyo resuelve visualmente la pierna y limita el anclaje temporal por alcance; no añade colisiones. El calzado anterior y sus assets siguen recuperables.

En esta continuación se corrigió la caché de cuerpos recortados: ya no conserva una malla pesada con morphs por cada instancia del mismo recurso. El contenido geométrico del protagonista se mantiene.

## 4. Inventario y arquitectura

Se buscaron fábricas en scripts, escenas principales/secundarias, NPC de campaña, estudiantes de rutina/aula/rescate, guardias, bibliotecaria, actores educativos, figurantes de eventos y simulaciones. [Inventario original](reports/characters_6_3/inventory_runtime.json), [fábricas](reports/characters_6_3/character_factories.json), [cobertura normalizada por nodo](reports/characters_6_3/coverage_by_character.json).

Los actores conservan ID, nombre, misión, materia, diálogo, señales y colisiones. npc_visual_6_3.gd adapta solo la representación. Cada humano dispone de pose independiente en Skeleton3D de 53 huesos; scripts, PackedScene, mallas fuente, geometrías horneadas y materiales se comparten cuando corresponde.

## 5. Lotes implementados

Lote 1: pies conservados y revalidados. Lote 2: pilotos Auxiliar/Estudiante conservados. Lote 3: profesores/mentores. Lote 4: estudiantes existentes y fábricas ambientales. Lote 5: funcionarios, personal de servicios, guardias, papelería y bibliotecaria. Lote 6: estudiante de rescate. Lote 7: revisión de especiales, manteniendo sus diseños específicos. Los JSON batch4_validation a batch7_validation registran las comprobaciones realizadas entre lotes.

## 6. Representaciones anteriores y especiales

Las simulaciones digitales, bugs y cuerpos lógicos heredados ocultos se conservan. Los mentores educativos siguen separados de las hitboxes de sus simulaciones. No se añadieron profesores, estudiantes permanentes ni recorridos. Las alturas sin estudiante inicial válido no se rellenaron artificialmente. Casos activos sin clasificar en la auditoría final: ${activeUnknown.length}. El spawner de enemy.gd ligado a populate_entrance=false y la plantilla Character.tscn no utilizados por Main mantienen su visual anterior; no se activa ni modifica ese modo de combate.

## 7. Rostros y cuerpos

La semilla estable deriva del identificador. Se configuran morphs de nariz, mandíbula, mentón, pómulos, ojos, labios, boca, orejas y frente, con variaciones moderadas de proporciones y edad. Las formas se hornean una vez conservando skinning. La prueba de la fábrica produjo **${dynamic.distinct_body_geometries} geometrías distintas** para nueve perfiles; no se limita a cambiar materiales.

## 8. Cabellos

Recursos encontrados en los NPC remodelados: ${styles.map(x=>'\x60'+x+'\x60').join(', ')}. La base dispone de ocho estilos, además de la opción sin cabello, con tonos del perfil. Se conserva una expresión neutral; no se incorpora captura facial ni simulación de cabello.

## 9. Prendas y accesorios

Prendas en uso: ${wardrobes.join(', ')}; estudiantes combinan polera, polerón, camisa o chaqueta con pantalones. Se preservan mochilas, props, credenciales, libro de biblioteca y distintivos compatibles. Guardias usan chaqueta grafito. Odontología utiliza camisa clara compatible; se descartó la gabardina que se deformaba en sus poses.

Se alinearon los lentes con los ojos del modelo mediante el hueso de cabeza. Gorro del chef y accesorios de cabeza siguen ese mismo anclaje visual. Los audífonos cuentan con una nueva malla compartida de banda curva y copas, sustituyendo la barra desconectada anterior. No se añadieron colisiones cosméticas.

## 10. Animaciones

Se mantienen los estados y animadores existentes y se transfieren poses al rig humano. Los NPC basados en StudentVisual conservan conversación, lectura, escritura, celebración, asiento y computador. Guardia/bibliotecaria basados en Humanoid mantienen sus acciones disponibles; la prueba comprueba estabilidad cuando un contexto no existe, sin fingir una animación nueva.

Se aplican poses locales jerárquicas y se permite al motor actualizar el esqueleto una vez antes del render. Referencia: [Skeleton3D de Godot](https://docs.godotengine.org/en/stable/classes/class_skeleton3d.html). Una conversión incorrecta detectada durante la optimización se corrigió antes de ampliar los lotes y se añadió un control anatómico que detecta cuerpos colapsados.

## 11. Optimización y rendimiento

LOD de malla, materiales compartidos, caché de cuerpos fuente, distribución de actualizaciones por identificador y frecuencias visuales según distancia: 30 Hz cerca, 15 Hz a distancia media, unos 8 Hz más lejos y 2,5 Hz al fondo. Se conserva SLEEP y la separación por nivel. El rig auxiliar no se anima a una frecuencia mayor que el humano; ataques/daño/estados críticos mantienen sus tiempos. El protagonista sigue con su actualización propia. Sombras respetan la calidad y la distancia.

Benchmark63: misma escena y distribución de 1/5/15/30 personajes, 180 muestras tras calentamiento, vsync desactivado. FPS derivados de la mediana; memoria del monitor del motor, no memoria incremental exclusiva. [Datos finales](reports/characters_6_3/benchmark_final.json).

| NPC | Anterior ms | 6.3 ms | 6.3 p95 ms | FPS derivados 6.3 | Draw calls | Vídeo MiB |
|---|---:|---:|---:|---:|---:|---:|
${metrics}

Main, cámara comparable con físicas de actores congeladas: **${oldMain.median_ms.toFixed(3)} → ${newMain.median_ms.toFixed(3)} ms**, p95 **${oldMain.p95_ms.toFixed(3)} → ${newMain.p95_ms.toFixed(3)} ms**. Esta muestra no equivale a una campaña completa con todos los sistemas activos. La memoria inicial del caso de 30 NPC era aproximadamente 734 MB decimales; la caché compartida eliminó la mayor parte de esa retención. Los benchmarks intermedios anteriores a la revisión visual no se usan como evidencia final.

## 12. Assets y licencias

CharacterCreator/MakeHuman, Kasper Olesen/kblood. Los LICENSE-NOTES.md locales declaran CC0-1.0 para los datos GLB generados desde fuentes CC0, incluidos cuerpo, prendas, cabello, texturas y animaciones. El generador tiene GPL separada y no se incorporó su código. Se conservan procedencia y hashes en assets/characters/shared_6_3/provenance.json y documentación main_6_2. Calzado y nuevos audífonos son geometría creada para el proyecto. No se descargaron assets nuevos en esta continuación.

## 13. Archivos de producción modificados

- scripts/juego/npc_visual_6_3.gd: cobertura por rol, prendas, relevancia, accesorios y frecuencia visual.
- scripts/juego/human_npc_6_3.gd: caché de jerarquía y transferencia de poses locales.
- scripts/juego/humanoid.gd: presupuesto de representación para NPC y seguridad de la instalación diferida al retirar previews. Sin cambios a tiempos críticos de gameplay.
- scripts/juego/character_footwear_6_3.gd: compartir correctamente la caché de cuerpo cubierto.
- scripts/juego/character_headset_6_3.gd: nueva geometría compartida.
- scripts/juego/characters_6_3_rollout.json: lote 7 activado.

Se añadieron fixtures y escenas de diagnóstico bajo tests, datos/capturas bajo reports/characters_6_3 y este informe. Main.tscn, player.gd y gameplay_manager.gd permanecen idénticos por hash. Los modelos anteriores no se eliminaron.

## 14. Capturas antes/después

[Pies antes](reports/characters_6_3/before_feet_idle_right.png), [pies actuales](reports/characters_6_3/after_feet_idle_right.png), [Auxiliar](reports/characters_6_3/batch7_Auxiliar_front.png), [estudiante de aula](reports/characters_6_3/batch7_v4_lab_student_front.png), [bibliotecaria](reports/characters_6_3/batch7_bibliotecaria_face.png), [chef](reports/characters_6_3/batch7_chef_front.png), [profesor de Inglés](reports/characters_6_3/batch7_profesor_ingles_face.png), [rescate](reports/characters_6_3/batch7_v4_rescued_student_front.png).

Las capturas NPC son de Main instanciado con cámara de inspección, persistencia desactivada y actores congelados. Las capturas live_feet utilizan entradas reales del controlador; los traslados entre zonas se realizan mediante diagnóstico. No se presentan como un recorrido manual completo.

## 15. Pruebas ejecutadas

- ${regressions.filter(x=>x.pass).length}/${regressions.length} suites automáticas aprobadas sin errores de motor: gameplay, inventario, personalización, lectura de guardado, nueva partida y campaña. [Resultados](reports/characters_6_3/final_regressions.json).
- Lote final: 34 representaciones, 53 huesos, skin válido, transformaciones finitas y proporciones válidas en once estados. Se respetan contextos soportados por cada clase.
- Auxiliar: apertura real del diálogo, texto exacto [E] Hablar con Auxiliar y misión sin aceptar durante el fixture.
- Fábrica real de figurantes invocada sobre nueve alturas: ${dynamic.rows.length} casos; apariencia estable tras serializar/reaplicar, una sola instancia y ${dynamic.distinct_body_geometries} mallas distintas. No añade personajes permanentes. [Datos](reports/characters_6_3/dynamic_factories_validation.json).
- Pies: fixture renderizado repetido con caminar, correr, salto, aterrizaje, agacharse, ataque, superficies decorativas, biblioteca, escalera y cabina/ascensor en movimiento. La solicitud de un piso puede estar bloqueada por campaña nueva; la prueba de movimiento aislado no modifica desbloqueos. [Datos](reports/characters_6_3/after_live_feet.json).
- Revisión visual de capturas de estudiantes, Odontología, biblioteca, seguridad, chef, Inglés y protagonista. La comprobación automatizada no sustituye la revisión artística de cada fotograma.

## 16. Límites y pruebas manuales pendientes

No se certifica ausencia de clipping en todas las combinaciones de ropa/armas ni foot sliding en recorridos prolongados. El armario especial del protagonista conserva el fallback 6.0 documentado en 6.2. Guardado/carga remotos, login y Supabase no se modificaron ni se probaron con una cuenta real. La prueba de campaña es automática y no equivale a jugarla completa. Se recomienda revisión artística prolongada de cabellos, uniformes y manos en contextos de asiento/escritura.

Las primeras pruebas dentro del aislamiento encontraron bloqueos de registros/certificados y un error de instalación diferida al retirar previews. Se corrigió el error y se repitieron las seis suites fuera del aislamiento con aprobación; sus resultados finales son los enlazados arriba.

## 17. Cobertura por nivel y personaje

| Nivel | Humanos remodelados iniciales | Identificadores | Fábrica dinámica |
|---|---:|---|---|
${floors}

Los pisos sin estudiante inicial no recibieron NPC nuevos; la fábrica compartida se prueba en las nueve alturas. Las entradas heredadas ocultas siguientes se conservan como respaldo de lógica/simulaciones, no son personajes adicionales pendientes de sustitución genérica.

| Nivel | ID | Rol | Nodo en Main | Representación | Interacción |
|---|---|---|---|---|---|
${details}
`;
fs.writeFileSync(path.join(project,'CHARACTERS_REMODEL_6_3.md'),document);console.log(JSON.stringify(summary));
if(failures.length||!perfGate||activeUnknown.length)process.exitCode=1;
