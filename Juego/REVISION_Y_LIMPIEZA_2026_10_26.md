# Revisión funcional y limpieza — 26 de octubre de 2026

Se revisaron referencias y símbolos del código propio, se inspeccionaron los caminos de arranque, persistencia e interacción afectados y se ejecutó la batería funcional existente. Se conservaron los cambios que ya estaban presentes en el árbol de trabajo. No se modificaron cuentas, roles ni datos remotos durante esta limpieza.

## Alcance y evidencia

- Análisis estático de 412 archivos fuente y recursos, incluidos 190 scripts de producción con 1.522 funciones. Este conteo representa búsqueda de símbolos y dependencias, no una inspección manual línea por línea de todas las funciones.
- Carga en Godot de 263 scripts/recursos propios y las 40 escenas restantes: sin fallos.
- 48 suites aprobadas; 1.052 comprobaciones con contador explícito, además de pruebas que solo informan éxito/fallo. Ninguna suite fallida en el informe final.
- Cero scripts de producción exactamente duplicados y cero rutas literales de recursos requeridos ausentes detectadas por el auditor. Los destinos de guardado temporal se clasifican aparte.

Resultados reproducibles: `reports/detailed_validation.json`, `reports/detail_*.log`, `reports/code_usage_audit.json` y `reports/scene_reference_check.json`.

## Eliminaciones confirmadas

| Código retirado | Motivo |
| --- | --- |
| `_build_environment`, `_build_floor`, `_build_obstacles` y `_add_block` de `scripts/juego/gameplay_manager.gd` | Generador del escenario de prueba antiguo: llamadas comentadas y ninguna referencia activa. El edificio actual proviene de sus escenas. |
| `power_cut` de `scripts/campaign/campus_audio.gd` | Rutina sin llamadas; los efectos reactivos usados por el juego conservan su implementación. |
| Once miembros de scripts sin lecturas | `point_failures`, `gesture_time`, `expression_before`, `previous_id`, `HAIR_STYLE_IDS`, `CLOTHING_SLOTS`, `TASKS_TOTAL`, `ragdoll_enabled`, `foot_ik_enabled`, `marker_labels` y `room_tick`. Los indicadores de ragdoll/IK no activaban ninguna implementación. |
| Dos `_ready` vacíos | `upper_campus_bosses.gd` y `adaptar_desembarco_tienda.gd`, ambos sin inicialización heredada propia que debieran bloquear. |
| Tres escenas HumanPilot y tres scripts con sus tres UID | Prototipo aislado sin referencias desde la campaña ni desde los ejecutores de regresión. Dependía de `assets/characters/human_pilot/human_pilot.glb`, ausente del árbol de trabajo; sus herramientas fallaban al instanciarlo. Se conservaron las capturas y los informes históricos, y se anotó su estado. |
| `tests/__pycache__/build_balance_docs.cpython-312.pyc` | Caché regenerable de Python. |

Se conservaron las funciones públicas de construcción y diagnóstico del editor y los puntos de extensión que aún tienen una finalidad identificable. El auditor lista 82 funciones públicas con una sola referencia textual para revisión; esta condición no prueba que sean inútiles. Tampoco se eliminaron migraciones, configuración privada, addons, escenas funcionales ni recursos de campaña.

Los `_ready` vacíos de los locales y la sala del piso 3 y de la tienda del piso 5 se conservan deliberadamente: bloquean la inicialización heredada de `piso_8_completo.gd`, que espera nodos de otro tipo de escena. Eliminarlos podría introducir errores al iniciar esos locales.

## Correcciones funcionales

La tecla R recargaba la escena directamente y podía abandonar cambios aún pendientes de confirmación en Supabase. Ahora el camino cloud captura el estado, pausa la simulación y espera el guardado. Si falla, mantiene la escena y ofrece reintentar, seguir jugando o cargar la copia remota. Pulsar R repetidamente no abre reinicios simultáneos.

La recarga cloud también debe indicar que el usuario continúa la campaña. Sin esa marca, el arranque del campus podía programar un regreso al menú. Se agregó la marca tanto al reinicio con R como a la recuperación explícita de la copia remota.

`tests/cloud_campaign_check.gd` cubre ahora 20 comprobaciones, incluidas pérdida de conexión, cambios pendientes, cancelación del reinicio, recuperación del control, confirmación tardía, R repetida, conservación de créditos/apuntes y Nueva partida con respaldo. Usa transporte simulado y no escribe partidas reales.

El ejecutor `tests/detailed_validation.cjs` incluye las dos suites cloud y termina una suite al detectar errores de script en ejecución, para evitar que un error quede esperando el tiempo máximo sin producir resultado. La prueba cloud espera también el intervalo en que Godot deja `current_scene` vacío durante un cambio de escena.

## Funcionalidad ejercitada

| Sistema | Comprobación ejecutada |
| --- | --- |
| Arranque y recursos | Carga de scripts, materiales y escenas; resolución de referencias. |
| Identidad y educación | Login recordado, registro, diagnóstico, roles, respuestas, integración educativa y control de acceso académico mediante fixtures. Consulta real de Auth accesible, sin escrituras. |
| Campaña y progreso | Primera misión, cadena de misiones, recompensas, inventario, lectura de guardados, Nueva partida y respaldo. |
| Combate | Jugador, Chef, Director, jefes académicos, jefes superiores y NEXO. |
| Vida del campus | Celular, horario, interacciones contextuales, personalización, balance y eventos. |
| Distribución y accesos | Nueve pisos y 596 rutas de nodos; biblioteca, auditorio, coordinación, salidas de emergencia, recorrido del piso 5, piso 8 y ascensores/subterráneo. |
| Persistencia cloud | Aislamiento por cuenta, snapshots, errores de red, idempotencia, conflictos, renovaciones, respuestas tardías y reinicio seguro con transporte simulado. |
| Juego renderizado | Movimiento mediante input/física real; apertura de inventario, pausa, mapa y celular; cámara y visibilidad del personaje en escaleras y recogida de objetos. |
| Interfaz renderizada | Capturas de login, registro a dos resoluciones, paneles admin/profesor, biblioteca y coordinación. |

Las pruebas renderizadas aprobaron y generaron capturas en `reports/detail_*.png` y `reports/placement_*.png`. Se inspeccionó además la captura de movimiento del jugador en la entrada. Esto no equivale a revisar visualmente todas las habitaciones.

## Límites pendientes

No se completó una campaña manual de principio a fin ni se recorrió cada pasillo con un jugador humano. La comprobación de rutas de nodos tampoco demuestra por sí sola transitabilidad física universal. Quedan la revisión humana de legibilidad del HUD, colisiones fuera de las rutas ejercitadas, equilibrio de dificultad y rendimiento prolongado en el equipo de destino.

Las suites de roles y cloud emplean fixtures: no certifican nuevamente operaciones con cuentas reales, aislamiento remoto entre dispositivos, SMTP o Google OAuth. El usuario confirmó el funcionamiento de Supabase antes de esta revisión. Tampoco se generó ni probó una exportación distribuible.

Para reproducir el análisis estático: `node tests/code_usage_audit.cjs`. Para la batería funcional: `node tests/detailed_validation.cjs RUTA_AL_EJECUTABLE_GODOT`. Las pruebas con renderizado se seleccionan con el tercer argumento: `visual_detail_check,rendered_gameplay_check,placement_stairs_visual_check`.
