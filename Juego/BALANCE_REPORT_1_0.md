# BALANCE REPORT 1.0

## Actualización vigente: Academic Bosses 3.0 — 19-10-2026

Se agregan seis bosses de acción académica y se reorganizan tres conservando IDs y victorias: Inglés/Ética en 6 y Comunicación (profesor_lenguaje) en 7. Redes conserva su contenido opcional. Total: 15 bosses y 20 misiones; misma cadena de diez principales, con Datos o Algoritmos como requisito alternativo. Piso 5 conserva exploración, servicios y documentos/TarjetaAcceso.

Director mantiene 700 HP y combate, con tres pruebas previas y flags persistentes. Chef mantiene 350 HP y NEXO 1200. Sin rebalanceo global. Premios únicos, recuperación de victorias anteriores y migración idempotente; mecánicas físicas con presión moderada y caps de nodos. Informe técnico y efectos concretos: [ACADEMIC_BOSSES_3_0.md](ACADEMIC_BOSSES_3_0.md). **Balance humano pendiente**; el historial siguiente no representa la nueva distribución.

**Estado actual, 16-10-2026:** CIERRE DE CAMPAÑA 1.0 añade NEXO normal y una misión principal final. Las conclusiones fechadas 15-10 son el diagnóstico previo. NEXO está **PENDIENTE DE BALANCE HUMANO**; no se rebalancearon los elementos anteriores. Ver actualización de cierre al final y [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md).

## RESUMEN EJECUTIVO

Auditoría de datos y pruebas automáticas, 2026-10-15, con godot-mcp-toolkit y Godot 4.7.2. Se conservan edificio y contenido. Hay 15 misiones, cinco bosses, 23 armas de catálogo, 51 pickups de arma, 779 sillas y 12 centros de vida. No se hicieron partidas humanas ni se enviaron datos a internet.

Duración provisional: principal 1–2,5 h; principal + secundarias 2–4 h; contenido disponible completo 3–6 h; postgame abierto. Son estimaciones por componentes, pendientes de cronometraje. No se fuerza 5–8 h añadiendo vida o esperas. El cierre real es archivo_subterraneo; no existe boss final NEXO.

## CRITICAL ISSUES

**B01 corregido:** aceptar documentos con mochila llena marcaba provided aunque receive_item fallara. Se reutiliza la entrega garantizada de recompensas. Al volver al Profesor también se recupera una clave inicial pendiente de una partida antigua, sin duplicarla. Es necesaria para TarjetaAcceso.

No se certifica ausencia universal de softlocks: la conectividad física de puertas, escaleras, ascensores y aulas necesita recorrido manual. QA de IDs/referencias dio cero errores; no sustituye navegación real.

## HIGH ISSUES

- **B02 corregido:** objetivos de boss reconocen data.bosses aunque falte su evento redundante en guardado antiguo.
- **B03 corregido:** lotes respetan capacidad; stacks llenos no crean entradas adicionales ni devuelven éxito; add_item devuelve cantidad añadida, no total poseído. Evita cobrar o consumir fuentes por un falso éxito.
- **B04 corregido:** guardar/cerrar durante intro/combate o muerte pendiente escribe estado coherente previo al duelo, incluidos mundo/progreso e inventario; al continuar el boss está neutral. Se informa antes de aceptar. Elegir checkpoint abandona snapshot para no afectar guardados futuros. Victoria conserva recompensas actuales y su ledger.
- **Abierto:** mínimos ofensivos teóricos de bosses muy cortos frente a los objetivos de diseño; medir primera victoria y porcentaje de tiempo golpeando antes de modificar HP/daño.
- **Abierto:** NEXO final y varios modos/bosses citados por el encargo no existen en el contenido actual. No se crean en esta etapa.

## ARMAS

Tabla completa de las 23 instancias en BALANCE_1_0.md y datos en reports/balance_1_0_data.json. **Sin cambios de daño, velocidad, durabilidad ni rareza.** Silla 34/0,75 s/4 impactos; Palo 22/0,6 s/14. Se mantienen sillas divertidas y frágiles: oferta abundante pero sin venta, sin conversión a créditos infinitos. 770/779 pasan aproximación local y raycast; falta demostrar rutas desde spawn.

