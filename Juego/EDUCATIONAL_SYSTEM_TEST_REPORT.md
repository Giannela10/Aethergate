# DuocGames — pruebas del sistema educativo y del juego

Fecha de ejecución: 6 de noviembre de 2026 (America/Santiago). Cierre de fases 1–3: 2026-11-06T17:42:17.044Z. Este informe precede a la auditoría Capstone. Resultados observados, sin certificar un despliegue remoto.

## Recuperación y alcance

Punto de recuperación: `recovery/capstone_2026-11-06T162611510Z`, 266 archivos, HEAD `b8c93566cf1869c399c74255728918ff058e7a48`. Manifiesto con SHA-256 y rutas relativas en `reports/capstone/checkpoint.json` y en el respaldo. No se reinició el árbol Git: ya tenía trabajo anterior. Sin push, sin cuentas reales modificadas, sin escrituras Supabase, sin cambios RLS. Las claves de configuración no se copiaron al informe.

Se inspeccionaron Main, escenas educativas, generadores de profesores, registros de mentores, servicios, recursos JSON y migraciones SQL. El inventario completo con rutas de actor, mentor y script está en [teacher_inventory.json](reports/capstone/teacher_inventory.json). No se asumió que los profesores eran hijos directos de Main. Las rutas procedurales se obtuvieron después de instanciar el campus.

## Estado previo y recuperación remota

La consulta pública de solo lectura falló con `ENOTFOUND`, también ejecutada fuera de la restricción de red del sandbox. Evidencia: [remote_readonly.json](reports/capstone/remote_readonly.json). No se conocen cantidades totales ni activas de producción, ni el esquema desplegado. Un fallo DNS **no demuestra ausencia de preguntas**. No se ejecutó login con cuentas ajenas ni se insertaron registros de prueba remotos.

Antes existían 3 preguntas de respaldo DEBUG en Informática General, un quiz literario de biblioteca de 16 preguntas y un recurso de 6 preguntas usado por simulaciones heredadas de Inglés. Tener ese recurso en una configuración de simulación no demuestra que un profesor tenga seis preguntas académicas publicadas. Los nueve docentes temáticos carecían de respaldo local específico utilizable en su actividad; la publicación remota permanece desconocida. El NPC genérico Profesor entrega documentos: no tiene asignatura y no se le inventó una.

## Inventario de profesores y otros actores revisados

En «config./sim.» se distingue la lista configurada en el actor del recurso de simulación; no equivale a una cantidad recuperada del servidor. Todos los bancos nuevos son locales, activos, de práctica explícita.

| ID | Piso | Asignaturas de práctica | Anterior config./sim. | Remoto total/activo | Local total/activo | Resultado |
|---|---:|---|---|---|---|---|
| punto | 1 | Sin asignatura formal asociada | — / — | Desconocido: recuperación remota fallida | 0 / 0 | Rol especial/servicio, sin nuevo banco docente |
| chef | 1 | Sin asignatura formal asociada | — / — | Desconocido: recuperación remota fallida | 0 / 0 | Rol especial/servicio, sin nuevo banco docente |
| bibliotecaria | 2 | Sin asignatura formal asociada | — / — | Desconocido: recuperación remota fallida | 0 / 0 | Quiz literario existente: 16 preguntas, 3 opciones; regresión aprobada |
| profesor_redes | 3 | Redes y Telecomunicaciones | — / — | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_datos | 3 | Bases de Datos | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_algoritmos | 3 | Algoritmos y Programación | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| docente_enfermeria | 4 | Enfermería | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| docente_odontologia | 4 | Odontología | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| coordinador_profesores | 4 | Bases de Datos, Algoritmos y Programación, Redes y Telecomunicaciones, Enfermería, Odontología, Inglés, Ética, Habilidades de Comunicación, Matemáticas | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_ingles | 6 | Inglés | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_etica | 6 | Ética | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_lenguaje | 7 | Habilidades de Comunicación | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| profesor_matematicas | 7 | Matemáticas | 0 / 6 | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| director | 8 | Bases de Datos, Algoritmos y Programación, Redes y Telecomunicaciones | — / — | Desconocido: recuperación remota fallida | 15 / 15 | Práctica probada; publicación remota pendiente |
| nexo | -1 | Sin asignatura formal asociada | — / — | Desconocido: recuperación remota fallida | 0 / 0 | Rol especial/servicio, sin nuevo banco docente |
| Profesor | 3 | Sin asignatura formal asociada | — / — | Desconocido: recuperación remota fallida | 0 / 0 | Misión de documentos, sin asignatura; conservado |

