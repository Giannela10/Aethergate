# Optimización + personajes realistas 3.0

## Método y evidencia

Godot 4.7.2, Compatibility/OpenGL, NVIDIA GTX 1050 (driver 560.94). Fixture renderizada `tests/PerformanceProfile.tscn`, que hereda la fixture anterior: dos cargas de Main, 104 comprobaciones de bosses/campaña, luego `preview_boss("profesor_ingles")`. Misma posición, cámara, calidad ALTO y ventana del editor; jugador/física y GameplayDirector se detienen igual que en la fixture original. No representa un combate jugado ni nueve pisos recorridos. No comparar sus FPS con headless.

Histórico: muestra puntual 19 FPS / proceso 58,142 ms / física 2,81 ms. Reproducción inicial MCP: 20 FPS / 52,11 ms / 2,637 ms. Tras estabilización, cuatro muestras antes de optimizar: **36, 41, 41, 40 FPS**; proceso 30,341 / 23,461 / 23,644 / 24,874 ms. La variación impide prometer una mejora partiendo de un único 19.

Datos crudos: `reports/performance_before.json`. La primera sonda parcial (`performance_initial_partial_scope.json`) solo censaba hijos de CampusCampaign: **no** es el censo del campus ni un aislamiento completo de sombras. Se corrigió el alcance a Main antes de concluir.

## Aislamiento reversible, sin cambios de gameplay

| Experimento en la misma vista | FPS (4 muestras) | Draw calls aproximadas |
|---|---|---|
| Original, sombras a 100 m | 36 / 41 / 41 / 40 | 22.036–22.084 |
| Sin callbacks visuales de 15 NPC/bosses/controladores | 40 / 40 / 39 / 40 | 22.091 |
| Sin sombras de luces, solo diagnóstico | 65 / 65 / 65 / 64 | 1.346 |
| MeshInstance3D ocultos, solo diagnóstico | 65 / 65 / 65 / 65 | 631 |
| Restaurado | 39 / 38 / 39 / 36 | 21.905 |

La sonda restaura los estados de luces/meshes/proceso; no guarda estas ablaciones en partidas. Ocultar MeshInstance3D no elimina CSG, Label3D ni toda la geometría, por eso quedan draw calls. El aislamiento de callbacks no incluye todos los scripts de bosses antiguos: no prueba coste cero de todos los personajes.

**Cuello demostrado en esta fixture: envío/renderizado de sombras del campus.** La única luz con sombras es LuzExterior, DirectionalLight3D con alcance previo de 100 m; se dibujan muchos objetos de otros pisos en mapas de sombra. No hay evidencia de que blink, LookAt, partículas o NavigationAgent expliquen los 19 FPS. CPU de física ~3 ms es mucho menor que proceso total, pero TIME_PROCESS incluye costes de frame/driver y no es un perfil exclusivo de scripts.

Clasificación estricta **DESCONOCIDO (CPU de render/driver frente a GPU)**: las ablaciones señalan el subsistema, no separan ambos procesadores. Tiempo GPU no disponible en esta captura; no inferir GPU BOUND solo por ser sombras. El techo observado ~65 FPS tampoco demuestra margen ilimitado.

## Censo del campus cargado

45.125 nodos, 24.213 MeshInstance3D, 510 luces (1 con sombras), 14 AnimationTree, 14 Skeleton3D, **0 NavigationAgent3D**, 0 GPUParticles3D y 0 CPUParticles3D. Los Skeleton reservados no equivalen a rigs humanos animados. Objetos renderizados del monitor: ~23.000 antes; incluye pases, no es conteo único de NPC visibles. No se confunde cantidad total de nodos con cantidad procesando.

1.671 materiales override distintos; 316 firmas aproximadas de color/roughness/metallic/textura/emisión. Esto no cuantifica duplicados equivalentes: no incluye todas las propiedades ni los materiales de superficie. La ropa usa caché por personaje y flash de daño modifica esos materiales: compartirlos globalmente sin separar el flash contaminaría otros personajes.

