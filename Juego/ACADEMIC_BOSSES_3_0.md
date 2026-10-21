# Reorganización académica 3.0

## Etapas 1 y 2: auditoría y plan previo a cambios

19-10-2026. Implementación en curso; pruebas humanas pendientes.

Se revisaron RESUMEN_JUEGO, BALANCE_1_0, BALANCE_REPORT_1_0, PLAYTEST_1_0, BOSSES_SUPERIORES_2_0, cierre NEXO y reporte del Profesor de Redes; configuración, controladores de duelo, campaña, quest_manager, generación de computadores, inventario, celular, reintento y migración.

Antes: punto (1, 200 HP), chef (1, 350), bibliotecaria (2, 125), profesor_redes (3, 550), profesor_ingles (5, 450), profesor_lenguaje (6, 500), profesor_etica (7, 550), director (8, 700), nexo (-1, 1200). Redes registra bosses.profesor_redes, boss:profesor_redes, story:nexo_redes, router:profesor_redes:Router_*, RouterPortatil y reward:boss:profesor_redes. Se conserva opcional con su implementación intacta; no se convierte destructivamente.

### Tabla de migración prevista

| Tipo/ID estable | Antes | Después | Compatibilidad |
|---|---|---|---|
| profesor_ingles | Piso 5 | Piso 6 | Mismo bosses/eventos/reward ledger |
| profesor_lenguaje | Piso 6, Lenguaje | Piso 7, Habilidades de Comunicación | Mismo ID interno, nombre visible nuevo |
| profesor_etica | Piso 7 | Piso 6 | Mismo ID y victorias |
| pc5 / game_id 0 | Piso 5, Inglés | Piso 6, Inglés | campaign_id, activity_profile y computer:pc5 intactos |
| pc6 / game_id 2 | Piso 6, lectura | Piso 7, comunicación | computer:pc6 y LECTURA_PREPARADA intactos |
| pc7 / game_id 1 | Piso 7, Ética | Piso 6, Ética | computer:pc7 y REFLEXION_PREVIA intactos; acceso7 permanece en 7 |
| pc8 / game_id 2 | Piso 8, documentos NEXO | Igual | NEXO_INFORMATION intacto |

La cadena conserva inicio, biblioteca, academico3/4/5, seguridad6, acceso7, direccion, postgame y nexo_final. No reabrir COMPLETED. academico3 añadirá un requisito de cualquiera entre datos/algoritmos, solo en partidas no completadas. academico5 se reasigna a exploración general del 5; seguridad6 a exploración del 6; acceso7 conserva puerta/TarjetaAcceso y visita del 7. Los duelos superiores se vuelven opcionales. Director mantiene el actor, HP y premios; añade tres requisitos informáticos previos. Las partidas con director ya derrotado reciben sus flags previos por compatibilidad sin repetir premios.

Los nuevos premios usan academic_reward:<boss_id> y grant_reward existente, sin modificar el premio global de 75 créditos/150 XP. Los premios antiguos se conservan. La migración es idempotente y no cambia los IDs ni fuerza victorias nuevas. Los snapshots y el guardado existente siguen siendo la autoridad.

No se modifica geometría ni Chef/NEXO. Ubicaciones nuevas requieren sondeo físico y separación temática del piso 4. La implementación se valida por etapas; los resultados se agregarán al terminar.

## Implementación

Se mantienen los nueve bosses anteriores y se añaden seis: total **15**. Redes conserva su arena, script, routers, ID, RouterPortatil y eventos; sigue OPTIONAL. Los dos nuevos profesores de Informática son la elección MAIN: basta vencer a uno, además del PC3 ya existente. No se añaden tres combates obligatorios al piso 3.

