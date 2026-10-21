# Personajes y bosses superiores — 16-10-2026

## Alcance real

Se amplían los sistemas existentes. No se reemplazan Player, inventario, armas/durabilidad, misiones, computadores/minijuegos, guardado, XP/créditos, checkpoints, BossDuelController, teléfono, campaña, NEXO, ascensores, mapa, CampusState ni GameplayDirector. No se descargan modelos. No se cambia el balance de Chef (350), armas, consumibles, enemigos normales ni precios.

## Bosses de acción

| Piso | ID | HP inicial | Silueta y pose neutral | Premio |
|---|---|---|---|---|
| 5 | profesor_ingles | 450 | Prenda académica, audífonos, tablet | AuricularesLinguisticos + cosmético AudifonosAcademicos |
| 6 | profesor_lenguaje | 500 | Camisa/sweater/chaqueta por preset estable, libro | CuadernoDelEscritor + bolso cosmético |
| 7 | profesor_etica | 550 | Ropa sobria, carpeta y gesto de escritura | InsigniaIntegridad + insignia visible |
| 8 | director, existente | 700 | Chaqueta formal, credencial y tablet; escala visual 1,2 | CredencialDirector/TecladoAdministrador existentes + accesorio visual |

**Todos los HP nuevos: PENDIENTES DE PLAYTEST/BALANCE HUMANO.** Los tres profesores usan escala visual 1,15 y la cápsula del enemigo base. El Director conserva su cápsula anterior: se reduce solo su escala visual. Los nuevos premios académicos son objetos clave únicos y cosméticos, sin efectos estadísticos ocultos. Reutilizan la recompensa estándar de un boss (75 créditos/150 XP); no se retocan tablas anteriores.

Los nuevos duelos heredan BossDuelController mediante academic_boss_duel.gd: neutral/inmune → E/diálogo → Iniciar duelo o Ahora no → intro → combate → caída/victoria/guardado. La derrota permanece al cargar y permite conversación posterior. Reintentos reutilizan BossRetry, snapshot, recursos, quickslots, vida y durabilidad. Ninguno es un cuestionario.

Inglés: WORD SHOT; LISTEN! (franja frontal anunciada); SPEAK UP (área anunciada); fase 2 al 60%: SECOND PART, WORD RUSH con hueco central y VOCABULARY STORM; fase 3 al 30%: FINAL EXAM, mayor movilidad y menor pausa entre ataques. Lenguaje: HOJA CORTANTE, LIBRO PESADO, TORMENTA DE PÁGINAS; fase 2 al 60%: LAS PALABRAS TOMAN FORMA, TINTA y LÍNEA EDITORIAL; fase 3 al 30%: BLOQUEO DEL ESCRITOR, dos manchas máximas por tinta y mayor frecuencia. Máximo seis proyectiles y cinco zonas por profesor; ataques alternan y anuncian impactos.

Ética: PRESIÓN, DUDA con seguimiento suave limitado al inicio y melee. En fase 2 (60%) aparecen dos zonas transitables, sin preguntas ni respuesta correcta: A = daño causado ×1,2/recibido ×1,15; B = daño causado ×0,85/recibido ×0,8. Se aplica solo dentro de ese duelo, sin escribir estadísticas globales del Player. La primera zona pisada fija la elección hasta reset; puede no elegirse ninguna. DILEMA anuncia dos franjas laterales dejando libre el centro. Fase 3 (30%): CONSECUENCIA; A da algo más de recuperación entre ataques y B aumenta modestamente la movilidad del boss. No hay counter perfecto.

Director: conserva errores digitales, dos virus máximos, Modo Administrador, Pantallazo Azul, debilidad al USB y premios originales. Añade FIREWALL frontal en fase 2 y ACCESO DENEGADO en suelo en fase 3, con aviso 1,8 s, máximo dos zonas activas, cooldown 9/11 s y limpieza al reset/muerte. Estos patrones nuevos requieren balance humano; no se cambia el daño de sus ataques anteriores.

## Computadores, misión y compatibilidad

| Computador | game_id intacto | Actividad conservada | Ventaja opcional |
|---|---|---|---|
| pc5 | 0 | Vocabulario de Inglés | ENGLISH_PREPARED: +2 s de pausa después de Word Rush |
| pc6 | 2 | Comprensión lectora | LECTURA_PREPARADA: tinta dura 2 s en vez de 4; velocidad ×0,85 en vez de ×0,65 |
| pc7 | 1 | Decisiones de Ética | REFLEXION_PREVIA: 10 s para elegir zonas en vez de 6 |
| pc8 | 2 | Revisión documental NEXO | NEXO_INFORMATION: virus del Director nacen con 40 HP en vez de 50 |

Se mantienen campaign_id, señales completed/finished, eventos computer:ID y data.computers. Las ventajas se derivan de esas flags y se reflejan en data.unlocks, también al cargar partidas anteriores. No es obligatorio preparar el computador para aceptar/vencer al boss.

Las misiones existentes academico5, seguridad6, acceso7 y direccion conservan IDs, cadena y recompensas. Los requisitos de computador se etiquetan como opcionales y los tres nuevos duelos se añaden como requisitos principales. La puerta acceso7 sigue necesitando TarjetaAcceso. Una misión COMPLETED de un save antiguo no se reabre ni pierde pisos ya desbloqueados; los profesores siguen disponibles si aún no fueron vencidos. El marcador principal omite preparación opcional y apunta al duelo. CampusState reconoce también la victoria de Lenguaje como el hito MEDIUM antes ligado solo a pc6. No se fabrica un flag de computador resuelto por ganar un boss.

## Arenas y seguridad local

