# CAMPUS VIVO 2.0

## Integración

CampusCampaign crea CampusVivo tras inicializar los sistemas anteriores. Se añade gameplay_event como señal al bus ya existente; no se reemplazan misiones, reloj, NPC, combate, celular, historia ni guardado. No se reconstruye ni redistribuye el edificio.

GameplayDirector observa piso, objetivo actual, vida, combate reciente, progreso, bosses y hora de AcademicSchedule. Usa QUIET, NORMAL, ACTIVE y STORY_LOCK. El chequeo es periódico; hay una situación ambiental activa como máximo. Los bloqueos se comprueban también al solicitarla directamente.

No genera situaciones con boss activo, jugador ocupado/muerto, modal, minijuego, cinematic lock, combate cercano o reciente, vida por debajo de 25% o cooldown pendiente. Al terminar aplica una pausa aleatoria de 90–240 s por defecto. Las pausas y los eventos únicos sobreviven a la carga.

## Catálogo y mundo reactivo

Veinte definiciones: entrada, almuerzo, biblioteca, técnico investigando, reunión docente, evaluación, trabajo de grupo, profesor saliendo, taller, espera de ascensor, carpeta caída, orientación, revisión de PC, agradecimiento, descuento raro, rumor raro, primer fallo, interferencia NEXO, pulso y discusión docente.

Las situaciones duran hasta 1–3 minutos, caducan y se limpian sin tocar objetivos de campaña. Cuatro son únicas por partida: primer_fallo, tecnico_sistema, discusion_docente y rumor_raro. Los eventos raros y recompensas ambientales no forman parte del 100% obligatorio.

Se reutilizan los NPC cercanos para poses/props, sin cambiarles posición o identidad. Las escenas de grupo pueden añadir hasta tres representaciones temporales con CharacterVisual, sobre asientos/posiciones comprobados. No son un nuevo sistema de NPC dinámicos: no tienen misiones, inventario, IA de combate ni colisiones. Los pequeños recorridos visuales no sustituyen navegación de los NPC existentes.

Almuerzo consulta la hora; biblioteca varía su cantidad de figurantes. Reuniones docentes se anclan al recinto de profesores del 4. Talleres solo en -1, tecnología en 3 y materias generales en 5–8. No hay procedimientos clínicos/industriales reales.

Las ayudas son voluntarias. Carpeta caída usa un prop temporal y token propio, sin introducir un objeto de misión en el inventario. Orientar o ayudar al PC usa la interacción existente. Hay agradecimientos y descuentos temporales. Los premios usan el ledger de campaign.grant_reward: máximo 24 créditos ambientales por partida por defecto. Cargar no reinicia el presupuesto.

CampusState deriva NORMAL, ANOMALY_LOW, ANOMALY_MEDIUM, ANOMALY_HIGH y RESTORED de progreso existente: pistas/PC3, PC6, Director y final/postgame; también admite decision_flags.nexo_stage y campus_restored. No inventa una nueva secuencia NEXO.

CampusDisplay admite NORMAL/NOTICE/NEXO_GLITCH/EMERGENCY/RESTORED. Los computadores conservan done y sus minijuegos; la base visual se vuelve a derivar de su estado real. Avisos, carteleras y conversaciones reaccionan a progreso, hora y, cuando existen esos datos, decisiones, clima y reputación.

El pulso cambia pantallas y luces de monitores cercanos, hace reaccionar visualmente a NPC y usa un tono procedural breve y discreto. No hace daño. Efectos y expresiones se restituyen; no se producen nuevos pulsos en RESTORED. Abrir un modal cancela la situación antes de pausar el mundo.

Las aulas exponen EMPTY, CLASS, GROUP_WORK, EXAM y TECH_PROBLEM como presentación; el horario, asistencia y desafíos académicos siguen siendo los anteriores.

## StoryMoments y descubrimiento

Se registran llegada, primer boss, descubrimiento NEXO, piso 8, entrada a -1, archivo/servidor y final, además de descubrimientos de pisos/áreas. Son presentaciones de hitos existentes, no nuevas misiones o vídeos.

Las áreas incluyen biblioteca, casino, auditorio, coordinación, talleres, dirección y terraza según entrada/proximidad/eventos existentes. Los avisos de primera visita se guardan y no se repiten al subir y bajar.

StoryMoment puede delegar en handlers narrativos existentes con STORY_LOCK. El juego conserva sus cámaras, UI y slots de música; los momentos predeterminados usan texto/aviso y un sonido discreto de descubrimiento.

## Bosses

Se revisaron Punto Estudiantil, Chef, Bibliotecaria, Redes y Director. Mantienen estadísticas, daño, fases, elecciones por distancia y cooldowns actuales. Se añade un aviso visual al detectar sus flags de ataque especial pendiente/carga; se mantienen las poses y zonas anteriores.

No se añaden paredes invisibles ni cambios de geometría. Los límites propios de cada actor continúan. Si el jugador se aleja de la zona del duelo durante varios segundos, puede usar un retorno voluntario con E hacia el punto validado previo al duelo; no se le mueve automáticamente ni se cura.