| Boss | Piso | boss_id | HP | Clasificación | Premio académico nuevo |
|---|---|---|---:|---|---|
| Encargado | 1 | punto | 200 | MAIN | Ninguno, conserva PaletaProfesional |
| Chef Supremo | 1 | chef | 350 | MAIN | Ninguno, conserva BandejaDelChef y LlaveCasino |
| Bibliotecaria | 2 | bibliotecaria | 125 | MAIN | Conserva LibroEspecial |
| Profesor de Redes | 3 | profesor_redes | 550 | OPTIONAL | Conserva RouterPortatil |
| Bases de Datos | 3 | profesor_datos | 500 | MAIN, alternativa a Algoritmos | LlaveDeDatos |
| Algoritmos y Programación | 3 | profesor_algoritmos | 525 | MAIN, alternativa a Datos | DepuradorPortatil |
| Docente de Enfermería | 4 norte | docente_enfermeria | 475 | OPTIONAL | KitClinicoMejorado |
| Docente de Odontología | 4 norte | docente_odontologia | 475 | OPTIONAL | ProtectorDental |
| Coordinador de Profesores | 4, Sala de Profesores | coordinador_profesores | 500 | OPTIONAL | MapaDocente |
| Profesor de Inglés | 6 | profesor_ingles | 450 | OPTIONAL | AudifonosDeTraduccion; conserva premio anterior |
| Profesor de Ética | 6 | profesor_etica | 550 | OPTIONAL | InsigniaDeIntegridad; conserva InsigniaIntegridad anterior |
| Habilidades de Comunicación | 7 | profesor_lenguaje | 500 | OPTIONAL | InsigniaDeOratoria; conserva CuadernoDelEscritor |
| Profesor de Matemáticas | 7 | profesor_matematicas | 525 | OPTIONAL | CalculadoraAvanzada |
| Director de Carrera de Ingeniería Informática | 8 | director | 700 | MAIN | CredencialDirector y TecladoAdministrador intactos |
| NEXO | −1 | nexo | 1200 | MAIN | Sin cambios |

Todos los HP y efectos nuevos están **PENDIENTES DE PLAYTEST HUMANO**. No se retocaron las tablas de armas, enemigos, precios, XP ni créditos globales. Los nuevos bosses usan el premio común existente de 75 créditos/150 XP. Las habilidades pasivas requieren poseer el premio; no cambian el valor base del objeto o del personaje para partidas sin ese premio.

### Acción y fases

Los nueve profesores de la expansión utilizan `academic_action_boss.gd`, que extiende `academic_boss.gd`/Enemy y conserva `academic_boss_duel.gd`/BossDuelController. No hay un segundo sistema de combate o guardado. Fases a 60% y 30%; las actividades son periódicas y dejan ataques moderados mientras se resuelven. Una solución abre cinco segundos de vulnerabilidad/aturdimiento. Los errores reinician secuencia o generan presión anunciada de bajo daño; no matan instantáneamente.

| Profesor | Fase 1 y ataques base | Fase 2 / actividad | Fase 3 |
|---|---|---|---|
| Datos | Registro Corrupto, copias falsas sin daño, Error de Conexión; golpear registro válido | Relaciones: caminar a VENTAS; JOIN: activar CLIENTE y PEDIDO con E | Consulta Final, alternancia de selección y JOIN con ataques |
| Algoritmos | Bug proyectil, Error de Sintaxis lineal, Stack Overflow en dos áreas crecientes | Secuencia INICIO/PROCESO/DECISIÓN/FIN y patrón Bucle que se corta con BREAK/E | Debug Mode, movilidad de fase 3, secuencia y proyectiles |
| Enfermería | Presión frontal y Emergencia con zonas anunciadas | Prioridad ROJO/AMARILLO/VERDE y dos dispositivos con E | Emergencia Total, mezcla de objetivos y presión; representación ficticia |
| Odontología | Taladro lineal y Enjuague circular con empuje del impacto existente | Golpear tres placas, después golpear CARIES para abrir ventana | Repite objetivos limitados con mayor frecuencia; sin procedimientos clínicos |
| Coordinador | Carpetazo, Documentos, Horario Cambiado | Caminar a la sala del docente anunciado (301/405/602) | Zonas de horario y combate más frecuente |
| Inglés | Word Shot, Listen!, Speak Up y preguntas con zonas físicas A/B/C | Conserva Word Rush/Vocabulary Storm y añade preguntas periódicas | Final Exam: mezcla de combate y preguntas; banco sin repetición inmediata |
| Ética | Presión, Duda, melee | Conserva elección A/B; variación PROTEGER/PERSEGUIR da defensa/daño local, sin respuesta moral correcta | Consecuencia conserva ajuste por elección; bonificación limitada al duelo |
| Comunicación | Ruido, Interrupción, señal falsa sin daño | Mensaje Claro: MAÑANA/TENEMOS/EXPOSICIÓN; Escucha Activa: recordar zona tras dos pulsos | Comunica bajo presión: alternancia de memoria/secuencia y ataques |
| Matemáticas | Suma Vectorial, Ángulo y Secuencia de proyectiles | Operaciones cortas y patrón 2/4/8/16 con respuestas en suelo | Geometría: círculo seguro anunciado y ecuación final sencilla |

