const fs=require('fs'),path=require('path'),crypto=require('crypto');
const project=path.resolve(__dirname,'..'),root=path.dirname(project),dir=path.join(project,'reports/capstone');
const read=p=>JSON.parse(fs.readFileSync(path.join(project,p),'utf8'));
const bank=read('resources/education/capstone_practice_bank.json'),teachers=read('reports/capstone/teachers_before.json');
const educational=read('reports/capstone/education_tests.json'),staff=read('reports/capstone/staff_tests.json'),auth=read('reports/capstone/auth_tests.json'),roles=read('reports/capstone/roles_tests.json'),general=read('reports/capstone/general_tests.json'),campus=read('reports/capstone/campus_tests.json'),feet=read('reports/characters_6_3/feet_gate_final.json'),demo=read('reports/capstone/demo_test.json');
const failures=[...educational.failures,...staff.failures,...auth.failures,...roles.failures,...campus.failures,...demo.failures,...general.filter(x=>!x.pass).map(x=>x.suite)];if(!feet.passed)failures.push('feet');
if(failures.length)throw Error('Do not close phase 3 while tests fail: '+JSON.stringify(failures));
const checkpoint=read('reports/capstone/checkpoint.json'),before=JSON.parse(fs.readFileSync(path.join(root,checkpoint.path,'checkpoint.json')));
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const source=before.files.map(row=>({file:row.file,sha256:hash(fs.readFileSync(path.join(project,row.file))),changed_from_recovery:row.sha256!==hash(fs.readFileSync(path.join(project,row.file)))}));
const changed=source.filter(x=>x.changed_from_recovery).map(x=>x.file);
fs.writeFileSync(path.join(dir,'phase3_source_manifest.json'),JSON.stringify({closed_at:new Date().toISOString(),checkpoint,files:source,changed_existing_files:changed,new_production_files:['scripts/education/local_practice_service.gd','resources/education/capstone_practice_bank.json','resources/education/capstone_authoring_informatica.json','resources/education/capstone_authoring_salud_matematicas.json','resources/education/capstone_authoring_ingles_etica.json','resources/education/capstone_authoring_comunicacion_general.json']},null,2));
const table=teachers.map(t=>{const profile=bank.mentors[t.id];const questions=profile?bank.questions.filter(q=>profile.question_ids.includes(q.id)):[];const subjects=[...new Set(questions.map(q=>bank.subjects.find(s=>s.id===q.subject_id).name))];return `| ${t.id} | ${t.floor} | ${subjects.join(', ')||'Sin asignatura formal asociada'} | ${t.configured_questions??'—'} / ${t.simulation_bank??'—'} | Desconocido: recuperación remota fallida | ${questions.length} / ${questions.filter(q=>q.active).length} | ${profile?'Práctica probada; publicación remota pendiente':t.id==='bibliotecaria'?'Quiz literario existente: 16 preguntas, 3 opciones; regresión aprobada':t.id==='Profesor'?'Misión de documentos, sin asignatura; conservado':'Rol especial/servicio, sin nuevo banco docente'} |`;}).join('\n');
fs.writeFileSync(path.join(dir,'teacher_inventory.json'),JSON.stringify(teachers.map(t=>({...t,local_practice_questions:bank.mentors[t.id]?.question_ids.length||0,local_active_questions:bank.mentors[t.id]?.question_ids.length||0,remote_total:null,remote_enabled:null,remote_source:'Supabase: DNS ENOTFOUND, not empty bank',interaction_system:t.id==='Profesor'?'Quest NPC dialogue':'Campaign Interactions → BossDuelController / MentorActivityV4',new_source:bank.mentors[t.id]?'res://resources/education/capstone_practice_bank.json':null})),null,2));
const subjectTable=bank.subjects.map(s=>{const q=bank.questions.filter(q=>q.subject_id===s.id);return `| ${s.code} · ${s.name} | ${s.floor} | ${s.code==='INF_GENERAL'?3:0} | ${s.code==='INF_GENERAL'?12:15} | ${q.length} | ${['easy','medium','hard'].map(d=>q.filter(x=>x.difficulty===d).length).join(' / ')} |`;}).join('\n');
const suiteTable=general.map(row=>`| ${row.suite} | ${row.pass?'APROBADA':'FALLIDA'} | ${row.errors.length} | ${row.warnings.length} | ${row.elapsed_ms} |`).join('\n');
const floorTable=campus.floors.map(row=>`| ${row.floor} | Sí / Sí | ${row.human_npcs} | ${row.fps_from_median.toFixed(1)} | ${row.median_ms.toFixed(2)} | ${row.p95_ms.toFixed(2)} | ${row.draw_calls} | [Captura](reports/capstone_capturas/piso_${row.floor}.png) |`).join('\n');
const report=`# DuocGames — pruebas del sistema educativo y del juego

Fecha de ejecución: 6 de noviembre de 2026 (America/Santiago). Cierre de fases 1–3: ${new Date().toISOString()}. Este informe precede a la auditoría Capstone. Resultados observados, sin certificar un despliegue remoto.

## Recuperación y alcance

Punto de recuperación: \`${checkpoint.path}\`, ${checkpoint.files} archivos, HEAD \`${checkpoint.head}\`. Manifiesto con SHA-256 y rutas relativas en \`reports/capstone/checkpoint.json\` y en el respaldo. No se reinició el árbol Git: ya tenía trabajo anterior. Sin push, sin cuentas reales modificadas, sin escrituras Supabase, sin cambios RLS. Las claves de configuración no se copiaron al informe.

Se inspeccionaron Main, escenas educativas, generadores de profesores, registros de mentores, servicios, recursos JSON y migraciones SQL. El inventario completo con rutas de actor, mentor y script está en [teacher_inventory.json](reports/capstone/teacher_inventory.json). No se asumió que los profesores eran hijos directos de Main. Las rutas procedurales se obtuvieron después de instanciar el campus.

## Estado previo y recuperación remota

La consulta pública de solo lectura falló con \`ENOTFOUND\`, también ejecutada fuera de la restricción de red del sandbox. Evidencia: [remote_readonly.json](reports/capstone/remote_readonly.json). No se conocen cantidades totales ni activas de producción, ni el esquema desplegado. Un fallo DNS **no demuestra ausencia de preguntas**. No se ejecutó login con cuentas ajenas ni se insertaron registros de prueba remotos.

Antes existían 3 preguntas de respaldo DEBUG en Informática General, un quiz literario de biblioteca de 16 preguntas y un recurso de 6 preguntas usado por simulaciones heredadas de Inglés. Tener ese recurso en una configuración de simulación no demuestra que un profesor tenga seis preguntas académicas publicadas. Los nueve docentes temáticos carecían de respaldo local específico utilizable en su actividad; la publicación remota permanece desconocida. El NPC genérico Profesor entrega documentos: no tiene asignatura y no se le inventó una.

## Inventario de profesores y otros actores revisados

En «config./sim.» se distingue la lista configurada en el actor del recurso de simulación; no equivale a una cantidad recuperada del servidor. Todos los bancos nuevos son locales, activos, de práctica explícita.

| ID | Piso | Asignaturas de práctica | Anterior config./sim. | Remoto total/activo | Local total/activo | Resultado |
|---|---:|---|---|---|---|---|
${table}

No se encontraron profesores adicionales de Mecánica, Soldadura o Doctrina con banco académico asignado en los registros/actores inspeccionados. La temática de un piso y sus carteles no prueban la existencia de un docente. Punto Estudiantil, Chef, Bibliotecaria y NEXO conservan su identidad; no se convirtieron en profesores nuevos.

## Preguntas incorporadas realmente

[Banco ejecutable](resources/education/capstone_practice_bank.json): **150 preguntas únicas**, 147 originales agregadas y 3 reutilizadas del respaldo anterior. Diez áreas locales; las nueve asignaturas de docentes y el área general existente. Los campos siguen el formato de LearningActivity: id, subject_id, unit, kind, prompt, content.options, answer, explanation, difficulty, active, access_challenge y mentor_id. Cuatro alternativas distintas y una clave por pregunta. Los UUID locales son deterministas y no se atribuyen a filas remotas. Se usa \`BASE_DATOS\`, el código real del seed SQL.

| Código y asignatura | Piso | Anteriores locales reutilizadas | Agregadas | Disponibles/activas | Fácil / media / difícil |
|---|---:|---:|---:|---:|---|
${subjectTable}

Coordinación reutiliza 15 referencias de las asignaturas: 5 fáciles, 5 medias y 5 difíciles. Director reutiliza 15 referencias avanzadas, cinco difíciles de Bases de Datos, Algoritmos y Redes. No son asignaturas nuevas ni copias de filas. Se mantienen requisitos de sus simulaciones; practicar está disponible sin falsificar un pase.

El respaldo DEBUG \`demo_questions.json\` también pasó de 3 a 15 conservando las tres originales: así la ruta existente de Informática General utiliza el contenido. El servicio de acceso de una exportación no DEBUG mantiene su política previa de entrenamiento público sin clave; no se amplió el acceso oficial ni se cambió su guardia. Los nueve docentes temáticos usan el banco nuevo desde su opción **ACTIVIDAD DEL DOCENTE → PRÁCTICA LOCAL** también mediante el servicio dedicado. El panel no necesita estar conectado para esta práctica.

El generador \`tests/build_capstone_bank.cjs\` se ejecutó dos veces; la segunda informó \`unchanged_on_repeat: true\`. Solo regenera los archivos locales propios. No elimina preguntas de docentes ni aplica SQL. Los archivos \`capstone_authoring_*.json\` son las fuentes editables; el banco generado es el recurso utilizado en juego.

**Publicadas en Supabase durante esta tarea: 0.** [publication_pending.json](reports/capstone/publication_pending.json) registra los IDs locales y la asociación remota pendiente. Antes de publicar se requiere staging autorizado, UUID reales de asignaturas, propietario docente y reglas mentor/piso verificadas; los desafíos integradores cruzan asignaturas y no deben clonarse ciegamente para eludir esas reglas.

Contenido original de práctica, sin atribución al programa oficial de Duoc UC ni validación docente aún. Salud usa principios generales de bioseguridad y comunicación, no recomendaciones individuales ni reemplazo de protocolos clínicos. Referencias para revisión: [OMS, higiene de manos](https://www.who.int/publications/m/item/five-moments-for-hand-hygiene), [CDC, precauciones odontológicas](https://www.cdc.gov/dental-infection-control/hcp/summary/standard-precautions.html), [PostgreSQL, transacciones](https://www.postgresql.org/docs/current/tutorial-transactions.html), [ACM, ética profesional](https://www.acm.org/binaries/content/assets/about/acm-code-of-ethics-and-professional-conduct.pdf). Estas referencias no son un aval institucional.

## Pruebas educativas ejecutadas — fase 2

Godot MCP abrió escenas de prueba que instancian Main y sus componentes reales. Campaña y credencial con persistencia deshabilitada en estas escenas; las pruebas de escritor de guardado usan archivos temporales. No se alteran partidas reales. Los casos automatizados relocalizan al jugador para cubrir todos los profesores: esto no certifica un recorrido manual continuo de los nueve pisos.

| Evidencia | Resultado real | Límite |
|---|---|---|
| [education_tests.json](reports/capstone/education_tests.json) | ${educational.checks} comprobaciones; 150 preguntas; 11 docentes; 33 respuestas por UI; 0 fallos | Proyección local y campaña aislada, sin sesión remota |
| [staff_tests.json](reports/capstone/staff_tests.json) | ${staff.checks} comprobaciones; creación, edición, activación, desactivación, vista estudiante, recuperación de fallo temporal, permisos | Paneles reales contra backend simulado en memoria; no prueba RLS desplegada |
| [auth_tests.json](reports/capstone/auth_tests.json) | ${auth.checks} comprobaciones, 0 fallos | Adaptadores reales con transporte/sesiones aislados; Google/login real pendientes |
| [roles_tests.json](reports/capstone/roles_tests.json) | ${roles.checks} comprobaciones, 0 fallos | Modelo de políticas independiente y SQL estático; sin privilegios reales modificados |

Para **cada uno de los 11 docentes**: piso y actor; acercamiento seguro; visibilidad del prompt; diálogo; botón de actividad; cuatro alternativas; tres preguntas sucesivas (incorrecta y correctas); explicación; cierre; reapertura sin repetición prematura; acceso después de simulación completada; selección del mentor trasladado; ausencia de recompensa/pase oficial. Las 150 preguntas se evaluaron por clave, se rechazaron índice inválido y reenvío del ticket. Por cada área se probó respuesta incorrecta, banco vacío, registro malformado y rechazo de uso local como validación de misión. Se comprobó que una pared real continúa bloqueando la interacción.

Guardado educativo: serialización y migración real conservaron las 33 respuestas como práctica. La suite de integración prueba además el escritor local real con archivo temporal. La práctica nueva no completa misiones verificadas ni genera desbloqueos oficiales: esa separación es una condición aprobada, no una omisión simulada como éxito de campaña. Las misiones de campaña y recompensas idempotentes se ejercitaron en regresiones independientes.

Panel docente: login/modelo de rol, asignaturas, CRUD no destructivo, preview y cambios reflejados en estudiante aprobados en fixture. Panel administrador: asignación docente/asignatura y gestión entre áreas aprobados en fixture. Rol de estudiante y docente sin asignación rechazados. **El panel actual no ofrece borrado físico**; no se inventa una prueba de eliminación. Se retiraron únicamente registros del fixture al finalizar; 0 preguntas reales eliminadas.

## Correcciones funcionales acotadas

1. Se añadió un servicio local explícito con validación de datos y tickets consumibles. Un registro incompleto provocaba acceso a un campo inexistente; ahora se descarta y se devuelve error controlado. La prueba de datos inválidos pasó después de corregirlo.
2. La selección de docentes chocaba con el cuerpo lógico de su propia simulación, aunque el mentor visible estaba delante. El raycast educativo excluye únicamente ese cuerpo asociado y al jugador; las paredes siguen bloqueando. Rango y orientación usan el mentor visible, incluida su posición posterior al encuentro. No se modificó el controlador del protagonista.
3. Redes y Director conservan conversación y práctica después de completar su simulación. Coordinación y Director ofrecen práctica cuando faltan requisitos de acción sin levantar esos requisitos. No cambian daño, vida ni recompensas.
4. La propiedad enum de la bibliotecaria se normalizó de \`duel_type = 1.0\` a \`duel_type = 1\`: la representación decimal se perdía al recargar/guardar en el editor y activaba COMBAT por defecto. Se observó el fallo y se restauró QUIZ mediante MCP; la regresión completa de campaña aprobó después. Main solo difiere del respaldo en esta línea.
5. El código de asignatura nuevo se alineó al seed existente \`BASE_DATOS\`. Las pruebas antiguas que asumían siempre A/B se adaptaron a seleccionar la clave del registro emitido y una alternativa distinta para el caso incorrecto, manteniendo las mismas aserciones de evaluación y guardado.

## Pruebas generales ejecutadas — fase 3

| Suite headless | Estado final | Errores | Avisos | Duración de proceso ms |
|---|---|---:|---:|---:|
${suiteTable}

16/16 suites aprobadas al cierre. Los cuatro avisos de \`guardado_lectura\` son casos deliberados de JSON corrupto/no objeto y recuperación con copia; no son errores inesperados de una partida normal. Los mensajes/resultados completos permanecen en \`reports/capstone/general_*_process.log\`. El fallo inicial de biblioteca fue real y no se contó como aprobado hasta repetir la prueba corregida.

Cobertura: inicio de Main, guía y pausa, controlador y estados de movimiento, cámara y componentes, interacción E, recogibles e inventario, equipo/armas, simulaciones, misiones secundarias, progresión, accesos, objetos de misión, nueva partida, lectura/escritura local y migración, muerte/reaparición, premios no duplicados, organización de 596 rutas de piso, Director y NEXO. Las pruebas headless funcionales no prueban calidad de iluminación ni rendimiento gráfico.

[feet_gate_final.json](reports/characters_6_3/feet_gate_final.json): 19 comprobaciones aprobadas tras nueva ejecución de Feet63. Movimiento por Input real, salto, aterrizaje, caminar/correr, agacharse, ataque, subida de escalera y desplazamiento de cabina. La cabina móvil usa la fixture visual documentada cuando una campaña nueva aún no autoriza el destino; no se presenta eso como prueba de todos los desbloqueos de ascensor. No certifica todos los trayectos o ausencia absoluta de deslizamiento de pies.

### Nueve niveles: observación y rendimiento actual

Main instanciado, física de actores activa, cámara fija de inspección, 1,2 segundos de asentamiento por piso; 60 fotogramas de calentamiento y 120 medidos; VSync desactivado; GL Compatibility, ventana 1152×648. El director de población se suspendió para estabilizar la muestra; el guardia de acceso se suspendió solo dentro de esta fixture de diagnóstico para relocalizar la cámara/jugador. No es un cambio de producción. La cuenta de humanos indica visuales remodelados registrados en cada altura; no todos aparecen simultáneamente en pantalla.

| Piso | Escena / suelo con colisión | Humanos registrados | FPS según mediana | ms mediana | ms p95 | Draw calls mediana | Captura |
|---|---|---:|---:|---:|---:|---:|---|
${floorTable}

[campus_tests.json](reports/capstone/campus_tests.json) contiene posiciones, luces, carteles y recursos. Memoria estática observada ~2,75 GB decimales y monitor de vídeo ~397 MB; son monitores Godot, no memoria total del sistema/GPU. Carga inicial headless observada: 13.494 ms en la suite de arranque. No hay comparación controlada anterior/posterior de esta tarea; **no se afirma mejora de FPS**. Draw calls elevados y p95 del piso 6 requieren seguimiento en hardware objetivo. Estas muestras cortas no certifican 60 FPS estables ni todos los sectores/colisiones.

### Recorrido de demostración probado

[demo_test.json](reports/capstone/demo_test.json): ${demo.duration_seconds} segundos desde escena lista, ${demo.input_movement_metres.toFixed(2)} m de movimiento real, profesor seleccionado por scanner, diálogo, pregunta SQL, respuesta correcta, retroalimentación y contador de una práctica. Cero pase oficial. Escena \`res://tests/CapstoneDemo.tscn\`, inicio diagnóstico piso 3 \`${demo.start}\`; profesor \`${demo.teacher}\`. Cámara de demostración fija; no se presenta como grabación de login o campaña completa. Capturas 01–05 en [capstone_capturas](reports/capstone_capturas/). Los paneles 06/07 son fixtures etiquetadas y quedan fuera de la demo de servicios remotos.

## Pruebas pendientes y problemas conocidos

- Supabase: DNS/configuración del entorno remoto; esquema y filas desplegados, RLS real, sesión Google/correo real, publicación docente, persistencia cloud, conflictos entre dispositivos. Implementación existente revisable; prueba remota no ejecutable en esta sesión.
- Publicación de las 147 preguntas nuevas: pendiente staging, permisos y validación docente. Banco nuevo utilizado localmente y no tratado como evaluación oficial.
- Revisión académica humana de precisión, dificultad, accesibilidad y alineación con resultados de aprendizaje, particularmente Salud. No hay validación institucional ni estudio de aprendizaje con estudiantes.
- Recorrido manual completo desde login hasta final, todas las combinaciones de asignatura/piso, recorridos de ascensor y escaleras con progresión real, iluminación/carteles de cada sala y pruebas prolongadas de carga. Las regresiones y observaciones por punto no sustituyen esa aceptación manual.
- Borrado físico de preguntas no disponible en el panel actual. No se añadió ni se probó sobre registros reales.
- Herramientas MCP emitieron aviso de versiones plugin 1.0.2/servidor 1.1.2 y una consulta de log tuvo timeout de handshake durante la demo; la demo terminó y produjo evidencia válida. No se cambió el plugin para ampliar el alcance.

## Archivos de producción modificados y preservación

Cambios existentes frente al respaldo inicial:

${changed.map(x=>'- `'+x+'`').join('\n')}

Nuevos: servicio \`scripts/education/local_practice_service.gd\`, banco generado y cuatro fuentes \`resources/education/capstone_authoring_*.json\`. Fixtures y reportes se encuentran en \`tests/capstone_*\` y \`reports/capstone*\`. [phase3_source_manifest.json](reports/capstone/phase3_source_manifest.json) fija hashes al entrar a la fase 4. Controlador del protagonista, estadísticas/combate, SQL, autenticación y guardado funcional no se cambiaron para ocultar fallos de estas pruebas. En fase 4 solo se generan documentos y evidencia de auditoría.
`;
fs.writeFileSync(path.join(project,'EDUCATIONAL_SYSTEM_TEST_REPORT.md'),report);
console.log(JSON.stringify({phase3_closed:true,checks:educational.checks,general_suites:general.length,changed}));