Clases/peso/coste por tipo no están implementados como atributos; no se inventan. Las únicas tienen durabilidad/velocidad/bonus útiles. Cable y compra de Silla por 25 son candidatos de revisión, sin borrarlos o igualarlos. No existe taller de reparación/mejora de arma que balancear.

## ENEMIGOS

Nueve encuentros normales, HP reales 54,6–238, daño 6–21. Tabla TTK por arma en auditoría. Las armas comunes no eliminan de un golpe todos los roles. Especiales sí pueden eliminar rápidos anteriores; no se normaliza esa diferencia. Salto rápido del 3 → pesado del 4 pendiente de sensación. **Sin cambios de estadísticas ni densidad.**

## BOSSES

Revisados Punto, Chef, Bibliotecaria, Redes y Director. Chef 450 HP, Redes 550, Director 700, Punto 200; Bibliotecaria 125 y cinco aciertos de 25. Se conservan estadísticas, fases y cooldowns. La modificación común es la política de guardado/reintento y su explicación, no nuevas mecánicas.

Redes conserva reducción hasta 70% con tres routers; desconexión instantánea, reconexión única en fase 2; pulso 7 s, interferencia 8 s, conexión 9 s y aviso 1,2 s. Director invoca dos virus una vez; USB causa 80 daño y stun 3 s, ventaja sin eliminar 700 HP. No hay Profesor de Programación ni boss final NEXO para validar. El quiz se prueba como quiz, sin inflar vida física.

## ECONOMÍA

Principal analítica: 1165 créditos antes de gastos, incluyendo documentos, cuatro bosses, siete PCs y archivo. Cinco ramas de mejoras completas cuestan 3500; no se compra todo con principal sola. Precios y recompensas **sin cambios**. Eventos tienen presupuesto total 24. Recompensas son idempotentes; venta no existe. Farming por recargar enemigos normales sigue posible: medir rentabilidad, no eliminar todo respawn automáticamente.

## XP

Principal analítica sin enemigos: 2015 XP, nivel 14. 150 XP por nivel; salud +5 por nivel, Fuerza solo mediante mejora (máximo +25%). Principal + coleccionables/secundarias/clases/Redes, sin farming/eventos: ~3080 XP, nivel 21; con nueve enemigos normales ~3170, nivel 22. Son sumas de fuentes, no telemetría de una partida. **Sin cambios de XP o curva.**

## CURACIÓN

Bebida 10 HP/5 créditos; Comida 30/10; Botiquín 50/25; Colación vida completa; energética +35% por 12 s. Stack 999, sin cooldown de consumo. Cada PC completado cura 25 HP una vez. Centros y victorias curan completo; centros bloqueados en duelos. **Sin cambios de consumibles ni precios.** Curación abundante y abuso junto a enemigos fuera de duelo: MEDIUM pendiente de playtest.

## MISIONES

Nueve principales y seis secundarias; documentos es obligatoria por dependencia pese a etiqueta secundaria. Se corrige entrega y compatibilidad de derrota; no se eliminan, trasladan ni reordenan misiones. Ruta exacta y tabla por misión en auditoría; checklist individual en PLAYTEST_1_0.md.

PACING ISSUE: repetición computador/subir en 3–7, vuelta por documentos si se ignora Profesor, recorrido inicial largo, densidad de HUD y falta de clímax final NEXO. No se añaden misiones para rellenar duración.

## MINIJUEGOS

Archivos 6–8 decisiones, Antivirus 8–12 aciertos/máximo dos virus, contraseña 4–5 dígitos. Clases actuales opcionales de Programación/Redes/Inglés; horario 10 s reales por minuto, sin bloqueo por faltar. Parámetros conservados. Tiempo/dificultad humana y accesibilidad de memoria/reacción pendientes.

## UI Y TUTORIAL

B05: cola máxima 16, deduplicación, prioridades CRITICAL/MISSION/REWARD/INFO; crítico interrumpe conservando aviso pendiente. Los avisos esperan mientras modal/intro ocultan el HUD. API notify anterior compatible. B07: tutorial espera a oportunidad sin modal, duelo o avisos pendientes. No se añade otro sistema de tutorial.