La presentación usa primitivas del proyecto. No representa un pase artístico final. El círculo matemático utiliza un aviso y, si no se alcanza, un ataque moderado evitable; no impone daño continuo inevitable en todo el exterior. Los bugs son proyectiles, no se añade IA de minions nueva. El banco de Inglés tiene datos predeterminados en AcademicExpansionData y puede sustituirse con `questions` en su Resource.

Límites por profesor: seis proyectiles, cinco zonas de combate y cuatro objetivos de actividad. Toda actividad termina al vencer, resetear o morir el objetivo; los proyectiles conservan barrido, paredes y expiración existentes. Los personajes neutrales mantienen LOD/SLEEP y no ejecutan la física de combate. No se modificaron sombras ni HUD optimizado.

### Premios y efectos reales

| item_id | Efecto |
|---|---|
| LlaveDeDatos | Pista adicional en conexión/configuración del Director |
| DepuradorPortatil | Duración de ralentizaciones de NetworkSlowStatus ×0,85; sirve en tinta y tecnología posterior |
| KitClinicoMejorado | Botiquin cura cinco puntos adicionales, sin cambiar su base de 50 |
| ProtectorDental | Empuje recibido ×0,9; no cambia daño ni stagger |
| MapaDocente | Mapa/celular muestran sector aproximado de docentes importantes ya conocidos; no revela desconocidos |
| AudifonosDeTraduccion | Dos segundos adicionales para actividades físicas de Inglés/Comunicación |
| InsigniaDeIntegridad | Duración de ralentizaciones de NetworkSlowStatus ×0,9; con depurador: ×0,765 |
| InsigniaDeOratoria | Una Comida adicional por misión de ayuda de las seis originales completada mientras se posee; ledger separado, sin cambiar créditos/XP |
| CalculadoraAvanzada | Pistas numéricas y tiempo restante de preparación de ataques compatibles, sin respuesta automática |

Los objetos se registran desde el catálogo antes de cargar inventario, como CLAVE únicos con descripción. Fuente única `academic_reward:<boss_id>` mediante grant_reward; la flag completa es `unlocks["reward:academic_reward:<boss_id>"]`. Se recuperan estos premios al cargar una victoria anterior compatible una sola vez. Los premios anteriores y sus IDs permanecen; `InsigniaIntegridad` y `InsigniaDeIntegridad` son IDs distintos conservados de forma explícita, no un renombrado destructivo.

### Misiones, flags y migración

Se conservan diez principales y seis secundarias originales; se agregan cuatro secundarias, total veinte misiones. Tres son las pruebas del Director y una es Ubicar profesores. No hay otra campaña.