No se encontraron profesores adicionales de Mecánica, Soldadura o Doctrina con banco académico asignado en los registros/actores inspeccionados. La temática de un piso y sus carteles no prueban la existencia de un docente. Punto Estudiantil, Chef, Bibliotecaria y NEXO conservan su identidad; no se convirtieron en profesores nuevos.

## Preguntas incorporadas realmente

[Banco ejecutable](resources/education/capstone_practice_bank.json): **150 preguntas únicas**, 147 originales agregadas y 3 reutilizadas del respaldo anterior. Diez áreas locales; las nueve asignaturas de docentes y el área general existente. Los campos siguen el formato de LearningActivity: id, subject_id, unit, kind, prompt, content.options, answer, explanation, difficulty, active, access_challenge y mentor_id. Cuatro alternativas distintas y una clave por pregunta. Los UUID locales son deterministas y no se atribuyen a filas remotas. Se usa `BASE_DATOS`, el código real del seed SQL.

| Código y asignatura | Piso | Anteriores locales reutilizadas | Agregadas | Disponibles/activas | Fácil / media / difícil |
|---|---:|---:|---:|---:|---|
| BASE_DATOS · Bases de Datos | 3 | 0 | 15 | 15 | 5 / 5 / 5 |
| ALGORITMOS · Algoritmos y Programación | 3 | 0 | 15 | 15 | 5 / 5 / 5 |
| REDES · Redes y Telecomunicaciones | 3 | 0 | 15 | 15 | 5 / 5 / 5 |
| ENFERMERIA · Enfermería | 4 | 0 | 15 | 15 | 5 / 5 / 5 |
| ODONTOLOGIA · Odontología | 4 | 0 | 15 | 15 | 5 / 5 / 5 |
| INGLES · Inglés | 6 | 0 | 15 | 15 | 5 / 5 / 5 |
| ETICA · Ética | 6 | 0 | 15 | 15 | 5 / 5 / 5 |
| COMUNICACION · Habilidades de Comunicación | 7 | 0 | 15 | 15 | 5 / 5 / 5 |
| MATEMATICAS · Matemáticas | 7 | 0 | 15 | 15 | 5 / 5 / 5 |
| INF_GENERAL · Informática General | 3 | 3 | 12 | 15 | 5 / 5 / 5 |

Coordinación reutiliza 15 referencias de las asignaturas: 5 fáciles, 5 medias y 5 difíciles. Director reutiliza 15 referencias avanzadas, cinco difíciles de Bases de Datos, Algoritmos y Redes. No son asignaturas nuevas ni copias de filas. Se mantienen requisitos de sus simulaciones; practicar está disponible sin falsificar un pase.

El respaldo DEBUG `demo_questions.json` también pasó de 3 a 15 conservando las tres originales: así la ruta existente de Informática General utiliza el contenido. El servicio de acceso de una exportación no DEBUG mantiene su política previa de entrenamiento público sin clave; no se amplió el acceso oficial ni se cambió su guardia. Los nueve docentes temáticos usan el banco nuevo desde su opción **ACTIVIDAD DEL DOCENTE → PRÁCTICA LOCAL** también mediante el servicio dedicado. El panel no necesita estar conectado para esta práctica.

El generador `tests/build_capstone_bank.cjs` se ejecutó dos veces; la segunda informó `unchanged_on_repeat: true`. Solo regenera los archivos locales propios. No elimina preguntas de docentes ni aplica SQL. Los archivos `capstone_authoring_*.json` son las fuentes editables; el banco generado es el recurso utilizado en juego.

**Publicadas en Supabase durante esta tarea: 0.** [publication_pending.json](reports/capstone/publication_pending.json) registra los IDs locales y la asociación remota pendiente. Antes de publicar se requiere staging autorizado, UUID reales de asignaturas, propietario docente y reglas mentor/piso verificadas; los desafíos integradores cruzan asignaturas y no deben clonarse ciegamente para eludir esas reglas.