## RENDIMIENTO

B06: filtro de piso antes de métodos contextuales y distancia al cuadrado antes de raycast. 100 consultas en spawn: media 2001,69 → 605,51 µs (~70% en esa muestra); frecuencia 0,08 s conservada y 60 comprobaciones contextuales aprobadas. No es una mejora medida de FPS global.

Headless: 5577 ms hasta frame 120, 368,11 MiB de memoria estática, 44631 nodos, 15844 recursos. No mide GPU/VRAM ni rendimiento con render. Benchmark ahora evita leer/escribir partida del usuario. No se reestructura Main ni se implementa streaming. Medir pisos/render antes de proponer separación de escenas.

## GUARDADO

save_version=2 y migración existentes conservados; no nuevo formato incompatible. Pruebas: JSON real en fixture de duelo, estado del mundo consistente con inventario, checkpoint/snapshot, recompensas únicas, nueva partida, versiones futuras y lector con respaldo de JSON inválido. La regresión de campaña incluye cierre de escena y carga real. Cierre de aplicación con ventanas/render debe comprobarse manualmente.

La telemetría permanece opt-in, local, limitada; no hay tiempos de campaña o muertes humanos inventados. Los fixtures no escriben la partida del usuario.

## VALIDACIÓN

Antes de corregir B01–B03: cuatro reproducciones fallaron; después pasan. Suite nueva final: 20/20. También pasan gameplay_regression, inventory_regression, campaign_regression, Chef, Director, Redes 38, horario 27, celular 31, campus 52, Personajes 2.0 59, interacciones 60, nueva partida, lector de guardado y revisión de 219 scripts/recursos. Registros balance-*.log en .godot. Arranques MCP sin errores de runtime observados; dos avisos del modo embebido impiden mover/redimensionar ventana, revisar ejecución independiente. Warnings de JSON corrupto en el test del lector son deliberados.

## RECOMENDACIONES

1. Seguir PLAYTEST_1_0.md de inicio a archivo final y registrar tiempos por tramo/boss; NEXO no puede marcarse aprobado.
2. Priorizar duración real de bosses, abuso de centros fuera de duelo y recorrido 3→5; ajustar solo con esas mediciones.
3. Medir FPS y profiler por piso, 1080p/1440p, modos de ventana y tres presets; no deducir FPS desde headless.
4. Revisar las nueve sillas sin candidato local y todas las rutas de acceso; no hacerlas decorativas automáticamente.
5. Diseñar futuro cierre NEXO fuera de esta etapa, conservando las dependencias actuales. No añadir horas artificiales mediante HP, espera o backtracking.

## CIERRE DE CAMPAÑA 1.0 — actualización 16-10-2026

La recomendación de crear el final se implementó en esta nueva etapa autorizada: archivo intermedio, misión nexo_final, acceso y arena en una bahía existente del este de −1, boss NEXO no humano, tres fases, tres terminales, victoria/créditos/estadísticas y postgame restaurado. No se añadieron los modos/bosses ausentes ni se reconstruyó el edificio.

Las nueve sillas no tenían IDs faltantes: la muestra a 0,9 m chocaba con asientos/respaldo o escritorios. La validación ampliada pasa 779/779 y la suite recoge los nueve casos reales sin duplicación. No se cambió mobiliario ni ID.

**NEXO: 1200 HP iniciales, PENDIENTE DE BALANCE HUMANO.** Fases 70%/35%, protección parcial por tres enlaces y obligación de desactivarlos; Protocolo de Borrado con aviso 2 s y 30 daño, no muerte instantánea. RouterPortatil y USB reales facilitan el encuentro sin ser obligatorios. Configuración completa y razones en BALANCE_1_0.md y [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md).

Se conserva BossRetry, la política de guardado pre-duelo, rewards/ledger y migración de save_version 2. El final guarda campaign_completed, bosses.nexo y misión antes de la secuencia; al cargar NEXO permanece derrotado. Partidas antiguas conservan archivo/recompensas/cosméticos y reciben una principal final pendiente, sin restaurar el campus prematuramente.