`ubicar_profesores` empieza al conversar con el coordinador. Requiere hablar con profesor_algoritmos, profesor_ingles y profesor_matematicas y regresar. Usa eventos `talk:<id>`, `academic_expansion.seen` y `academic_expansion.flags.coordinator_returned`. Los contactos y el mapa dan piso/sector; no se crean NPC duplicados ni un marcador exacto de búsqueda.

Pruebas del Director en piso 8, ala oeste, en puntos físicos seguros:

1. `director_task_network`: revisar equipo/cable/adaptador y reiniciar conexión mediante cuatro pasos contextuales.
2. `director_task_antivirus`: nuevo computador `director_antivirus`, game_id 1, reutiliza el minijuego Antivirus con objetivo corto de cuatro aciertos. Usa el circuito computer_requested → minigame.finished → computer:director_antivirus existente.
3. `director_task_config`: tres computadores físicos PC01/PC02/PC03; comparar Red A/Red A/Red B y corregir PC03. Una elección incorrecta no concede progreso.

Flags: `academic_expansion.flags.director_task_network`, `.director_task_antivirus`, `.director_task_config`. Cada una tiene quest_id homónimo y requisito `academic_task`. Director muestra progreso N/3 y rechaza iniciar antes de las tres. Sus estadísticas, ataques, USB, virus y premios no se cambiaron. Se puede preparar estas pruebas antes de la misión principal; sus flags son persistentes. Los pasos incompletos de conexión son temporales y se reinician al recargar, sin perder una prueba ya completada.

`academic_expansion_data.gd.migrate` añade el diccionario versionado sin cambiar save_version=2. Preserva boss IDs, PCs, quests, desbloqueos y campos desconocidos. Una victoria anterior del Director concede sus tres flags de acceso por compatibilidad, sin dinero/XP ni victoria nueva. Las conversaciones antiguas alimentan conocidos. No se trasladan estados de `profesor_lenguaje` a un ID inventado: sigue siendo el mismo ID con el nuevo nombre visible. La migración repetida conserva el mismo resultado.

Piso 5 queda como exploración general, Funcionario/documentos y servicios previos; academico5 deja de exigir Inglés y conserva su recompensa/desbloqueo. seguridad6 requiere visita al 6; acceso7 mantiene TarjetaAcceso y puerta en el 7. No se pierden estados COMPLETED anteriores. Los flags de preparación ENGLISH_PREPARED/LECTURA_PREPARADA/REFLEXION_PREVIA/NEXO_INFORMATION se siguen derivando de pc5/pc6/pc7/pc8 respectivamente, sin inventar finalizaciones al vencer bosses.

### Archivos

Nuevos de producción: academic_expansion_data.gd, academic_expansion.gd, academic_action_boss.gd, academic_objective.gd y director_task_point.gd, bajo scripts/campaign.

Modificados: campus_campaign.gd, campus_content.gd, boss_duel_controller.gd (solo hooks condicionales de admisión), academic_boss.gd (hook de título de fase), academic_boss_config.gd, upper_campus_bosses.gd, quest_manager.gd, mission_guidance.gd, student_phone.gd, item_catalog.gd, inventory.gd, player.gd, gameplay_manager.gd, network_slow_status.gd, campus_qol.gd y save_migration.gd. Recursos modificados: profesor_ingles.tres, profesor_lenguaje.tres y profesor_etica.tres.

No se modificó Main.tscn ni escenas de pisos. Las únicas escenas nuevas son fixtures de pruebas, creadas mediante MCP. Los actores/puntos se integran en runtime siguiendo el patrón existente.

### Verificación y límites

Etapa 3: once comprobaciones aprobadas. Etapa 4: 62 aprobadas. Etapa 5: 92 aprobadas. Con Matemáticas: 102 aprobadas. Fixture ampliada: 243 comprobaciones aprobadas antes de extender los casos de muerte/reintento y victoria real. Los resultados finales y regresiones se registran aparte; esta cifra no debe sustituir al resultado final posterior.