Se buscan posiciones existentes de los pisos 5–7 desde (52, altura del piso, −132), con alternativas (43, altura, −132) y (35, altura, −140). Se comprueban suelo/cápsula del jugador y nueve muestras alrededor con rayos de continuidad. Se elige el candidato con más espacio. No se construyen paredes, puertas ni pisos. Los proyectiles reutilizan colisión barrida y se destruyen al chocar/salir de la arena; el movimiento del profesor comprueba suelo y colisiones antes de avanzar.

Los NPC de campaña dentro de la arena se retiran con tween únicamente si existe destino fuera del área y trayecto libre; se restaura su ubicación al terminar/reset. No se crea IA ni otro sistema de NPC. Si no existe un trayecto seguro no se teletransportan a través de paredes. El GameplayDirector existente evita nuevos eventos durante el duelo. No se cierran accesos reales ni se modifica su guardado.

Si ya había una situación ambiental dentro de la arena, se finaliza mediante su método finish existente antes del combate, limpiando sus figurantes temporales. No se alteran eventos en otros sectores.

Las muestras locales no certifican una ruta humana completa, cámara perfecta o salida de cada puerta: revisar manualmente.

## Archivos

Nuevos scripts de producción: academic_boss_config.gd, academic_boss.gd, academic_boss_duel.gd, academic_boss_projectile.gd, academic_boss_zone.gd y upper_campus_bosses.gd, todos bajo scripts/campaign. Tres configuraciones .tres bajo resources/live. Los scripts de proyectil y actor extienden los existentes; no sustituyen sistemas.

Pruebas/preview nuevos: tests/UpperVisualCheck.tscn + upper_visual_probe.gd; tests/UpperCampusCheck.tscn + upper_campus_check.gd. No usan el guardado personal. Resultado final automatizado en reports/upper_campus_result.json. El preview admite preview_boss(id) solo dentro de la fixture.

Scripts existentes modificados en esta ampliación:

- Visuales: scripts/juego/character_appearance.gd, character_visual_presets.gd, procedural_appearance_adapter.gd, student_visual.gd e imported_character_visual.gd.
- Actor base: scripts/juego/enemy.gd añade una fábrica de visuales sobreescribible (el enemigo normal sigue usando Humanoid) y pose neutral de pie cuando la física del boss está detenida. No cambia sus estadísticas.
- Integración: scripts/campaign/appearance_menu.gd, npc.gd, boss_visual_pass.gd, boss_duel_controller.gd (solo limpieza del Director), campus_campaign.gd, quest_manager.gd y mission_guidance.gd.
- Catálogo: scripts/inventory/item_catalog.gd agrega únicamente los tres premios nuevos.
- Estado: scripts/live/campus_state.gd reconoce el hito de Lenguaje aunque se omita pc6.
- Director: scripts/pisos/piso_8/director_informatica_boss.gd y proyectil_error_sistema.gd. Este último expone un gancho de daño para el proyectil académico; conserva el daño digital original.

Player, Humanoid, GameplayManager, Weapon y geometría de Main no se reescriben en esta ampliación. Se conservan las correcciones previas del proyecto. Se adaptan los tests de personalización (ropa modular estable), Director (escala visual 1,2), NEXO (nueve bosses) y campus_fixes (computadores de preparación con objetivo de boss).

Estructura visual, ropa, animación, GLB y assets faltantes: [PERSONAJES_2_0.md](PERSONAJES_2_0.md). Las casillas humanas de [PLAYTEST_1_0.md](PLAYTEST_1_0.md) permanecen pendientes. La validación automática y las capturas no son un playthrough ni una medición de dificultad humana.

### Validación de esta ampliación

Godot 4.7.2, mediante godot-mcp-toolkit y ejecutable del editor (sin depender de PATH). Preview de nueve roles: sin fallos. Suite nueva UpperCampusCheck: 104 comprobaciones, sin fallos; nueve muestras transitables por arena, neutralidad/aceptación, fases 60/30, proyectiles/zonas con límites y sin daño anticipado, ventajas, elección física A/B, reintento real, premios únicos, guardado/carga, identidad/ropa, LOD y compatibilidad de etapas completadas.

Regresiones aprobadas y verificadas por marcador final del log: personajes (70), personalización, campaña, inventario, gameplay, Director, Chef 350, Campus Vivo (52), balance (20), nueva partida, NEXO (111), interacciones (60), recogidas parciales/guardado previo (74) y carga de 236 scripts/recursos. Logs tests/upper_*.log; los errores deliberados de fixture de escritura no se confunden con errores de partida. No basta el código de salida del ejecutable gráfico de Windows.

Medición orientativa headless: frame 120 a 5133 ms, 377,69 MiB de memoria estática, 45120 nodos; no es FPS gráfico ni comparación controlada con versiones anteriores. Una muestra estabilizada de la fixture renderizada en Piso 5 dio 19 FPS, 58,14 ms de proceso/2,81 ms de física y ~2132 MiB tras dos cargas de Main. Esa muestra no certifica rendimiento general ni 60 FPS: hace falta profiler/recorrido humano con hardware, resolución/calidad y memoria GPU controlados. La muestra de 1 FPS registrada justo al recargar corresponde al pico de carga, no al combate jugable.

Capturas MCP revisaron variantes de ropa y presentación neutral de Inglés. La apariencia continúa procedural/estilizada; no se afirma realismo fotográfico. Quedan manuales todos los casos añadidos al checklist: caminar/saltar/escaleras/armas, ropa y apariencia al cargar, NPC sentados, cámara, combate real con/sin preparación, rutas/puertas/arenas, muerte/reintento mediante UI, lectura de telegraphs, dificultad y FPS. Ninguna casilla humana se marca PASS.