Contenido original de práctica, sin atribución al programa oficial de Duoc UC ni validación docente aún. Salud usa principios generales de bioseguridad y comunicación, no recomendaciones individuales ni reemplazo de protocolos clínicos. Referencias para revisión: [OMS, higiene de manos](https://www.who.int/publications/m/item/five-moments-for-hand-hygiene), [CDC, precauciones odontológicas](https://www.cdc.gov/dental-infection-control/hcp/summary/standard-precautions.html), [PostgreSQL, transacciones](https://www.postgresql.org/docs/current/tutorial-transactions.html), [ACM, ética profesional](https://www.acm.org/binaries/content/assets/about/acm-code-of-ethics-and-professional-conduct.pdf). Estas referencias no son un aval institucional.

## Pruebas educativas ejecutadas — fase 2

Godot MCP abrió escenas de prueba que instancian Main y sus componentes reales. Campaña y credencial con persistencia deshabilitada en estas escenas; las pruebas de escritor de guardado usan archivos temporales. No se alteran partidas reales. Los casos automatizados relocalizan al jugador para cubrir todos los profesores: esto no certifica un recorrido manual continuo de los nueve pisos.

| Evidencia | Resultado real | Límite |
|---|---|---|
| [education_tests.json](reports/capstone/education_tests.json) | 1315 comprobaciones; 150 preguntas; 11 docentes; 33 respuestas por UI; 0 fallos | Proyección local y campaña aislada, sin sesión remota |
| [staff_tests.json](reports/capstone/staff_tests.json) | 17 comprobaciones; creación, edición, activación, desactivación, vista estudiante, recuperación de fallo temporal, permisos | Paneles reales contra backend simulado en memoria; no prueba RLS desplegada |
| [auth_tests.json](reports/capstone/auth_tests.json) | 59 comprobaciones, 0 fallos | Adaptadores reales con transporte/sesiones aislados; Google/login real pendientes |
| [roles_tests.json](reports/capstone/roles_tests.json) | 63 comprobaciones, 0 fallos | Modelo de políticas independiente y SQL estático; sin privilegios reales modificados |

Para **cada uno de los 11 docentes**: piso y actor; acercamiento seguro; visibilidad del prompt; diálogo; botón de actividad; cuatro alternativas; tres preguntas sucesivas (incorrecta y correctas); explicación; cierre; reapertura sin repetición prematura; acceso después de simulación completada; selección del mentor trasladado; ausencia de recompensa/pase oficial. Las 150 preguntas se evaluaron por clave, se rechazaron índice inválido y reenvío del ticket. Por cada área se probó respuesta incorrecta, banco vacío, registro malformado y rechazo de uso local como validación de misión. Se comprobó que una pared real continúa bloqueando la interacción.

Guardado educativo: serialización y migración real conservaron las 33 respuestas como práctica. La suite de integración prueba además el escritor local real con archivo temporal. La práctica nueva no completa misiones verificadas ni genera desbloqueos oficiales: esa separación es una condición aprobada, no una omisión simulada como éxito de campaña. Las misiones de campaña y recompensas idempotentes se ejercitaron en regresiones independientes.

Panel docente: login/modelo de rol, asignaturas, CRUD no destructivo, preview y cambios reflejados en estudiante aprobados en fixture. Panel administrador: asignación docente/asignatura y gestión entre áreas aprobados en fixture. Rol de estudiante y docente sin asignación rechazados. **El panel actual no ofrece borrado físico**; no se inventa una prueba de eliminación. Se retiraron únicamente registros del fixture al finalizar; 0 preguntas reales eliminadas.

## Correcciones funcionales acotadas

1. Se añadió un servicio local explícito con validación de datos y tickets consumibles. Un registro incompleto provocaba acceso a un campo inexistente; ahora se descarta y se devuelve error controlado. La prueba de datos inválidos pasó después de corregirlo.
2. La selección de docentes chocaba con el cuerpo lógico de su propia simulación, aunque el mentor visible estaba delante. El raycast educativo excluye únicamente ese cuerpo asociado y al jugador; las paredes siguen bloqueando. Rango y orientación usan el mentor visible, incluida su posición posterior al encuentro. No se modificó el controlador del protagonista.
3. Redes y Director conservan conversación y práctica después de completar su simulación. Coordinación y Director ofrecen práctica cuando faltan requisitos de acción sin levantar esos requisitos. No cambian daño, vida ni recompensas.
4. La propiedad enum de la bibliotecaria se normalizó de `duel_type = 1.0` a `duel_type = 1`: la representación decimal se perdía al recargar/guardar en el editor y activaba COMBAT por defecto. Se observó el fallo y se restauró QUIZ mediante MCP; la regresión completa de campaña aprobó después. Main solo difiere del respaldo en esta línea.
5. El código de asignatura nuevo se alineó al seed existente `BASE_DATOS`. Las pruebas antiguas que asumían siempre A/B se adaptaron a seleccionar la clave del registro emitido y una alternativa distinta para el caso incorrecto, manteniendo las mismas aserciones de evaluación y guardado.

## Pruebas generales ejecutadas — fase 3

| Suite headless | Estado final | Errores | Avisos | Duración de proceso ms |
|---|---|---:|---:|---:|
| learning_activity_v4 | APROBADA | 0 | 0 | 690 |
| education_1_0 | APROBADA | 0 | 0 | 662 |
| education_integration | APROBADA | 0 | 0 | 12799 |
| gameplay_regression | APROBADA | 0 | 0 | 5785 |
| inventory_regression | APROBADA | 0 | 0 | 1684 |
| personalizacion | APROBADA | 0 | 0 | 14889 |
| campaign_regression | APROBADA | 0 | 0 | 21516 |
| guardado_lectura | APROBADA | 0 | 4 | 647 |
| nueva_partida | APROBADA | 0 | 0 | 14191 |
| student_phone | APROBADA | 0 | 0 | 6778 |
| campus_v4 | APROBADA | 0 | 0 | 29323 |
| campus_vivo | APROBADA | 0 | 0 | 14377 |
| organizacion_pisos | APROBADA | 0 | 0 | 4966 |
| director_informatica_boss | APROBADA | 0 | 0 | 1123 |
| nexo_final | APROBADA | 0 | 0 | 23702 |
| performance_startup | APROBADA | 0 | 0 | 14101 |

16/16 suites aprobadas al cierre. Los cuatro avisos de `guardado_lectura` son casos deliberados de JSON corrupto/no objeto y recuperación con copia; no son errores inesperados de una partida normal. Los mensajes/resultados completos permanecen en `reports/capstone/general_*_process.log`. El fallo inicial de biblioteca fue real y no se contó como aprobado hasta repetir la prueba corregida.

Cobertura: inicio de Main, guía y pausa, controlador y estados de movimiento, cámara y componentes, interacción E, recogibles e inventario, equipo/armas, simulaciones, misiones secundarias, progresión, accesos, objetos de misión, nueva partida, lectura/escritura local y migración, muerte/reaparición, premios no duplicados, organización de 596 rutas de piso, Director y NEXO. Las pruebas headless funcionales no prueban calidad de iluminación ni rendimiento gráfico.

[feet_gate_final.json](reports/characters_6_3/feet_gate_final.json): 19 comprobaciones aprobadas tras nueva ejecución de Feet63. Movimiento por Input real, salto, aterrizaje, caminar/correr, agacharse, ataque, subida de escalera y desplazamiento de cabina. La cabina móvil usa la fixture visual documentada cuando una campaña nueva aún no autoriza el destino; no se presenta eso como prueba de todos los desbloqueos de ascensor. No certifica todos los trayectos o ausencia absoluta de deslizamiento de pies.

### Nueve niveles: observación y rendimiento actual

Main instanciado, física de actores activa, cámara fija de inspección, 1,2 segundos de asentamiento por piso; 60 fotogramas de calentamiento y 120 medidos; VSync desactivado; GL Compatibility, ventana 1152×648. El director de población se suspendió para estabilizar la muestra; el guardia de acceso se suspendió solo dentro de esta fixture de diagnóstico para relocalizar la cámara/jugador. No es un cambio de producción. La cuenta de humanos indica visuales remodelados registrados en cada altura; no todos aparecen simultáneamente en pantalla.

| Piso | Escena / suelo con colisión | Humanos registrados | FPS según mediana | ms mediana | ms p95 | Draw calls mediana | Captura |
|---|---|---:|---:|---:|---:|---:|---|
| -1 | Sí / Sí | 1 | 53.4 | 18.74 | 24.69 | 6927 | [Captura](reports/capstone_capturas/piso_-1.png) |
| 1 | Sí / Sí | 10 | 61.8 | 16.19 | 23.61 | 6304 | [Captura](reports/capstone_capturas/piso_1.png) |
| 2 | Sí / Sí | 4 | 49.5 | 20.19 | 30.11 | 6918 | [Captura](reports/capstone_capturas/piso_2.png) |
| 3 | Sí / Sí | 8 | 54.1 | 18.50 | 23.33 | 7388 | [Captura](reports/capstone_capturas/piso_3.png) |
| 4 | Sí / Sí | 4 | 54.5 | 18.36 | 24.79 | 7998 | [Captura](reports/capstone_capturas/piso_4.png) |
| 5 | Sí / Sí | 2 | 53.5 | 18.68 | 23.29 | 8971 | [Captura](reports/capstone_capturas/piso_5.png) |
| 6 | Sí / Sí | 2 | 46.9 | 21.32 | 35.61 | 9223 | [Captura](reports/capstone_capturas/piso_6.png) |
| 7 | Sí / Sí | 2 | 55.4 | 18.05 | 24.46 | 8630 | [Captura](reports/capstone_capturas/piso_7.png) |
| 8 | Sí / Sí | 1 | 65.3 | 15.31 | 26.04 | 6548 | [Captura](reports/capstone_capturas/piso_8.png) |

[campus_tests.json](reports/capstone/campus_tests.json) contiene posiciones, luces, carteles y recursos. Memoria estática observada ~2,75 GB decimales y monitor de vídeo ~397 MB; son monitores Godot, no memoria total del sistema/GPU. Carga inicial headless observada: 13.494 ms en la suite de arranque. No hay comparación controlada anterior/posterior de esta tarea; **no se afirma mejora de FPS**. Draw calls elevados y p95 del piso 6 requieren seguimiento en hardware objetivo. Estas muestras cortas no certifican 60 FPS estables ni todos los sectores/colisiones.

### Recorrido de demostración probado

[demo_test.json](reports/capstone/demo_test.json): 60.688 segundos desde escena lista, 1.30 m de movimiento real, profesor seleccionado por scanner, diálogo, pregunta SQL, respuesta correcta, retroalimentación y contador de una práctica. Cero pase oficial. Escena `res://tests/CapstoneDemo.tscn`, inicio diagnóstico piso 3 `(-45.0, 23.96642, -132.8)`; profesor `(-45.0, 24.00767, -137.0)`. Cámara de demostración fija; no se presenta como grabación de login o campaña completa. Capturas 01–05 en [capstone_capturas](reports/capstone_capturas/). Los paneles 06/07 son fixtures etiquetadas y quedan fuera de la demo de servicios remotos.

## Pruebas pendientes y problemas conocidos

- Supabase: DNS/configuración del entorno remoto; esquema y filas desplegados, RLS real, sesión Google/correo real, publicación docente, persistencia cloud, conflictos entre dispositivos. Implementación existente revisable; prueba remota no ejecutable en esta sesión.
- Publicación de las 147 preguntas nuevas: pendiente staging, permisos y validación docente. Banco nuevo utilizado localmente y no tratado como evaluación oficial.
- Revisión académica humana de precisión, dificultad, accesibilidad y alineación con resultados de aprendizaje, particularmente Salud. No hay validación institucional ni estudio de aprendizaje con estudiantes.
- Recorrido manual completo desde login hasta final, todas las combinaciones de asignatura/piso, recorridos de ascensor y escaleras con progresión real, iluminación/carteles de cada sala y pruebas prolongadas de carga. Las regresiones y observaciones por punto no sustituyen esa aceptación manual.
- Borrado físico de preguntas no disponible en el panel actual. No se añadió ni se probó sobre registros reales.
- Herramientas MCP emitieron aviso de versiones plugin 1.0.2/servidor 1.1.2 y una consulta de log tuvo timeout de handshake durante la demo; la demo terminó y produjo evidencia válida. No se cambió el plugin para ampliar el alcance.

## Archivos de producción modificados y preservación

Cambios existentes frente al respaldo inicial:

- `scripts/campaign/academic_boss_duel.gd`
- `scripts/campaign/boss_duel_controller.gd`
- `scripts/campaign/interaction_controller.gd`
- `scripts/education/mentor_activity_v4.gd`
- `scripts/pisos/piso_3/profesor_redes_duel.gd`
- `resources/education/demo_questions.json`
- `Main.tscn`

Nuevos: servicio `scripts/education/local_practice_service.gd`, banco generado y cuatro fuentes `resources/education/capstone_authoring_*.json`. Fixtures y reportes se encuentran en `tests/capstone_*` y `reports/capstone*`. [phase3_source_manifest.json](reports/capstone/phase3_source_manifest.json) fija hashes al entrar a la fase 4. Controlador del protagonista, estadísticas/combate, SQL, autenticación y guardado funcional no se cambiaron para ocultar fallos de estas pruebas. En fase 4 solo se generan documentos y evidencia de auditoría.
