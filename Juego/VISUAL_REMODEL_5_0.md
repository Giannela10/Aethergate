# Remodelación visual 5.0 — registro de inicio

Fecha: 2026-11-05. Estado: BLOQUEADO antes de la inspección visual.

## Recuperación

- Git estaba limpio al iniciar. Base: `e260d9fa34758acfb7637305e78159fddd9d3038`.
- Copia previa: `../recovery/visual_5_0/campus_before.zip`.
- Incluye Main.tscn, project.godot, scripts, materiales y escenas. No es una copia completa de recursos externos ni del guardado del jugador.
- SHA256: `53A5E3AD938685E261A28E6CFFA0C7ACA38C8663A78AA392CC9C98160F24B360`.
- No se ejecutaron restauraciones, commits ni push.

## Bloqueo comprobado

Se invocaron `scene_get_tree` y `project_get_settings` de godot-mcp-toolkit. Ambas herramientas devolvieron `AUTH_FAILED`: no existe una entrada de registro para la raíz `DuocGames` seleccionada por el servidor MCP. El proyecto Godot está en `DuocGames/Juego/project.godot`.

El README local del toolkit indica iniciar el cliente desde la raíz del proyecto. Su documentación `addons/godot_mcp_toolkit/docs/multi-instance.md` también documenta `GODOT_MCP_PROJECT_PATH` para seleccionar otra raíz. Hace falta reconectar el servidor MCP con `Juego` como proyecto y tener ese proyecto abierto con el plugin activo. La existencia de un proceso Godot no demuestra que esté conectado a este proyecto.

## Inventario de resultados

| Concepto | Resultado de esta intervención |
| --- | --- |
| Problemas visuales confirmados | 0; no significa que el campus no tenga problemas |
| Pisos inspeccionados visualmente | Ninguno |
| Luces corregidas | 0 |
| Carteles corregidos | 0 |
| Objetos reubicados | 0 |
| Materiales mejorados | 0 |
| Duplicados demostrados/eliminados | 0/0 |
| Colisiones corregidas | 0 |
| Scripts y escenas modificados | 0 y 0 |
| Capturas antes/después nuevas | Ninguna |
| Rendimiento antes/después | No medido; sin conclusión sobre FPS, draw calls, triángulos o luces activas |

## Referencias

Se leyeron `AGENTS.md` y el documento `ARQUITECTURA_REFERENCIAS_2026_10.md` para conocer restricciones y referencias históricas. No se inspeccionaron fotografías ni se reutilizaron resultados históricos como pruebas de esta intervención.

## Pruebas

- PASS AUTOMÁTICO: creación del archivo de recuperación y cálculo de SHA256.
- PASS VISUAL: ninguno.
- FAIL: conexión MCP al proyecto seleccionado (`AUTH_FAILED`, dos operaciones distintas).
- PENDIENTE MANUAL / EJECUCIÓN: abrir Main, inspección de subterráneo −1 y pisos 1–8, exterior y todos los sectores solicitados; validar escaleras, ascensores, puertas, accesos, colisiones, recogibles, NPC, profesores, misiones y guardado; ejecutar regresiones disponibles y medir rendimiento en condiciones equivalentes.

## Trabajo pendiente

La remodelación completa sigue pendiente. No se modificó el campus sin la confirmación visual solicitada. Una vez restablecido MCP: capturar e inventariar los nueve niveles y exterior antes de editar; corregir por piso únicamente problemas contrastados con geometría y capturas; validar cada piso y conservar identificadores persistentes, interacciones, estructura, rutas y sistemas de juego. Registrar cada incidencia por piso, sector, objeto, evidencia, corrección y validación. Las incidencias no confirmables permanecerán pendientes.