Las sillas no tienen _process/_physics_process ni Area3D propio para recoger. Conservan colliders e interacción contextual por cercanía. Sus meshes pueden participar en sombras; no se atribuye un coste específico de sillas sin ablarlas por separado. El escaneo contextual optimizado anterior se conserva.

## Grupo 1: alcance de sombras

Mantener sombras del sol activas y reducir alcance ALTO a 40 m, MEDIO 30 m, BAJO 20 m mediante ajustes existentes. No ocultar pisos, eliminar NPC, cambiar colisiones ni apagar todas las sombras. A/B en la misma instancia con 40 m: 58 y 61 FPS, proceso 17,760 / 15,979 ms (datos `performance_shadow40_probe.json`). Revisión visual exterior/escaleras y popping de sombras: pendiente humana.

## Grupos siguientes y comparación controlada

| Estado de la misma fixture/vista | FPS de las cuatro muestras iniciales | Draw calls |
|---|---|---|
| Antes, sombras 100 m | 36 / 41 / 41 / 40 | 22.036–22.084 |
| Grupo 1, sombras 40 m | 65 / 65 / 60 / 57 | 8.380–8.429 |
| Grupo 2, LOD/SLEEP y geometría compartida | 66 / 65 / 65 / 64 | 8.380 |
| Grupo 3, adapter/HUD/blink/lifecycle | 65 / 65 / 65 / 65 | 8.288–8.380 |

Archivos: `performance_group1.json`, `performance_group2.json`, `performance_group3.json`, `performance_after.json`. Las ventanas cortas y el techo ~65 FPS limitan la atribución incremental de los grupos 2/3; no afirmar que cada microoptimización aporta FPS por separado. Proceso final típico ~15,4 ms con muestras de ~28,8 ms; física ~2,5–3,1 ms. No son percentiles ni tiempos GPU.

Censo final: 45.184 nodos (timers/sockets añadidos), mismos 24.213 MeshInstance3D, 510 luces y 1 luz con sombras. 188 callbacks _process y 99 de física habilitados en la captura: no incluyen todos los procesos internos del motor ni significan callbacks ejecutando trabajo completo. 30 visuales registrados; en la vista final 3 LOD0, 0 LOD1, 3 LOD2 y 24 SLEEP. La instantánea anterior tuvo 2/1/3/24 por distancia/postura; no eliminar personajes para mejorar cifras.

LOD0 completo; LOD1 intervalo 0,12 s, sin secundarios; LOD2 0,5 s, sin mirada/expresiones/props secundarios; SLEEP omite rig y detiene AnimationTree importado. FloorActivityManager revisa el presupuesto cada 0,35 s: mismo piso FULL, vecino REDUCED, más de 18 m verticales SLEEP; también se usa distancia. El host mantiene lod_level 2 en otro piso para compatibilidad y expone visual_activity=SLEEP por separado. No se desactivan nodos de misión, guardado, horarios o interacción. Player, intro/combate, impactos y caída de muerte conservan animación crítica. Enemigos normales de otro piso omiten percepción/movimiento y recuperan actividad al acercarse; la lógica de duelos no se duerme.

AnimationTree importado solo cambia de estado/blend cuando hace falta, se desactiva al dormir y recupera al volver. Sockets resueltos se cachean. Procedural: blink usa Timer pausado por distancia; ojos/expresiones usan cambios; meshes primitivos idénticos comparten recurso. Materiales de daño permanecen por actor. Se compone el objetivo HUD una vez y se asigna solo al cambiar. Inventario cerrado ya solo actualizaba su toast; celular cerrado no reconstruía UI cada frame. No se alteró el escaneo contextual existente. 779 sillas siguen con recogida y colliders, sin callbacks continuos propios.

LOD2 del modelo importado desactiva el avance automático de AnimationTree y muestrea la pose con `advance` en el tick reducido del host. LOD1 conserva locomoción básica; SLEEP no avanza. Esto se valida con rig sintético: no se atribuye una ganancia medida a GLB, porque no hay humano importado real en la fixture. Animaciones críticas evitan que un personaje dormido conserve una pose incorrecta tras daño/muerte.

## Ataques superiores: carga sintética después