Se compararon reportes antes/después: idénticos valores de las 23 armas, consumibles, nueve enemigos, HP de los cinco bosses anteriores y precios. XP, estadísticas y recompensas anteriores no se rebalancearon. El nuevo boss usa los 75 créditos/150 XP estándar; su misión no duplica recompensa.

Pruebas aprobadas: suite NEXO 111; balance 20; campus 52; Personajes 2.0 59; interacciones 60; Redes 38; horario 27; celular 31; además campaña con carga real, inventario, gameplay, Chef, Director, nueva partida y lectura/migración de guardado. Revisión 226 scripts/recursos. Capturas con toolkit confirmaron presentación básica/diálogo/barra/fase 3 en una fixture aislada, sin afirmar victoria humana o balance.

Pendientes: ruta física desde archivo, visibilidad con HUD/cámara, velocidad de lectura/reacción, seguridad de terminales, primera victoria, dificultad sin opcionales, rendimiento gráfico, créditos y cierre/reapertura reales. La duración anterior de campaña no incluye este final nuevo; cronometraje pendiente. Checklist **FINAL NEXO** en PLAYTEST_1_0.md.

## Correcciones de actividades, guardado y Chef — 16-10-2026

Esta actualización reemplaza los valores y actividades anteriores que se conservan como registro histórico.

- FIX: Actividades por piso. pc4 (game_id 2): organización docente; pc5 (0): vocabulario de Inglés; pc6 (2): comprensión lectora de Lenguaje; pc7 (1): decisiones de Ética; pc8 (2): revisión documental NEXO. Reutilizan la clasificación existente, su señal completed y el circuito finished(success). No se renumeran game_id, campaign_id, quest_id ni eventos computer:ID. pc_intro, pc3 y pc_secreto conservan sus juegos. Director permanece en piso 8.
- FIX: Apuntes. Apunte_datos pasa de piso 4 a 3, Apunte_redes de 6 a 3 y Apunte_ia de 8 a 3. Apunte_programacion ya estaba en 3. Se conservan world_id, item_id hoja_impresa, textos y flags collected; no se duplican.
- FIX: Error de autoguardado. Se comprueban apertura, escritura/flush, copia .bak y reemplazo .tmp → definitivo. Un fallo no marca éxito ni borra original/backup/temporal recuperable. Consola registra ruta y error; jugador recibe «No se pudo guardar la partida.» una sola vez por racha de fallos. Tras guardar correctamente se habilita un nuevo aviso. Nueva partida reutiliza el mismo escritor.
- FIX: WorldItem parcial. Se descuenta solo la cantidad aceptada; el sobrante permanece visible/interactivo y muestra xN. Solo al agotarse se marca collected y se emiten eventos de recogida especial/apunte. El JSON añade remaining_quantity[world_id]; collected sigue siendo booleano. Saves antiguos sin cantidad usan el valor original, salvo collected=true. Respawn explícito mantiene su comportamiento. Save_version sigue en 2 y el snapshot previo al boss incluye el nuevo diccionario.
- BALANCE: Chef Supremo HP reducido de 450 a 350, tanto actor como BossDuelController de Main.tscn. Tres fases conservadas a 60% y 30% (210/105 con el nuevo máximo). No cambian daño, velocidad, ataques, bandejas, cooldowns, recompensas, economía, XP, precios ni otros bosses.

Validación nueva: tests/CampusFixesCheck.tscn y tests/campus_fixes.gd. Reporte de ejecución: reports/campus_fixes_result.json. Incluye inventario real lleno, 5 → acepta 2 → quedan 3, guardar/cargar campaña real, recoger sobrante, saves antiguos, claves, IDs/señales de los cinco perfiles, desbloqueos 7/8, apuntes, HUD/fases/reset Chef y fallo de reemplazo inyectado. Los errores de consola provocados expresamente por el test de guardado son esperados.

PENDIENTE DE PRUEBA MANUAL:

- [ ] Recorrer los pisos 3–8; comprobar accesibilidad de apuntes y lectura de actividades a distintas resoluciones.
- [ ] Completar la ruta de campaña jugando cada actividad; verificar ascensores y puertas con una partida personal respaldada.
- [ ] Chef: comprobar HUD 350/350, morir/reintentar y continuar una partida anterior; evaluar dificultad humana manteniendo el resto del balance.
- [ ] Probar aviso discreto ante un fallo real de disco/permisos y recuperación; la inyección automática no simula un corte de energía.
- [ ] Recoger parcialmente un lote en juego, salir/reabrir y recoger el resto tras liberar espacio.

Los resultados automáticos concretos y sus límites se registran a continuación; las casillas manuales permanecen pendientes.
Resultado automático verificado (16-10-2026): nueva fixture ejecutada mediante godot-mcp-toolkit: 73 comprobaciones, cero fallos (reports/campus_fixes_result.json). Regresiones aprobadas con resultados finales sin fallos en los logs: campaña, inventario, gameplay, Chef 350 HP, balance (20), lector de guardado, nueva partida, NEXO (111) y organización (9 pisos/596 rutas de nodos). Revisión de carga: 227 scripts/recursos. Los logs son tests/fixes_*.log (ignorados por Git); no se confunde la salida temprana del ejecutable gráfico con éxito: se comprobaron los marcadores de resultado de cada archivo.

FIX visual adicional demostrado con captura MCP: la capa de minijuegos (antes 20) quedaba debajo del HUD de inventario (26) y campaña (40). Ahora es 50; las opciones quedan delante del HUD. Se inspeccionaron Lenguaje y NEXO con renderizado. No altera estadísticas ni mecánicas. Las pruebas humanas completas y otras resoluciones siguen pendientes.
## BOSSES DE ACCIÓN Y PERSONAJES — actualización 16-10-2026

Estado actual: 16 misiones existentes y nueve bosses (seis anteriores + Profesor de Inglés/Piso 5, Lenguaje/Piso 6 y Ética/Piso 7). Los nuevos duelos son de acción, voluntarios al aceptar E/diálogo y con fases al 60%/30%; no son cuestionarios. HP iniciales 450/500/550, TODOS PENDIENTES DE PLAYTEST HUMANO. Director existente conserva 700 HP y añade FIREWALL/ACCESO DENEGADO con avisos; Chef permanece en 350 HP. No se cambian armas, consumibles, enemigos normales, precios ni recompensas anteriores. Los nuevos bosses usan premios académicos/cosméticos y el premio estándar existente de boss.

Computadores pc5/pc6/pc7/pc8 mantienen actividades de Inglés/Lenguaje/Ética/documentos NEXO, game_id 0/2/1/2, campaign_id, flags y señales. Son preparación opcional: ENGLISH_PREPARED retrasa 2 s el siguiente ataque tras Word Rush; LECTURA_PREPARADA reduce duración/ralentización de tinta; REFLEXION_PREVIA amplía elección física de zonas de 6 a 10 s; NEXO_INFORMATION reduce HP de los dos virus del Director de 50 a 40 al invocarlos. Las misiones academico5/seguridad6/acceso7/direccion conservan IDs, recompensas y cadena; los bosses pasan a ser su objetivo de acción. Los estados completados antiguos y desbloqueos se conservan. La puerta acceso7 sigue necesitando TarjetaAcceso. No se marca un computador como resuelto por vencer al boss.

Ética usa zonas físicas A (+20% daño, −15% defensa) y B (+20% defensa, −15% daño), sin opción correcta ni preguntas. Los efectos están limitados a su duelo y se limpian al reset. Todos reutilizan BossDuelController, guardado pre-duelo, checkpoint/BossRetry, recursos/arma/desgaste/quickslots, curación y premio único. No se reconstruyen pisos; ubicación con cápsula/suelo/rayos de continuidad. Ninguna prueba automática certifica el recorrido físico humano.

CharacterVisual amplía el rig y adaptador GLB existentes: torso/ojos más discretos, ropa articulada, camisa/sweater/chaqueta/uniforme ficticio/overol, pantalón/calzado, colores de mochila, audífonos/bolso/insignia/dispositivo. Perfiles estables por ID y guardados; no autoequipa premios al protagonista. AnimationTree importado conserva blend de locomoción y transiciones de salto/caída/aterrizaje; sin clips reales se mantiene fallback procedural. BLOCK/PARRY son soporte visual, no nuevas mecánicas. LookAt, diálogo/cámara y LOD se reutilizan; no se descargan assets.