Aceptar un duelo captura vida, inventario, equipamiento, durabilidad y estamina. Se reutiliza el checkpoint en el acercamiento actual. Tras morir aparece REINTENTAR BOSS. Restaura el snapshot, limpia copias de armas lanzadas/soltadas de ese snapshot y proyectiles propios pendientes, y vuelve a la introducción normal.

La restauración no emite progreso de recogida ni vuelve a conceder premios. El snapshot es temporal, no una segunda partida guardada. Una victoria invalida el reintento.

## Calidad de vida

El mapa mantiene su acceso existente: muestra descubrimiento progresivo, hasta tres notas manuales y viaje postgame a puntos seguros de entrada, biblioteca, pisos 3/4/8, acceso de terraza y talleres. Solo ofrece pisos descubiertos; la terraza exige descubrir su área. Rechaza combate, minijuegos, muerte, asiento ocupado o llegada sin espacio.

Inventario conserva su catálogo y snapshots: añade favoritos persistentes, protección de descarte, confirmación de armas especiales y comparación de daño/duración de golpe/durabilidad de instancias. El peso físico no existe como estadística universal: se muestra sin dato. Los efectos de curación y velocidad se explican numéricamente.

El celular añade ACTIVIDAD RECIENTE (80 entradas por defecto), HISTORIAL DE DIÁLOGO (20 conversaciones importantes) y contactos favoritos. No archiva todas las frases ambientales ni cambia afinidad/reputación.

Los cambios de objetivo se notifican sin abrir una pantalla completa.

## Desarrollo, datos y guardado

BalanceTools reporta bosses, daño exportado o fórmulas por fase, armas, consumibles, enemigos, economía y advertencias de recursos. No ajusta estadísticas. QA comprueba IDs, referencias, prerequisitos, recompensas, NPC de entrega y existencia de nodos importantes; deja las rutas físicas como revisión manual.

La telemetría está desactivada por defecto y solo se activa en desarrollo. Guarda localmente un buffer limitado de daño, objetos, acontecimientos y muertes con coordenadas; permite examinar duración de misiones y muertes por boss. No hay envío a internet.

Se añade save_version = 2 conservando version = 1 como envoltorio compatible con herramientas anteriores. La migración agrega campus_live por defecto, conserva progreso y campos desconocidos, normaliza colecciones y acepta partidas anteriores. Una versión futura se protege desactivando escritura; el sistema anterior sigue creando respaldos de JSON inválido.

EventData/StoryMoment/BossData/NPCData son recursos de extensión. QuestData y WeaponData reutilizan los Resource existentes de misiones e inventario. No se migran masivamente valores de combate ni se crean copias de esos sistemas. resources/live/library_study.tres sirve como ejemplo editable.

[GUIA_CREAR_CONTENIDO.md](GUIA_CREAR_CONTENIDO.md) documenta NPC, boss, arma, misión, ClassroomChallenge, evento, pickup, diálogo y validación.

## Ajustes y rendimiento

Opciones → Gráficos, ventana, idioma y desarrollo:

- WINDOWED, BORDERLESS y FULLSCREEN.
- BAJO/MEDIO/ALTO: distancia de detalle NPC, sombras de personajes y efectos ambientales seguros.
- FPS: 30, 60, 120 o sin límite.
- ES/EN: infraestructura y traducción parcial de interfaz, sin afirmar que todo el juego esté traducido.
- Telemetría local opt-in y herramientas de desarrollo.

Las preferencias se guardan fuera del progreso, en campus_settings.cfg. Los avisos esenciales de bosses no desaparecen en calidad baja. Se amplía el LOD existente; no se desactivan misiones, colisiones o IA crítica de pisos lejanos. Los eventos terminan al abandonar su piso.

La UI se comprobó a 1920×1080 y 2560×1440 mediante layout y se adapta al cambio de tamaño. El rendimiento headless medido fue aproximadamente 5,5 s de arranque y 373 MiB de memoria estática: no es una medición de FPS/GPU ni una comparación con un baseline anterior.

## Pruebas y revisión manual

tests/campus_vivo.gd valida bloqueos, migración, progresión de CampusState, únicos, economía finita, figurantes, PC reparado, historial, favoritos, marcadores, viaje postgame, ajustes, UI y reintento sin progreso/recompensas duplicados. Se mantienen las regresiones anteriores.

Resultado: 52 comprobaciones nuevas aprobadas. Pasaron también campaña, inventario, gameplay, celular (31), horario (27), Personajes 2.0 (59), interacciones (60), nueva partida, lectura/respaldos de guardado, Chef, Director y Redes (38). La revisión cargó 219 scripts/recursos sin fallos; la prueba de arranque completó su medición. Los logs de prueba están bajo .godot/campus-vivo-*.log.

Revisar con renderizado real: horarios de almuerzo/biblioteca, disposición y pies de figurantes, interrupción de eventos por conversaciones/bosses, sillas recogidas durante una escena, cámara junto a paredes, límites y retorno de arena, dos reintentos consecutivos con armas lanzadas, partidas antiguas y descubrimiento de terraza, ventana/borderless en varios monitores, traducciones pendientes y FPS recorriendo cada piso.

QA no certifica ausencia de rutas bloqueadas ni una partida completa. No se han reconstruido historia, edificios, Boss Rush, Nueva Partida+, clases u otros sistemas de progreso.