`reports/performance_boss_patterns.json`: patrones repetidos cada 0,8 s, cámara por arena, IA principal suspendida y vida de jugador elevada SOLO en fixture para observar efectos. Conserva advertencias y expiración. No es mismo escenario que baseline quieto ni compara contra ataques anteriores.

| Arena / patrones | FPS capturados | Física ms |
|---|---|---|
| Inglés: Vocabulary Storm + Word Rush | 65 / 65 / 64 / 63 | 7,5–9,7 |
| Lenguaje: Tormenta de Páginas + tinta | 65 / 61 / 65 / 61 | 7,8–9,9 |
| Ética: zonas A/B + Dilema | 61 / 61 / 64 / 66 | 3,0–3,4 |
| Director: Firewall + Acceso Denegado + virus | 62 / 57 / 57 / 60 | 3,3–5,4 |

Inglés/Lenguaje aumentan física en esta carga sintética: revisar profiler de colisiones/barridos antes de agregar proyectiles. Director cae hasta 57 en esta ventana; no prometer 60. Se preservan caps de 6 proyectiles/5 zonas académicos (tinta incluida), dos zonas Director, dos virus; Firewall ahora tiene guardia explícita de uno. Ética crea dos zonas una vez, sin generación por frame. Las zonas se retiran sin callbacks al expirar, incluso si falta objetivo. No hay partículas en el censo. Pooling no implementado: no se demostró que creación/destrucción fuese el cuello principal; introducirlo ahora añade riesgo de estado residual.

## Límites y pruebas humanas necesarias

No hay perfil GPU ni tiempo por función de script; clasificación CPU/GPU continúa DESCONOCIDO. Faltan recorridos representativos por todos los pisos, exteriores, escaleras, encuentros completos y hardware alternativo. Muchas luces (509 sin sombras) y miles de objetos siguen cargados; no se apagaron luces que puedan revelar accesos ni se escondieron pisos. No se eliminaron colliders. El coste específico de sillas y materiales de superficie requiere otra captura controlada. Antes de ampliar campus o NPC, revisar render y física por arena; primero un piloto GLB con presupuesto de huesos, superficies y texturas medido, después multiplicarlo.

Regresión detectó un fallo introducido por limitar delta visual: restaurar un boss derrotado avanzaba solo 0,5 s. Se corrigió conservando delta completo para animaciones críticas y se añadió comprobación específica. Ningún resultado automático equivale a PASS manual. Resultados finales de suites se registran en `reports/performance_validation.json` al terminar.

Recomprobación final con UpperCampusCheck desde MCP: 104 checks sin fallos; al cambiar cámara se capturó 24 FPS / 44,438 ms, y tras estabilizar 65 FPS / 15,594 y 16,233 ms (`performance_final_recheck.json`). No ocultar este transitorio ni interpretarlo como mínimo de una sesión completa. La comparación antes/después usa las ventanas estables del mismo procedimiento de sonda, no esta muestra inmediata.

Validaciones finales: personajes 3.0 (23), personajes anteriores (70), fixes/guardado parcial (74), bosses superiores (104), CampusLive (52), NEXO (111), interacción (60), balance (20), comparación de capturas (6), carga de 237 scripts/recursos; además campaña, inventario, gameplay, personalización, Chef, Director y nueva partida sin fallos finales. Los tres errores de guardado en CampusFixes son inyecciones intencionales verificadas. Logs `tests/perf3_*.log`; JSON consolidado `reports/performance_validation.json`. El juego de prueba queda detenido.

Scripts nuevos: `scripts/live/floor_activity_manager.gd`, `tests/performance_profile.gd`, `tests/performance_regression.gd`, `tests/characters3.gd`; escena de sonda `tests/PerformanceProfile.tscn`. Se modifican presupuesto en campus_live/campus_settings; visuales humanoid/student_visual/imported_character_visual/character_visual_presets; HUD en campus_campaign; percepción en campus_enemy; callback neutral en boss_duel_controller; expiración en academic_boss_zone y guardia Firewall del Director. `tests/personajes2.gd` añade geometría al rig sintético: un rig vacío ahora se rechaza para no ocultar el fallback.