Detalles y scripts: [BOSSES_SUPERIORES_2_0.md](BOSSES_SUPERIORES_2_0.md). Ropa, estados, workflow GLB y assets faltantes: [PERSONAJES_2_0.md](PERSONAJES_2_0.md). Prueba nueva: tests/UpperCampusCheck.tscn; resultados en reports/upper_campus_result.json. Las pruebas humanas siguen pendientes en PLAYTEST_1_0.md. Las secciones anteriores son historial y no deben usarse como valores actuales cuando difieran de esta actualización.
### Validación de esta ampliación

Godot 4.7.2, mediante godot-mcp-toolkit y ejecutable del editor (sin depender de PATH). Preview de nueve roles: sin fallos. Suite nueva UpperCampusCheck: 104 comprobaciones, sin fallos; nueve muestras transitables por arena, neutralidad/aceptación, fases 60/30, proyectiles/zonas con límites y sin daño anticipado, ventajas, elección física A/B, reintento real, premios únicos, guardado/carga, identidad/ropa, LOD y compatibilidad de etapas completadas.

Regresiones aprobadas y verificadas por marcador final del log: personajes (70), personalización, campaña, inventario, gameplay, Director, Chef 350, Campus Vivo (52), balance (20), nueva partida, NEXO (111), interacciones (60), recogidas parciales/guardado previo (74) y carga de 236 scripts/recursos. Logs tests/upper_*.log; los errores deliberados de fixture de escritura no se confunden con errores de partida. No basta el código de salida del ejecutable gráfico de Windows.

Medición orientativa headless: frame 120 a 5133 ms, 377,69 MiB de memoria estática, 45120 nodos; no es FPS gráfico ni comparación controlada con versiones anteriores. Una muestra estabilizada de la fixture renderizada en Piso 5 dio 19 FPS, 58,14 ms de proceso/2,81 ms de física y ~2132 MiB tras dos cargas de Main. Esa muestra no certifica rendimiento general ni 60 FPS: hace falta profiler/recorrido humano con hardware, resolución/calidad y memoria GPU controlados. La muestra de 1 FPS registrada justo al recargar corresponde al pico de carga, no al combate jugable.

Capturas MCP revisaron variantes de ropa y presentación neutral de Inglés. La apariencia continúa procedural/estilizada; no se afirma realismo fotográfico. Quedan manuales todos los casos añadidos al checklist: caminar/saltar/escaleras/armas, ropa y apariencia al cargar, NPC sentados, cámara, combate real con/sin preparación, rutas/puertas/arenas, muerte/reintento mediante UI, lectura de telegraphs, dificultad y FPS. Ninguna casilla humana se marca PASS.
## OPTIMIZACIÓN + PERSONAJES REALISTAS 3.0 — 16-10-2026

SIN REBALANCEO. HP preservados: Chef 350 / Inglés 450 / Lenguaje 500 / Ética 550 / Director 700. Daño, armas, consumibles, economía, XP, misiones y premios sin cambios en esta etapa. Todos los bosses siguen PENDIENTES DE PLAYTEST HUMANO.

Perfil controlado: PERFORMANCE_PROFILE.md y reports/performance_*.json. Alcance de sombras acotado, LOD/SLEEP visual, geometría compartida, HUD por cambios y adaptador GLB ampliado. Los resultados de una fixture quieta no certifican FPS de campaña ni dificultad. El checklist manual añade FPS por piso, patrones de bosses y personajes; ninguna casilla se marca PASS automáticamente. No se introduce pooling: el aislamiento no lo justifica y ya existen caps/lifetimes; mantener lifecycle explícito reduce riesgo de estado residual.

FIX de estabilidad: AcademicBossZone expira incluso si su objetivo muere/desaparece; detiene procesamiento al retirarse. Firewall tiene guardia de instancia única, sin cambiar cooldown ni daño.