Se corrigió una inferencia de tipo en el módulo nuevo y en el runner de pruebas. En el primer pase ampliado, dos verificaciones estaban mal preparadas: la búsqueda del coordinador ya estaba completada por el propio test y el inventario JSON comparaba números serializados contra tipos nativos. Se aislaron estados y se normalizó la comparación; no se borró progreso real.

Toda validación aquí es automática, aun cuando se ejecuta con renderizado. Falta jugar las arenas, evaluar rutas/cámara y dificultad, probar legibilidad y comprobar la sensación de cada asignatura. No se certifica rendimiento por todo el edificio ni una partida humana completa.

## Resultado final de las comprobaciones principales

Fixture AcademicBossesCheck: **320 comprobaciones, cero fallos**, incluyendo activación caminando, E y golpes mediante los métodos del jugador; soluciones de las actividades, fases, nueve muertes/reintentos y victorias reales, snapshots, stamina, premios sin duplicación, migración idempotente, rechazo/desbloqueo del Director, tres pruebas y carga real de una campaña guardada con todos los premios. El test normaliza números al comparar JSON y aísla la búsqueda del coordinador. Reporte: `reports/academic_bosses_result.json`.

Regresiones lanzadas desde una fixture mediante godot-mcp-toolkit y el ejecutable del editor: campaña, inventario, gameplay, lectura/respaldos de guardado, nueva partida, celular (31), horario (27), Campus Vivo (52), balance (20), Chef 350, Director y NEXO (111) sin fallos. Organización: nueve pisos/596 rutas. Revisión: 242 scripts/recursos cargados. Los avisos de JSON inválido del lector son casos deliberados de la prueba. Registros y marcadores concretos: `reports/academic_regressions.json` y `tests/academic3_*.log`.

Arranque headless de referencia: aproximadamente 5,19 s, 375,87 MiB de memoria estática y 47.199 nodos. No es una medida de FPS/GPU ni una comparación controlada con la versión previa. No se modificó alcance de sombras, LOD/SLEEP ni lógica de HUD existente.

Se inspeccionó una captura renderizada de la actividad de Datos y se aumentó el tamaño de los rótulos de objetivos físicos para facilitar su lectura. Esa inspección automática no certifica cámaras jugables, rutas ni la dificultad.

Las pruebas adicionales heredadas de ascensores/escaleras detectaron una fixture incompatible con la campaña: reemplazaba/eliminaba Player pero conservaba CampusCampaign, que intentaba arrancar y bloqueaba el input del modo sin campaña. Se corrigieron `tests/elevator_basement.gd` y `tests/basement_access.gd` para retirar explícitamente la campaña antes de su boot diferido y desactivar persistencia de credencial. No se cambió lógica de ascensores ni geometría para hacer pasar la prueba. Son pruebas físicas aisladas; no sustituyen el recorrido manual con campaña activa.

Fixtures nuevas: AcademicBossesCheck, AcademicRegressionRunner y AcademicExtraChecks. Sus scripts solo se ejecutan desde tests; el runner lanza el ejecutable del editor con rutas de argumentos estructuradas y guardados de fixtures. No agregar estas herramientas como sistemas de producción.

Resultado de la repetición con fixtures aisladas: **tres ascensores aprobados**, incluidos retorno al −1 y viaje al 8; **20 recorridos de escaleras, abertura y nueve puertas aprobados**, sin errores de script. Profesor de Redes: **38 comprobaciones aprobadas** con su implementación original. Reporte consolidado: 18 ejecuciones sin timeout ni errores de script y con los marcadores finales verificados; rendimiento es una medición de arranque, no una suite de FPS.

Comprobación final adicional: los **29 scripts nuevos/modificados** de producción y pruebas pasaron script_check mediante MCP. Se añadió protección para que los señuelos de daño cero no apliquen el empuje/aturdimiento de un impacto real. Main.tscn quedó abierto en el editor; las fixtures se detuvieron.
