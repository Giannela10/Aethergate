# Correcciones de campus, guardado, WorldItem y Chef

Fecha: 16-10-2026. Proyecto: DuocGames. Godot 4.7.2.

## Cambios e IDs

| Piso | Computador | game_id conservado | Antes | Ahora |
|---|---|---|---|---|
| 4 | pc4 | 2 | Contraseña | Organización de documentos docentes |
| 5 | pc5 | 0 | Clasificación por extensiones de archivos | Vocabulario de Inglés |
| 6 | pc6 | 2 | Contraseña/seguridad | Comprensión lectora de Lenguaje |
| 7 | pc7 | 1 | Antivirus | Decisiones cotidianas de Ética |
| 8 | pc8 | 2 | Contraseña | Revisión documental narrativa NEXO |

Se reutiliza game_files.gd mediante perfiles; no se crean nuevos números de minijuego. Se conservan campaign_id, nombre de nodo, completed, finished(success), data.computers[ID], eventos computer:ID, requisitos/recompensas/desbloqueos de todas las misiones, incluyendo academico4, academico5, seguridad6, acceso7 y direccion. pc_intro=0, pc3=1 y pc_secreto=1 no cambian. El Director permanece en el piso 8. No se reubican computadores, NPC, bosses ni geometría.

Apunte_datos (4→3), Apunte_redes (6→3) y Apunte_ia (8→3) conservan sus world_id y el item_id hoja_impresa. Apunte_programacion permanece en 3. Se conserva el texto/pista y el flag de encontrado; posición validada por el mecanismo existente de suelo y cápsula. Un apunte ya encontrado no reaparece tras cargar.

## Persistencia

El escritor compartido de autoguardado y Nueva partida comprueba apertura, escritura/flush, copia del original a .bak y código de reemplazo de .tmp. No elimina el definitivo antes de renombrar. Si falla, last_save_succeeded=false, se conservan original/backup/temporal y se registra ruta/error en consola. La UI muestra solamente «No se pudo guardar la partida.» una vez por racha de fallos; un guardado correcto reinicia la supresión de avisos.

WorldItem resta la cantidad realmente aceptada. El sobrante sigue visible e interactivo con contexto xN. Solo al llegar a cero se oculta/desactiva y se marcan recogida y eventos especiales. Se conserva data.collected[world_id] como booleano y se añade data.remaining_quantity[world_id] como cantidad restante. Sin ese campo se usa la cantidad original; collected=true tiene prioridad. Respawn explícito se conserva. Save_version sigue en 2. Los snapshots previos al duelo duplican la campaña completa e incluyen el nuevo diccionario.

## Chef

Antes: 450 HP en chef_supremo_casino.gd y 450 en BossDuelController de Main.tscn. Ahora: ambos 350. HUD probado 350/350, carga neutral y reset a 350/fase 1. Fases porcentuales intactas a 60%/30% (210/105 HP). Daño, movimiento, ataques, bandejas, tiempos, recompensas, precios, XP, consumibles y demás bosses no se rebalancean.

## Validación

- Fixture nueva ejecutada desde el editor mediante godot-mcp-toolkit: **73 comprobaciones, cero fallos**. Resultado final en [campus_fixes_result.json](campus_fixes_result.json).
- Inventario real: stack 997/999, lote de 5, acepta 2, conserva 3; escritura/recarga real de Main y campaña; inventario lleno no reduce sobrante; liberar 3 y recoger las 3 restantes; persistencia de agotado; saves antiguos y respawn.
- Los cinco perfiles terminan por la misma señal una sola vez; flags/eventos originales y desbloqueos 7/8; claves protegidas; apuntes movidos seguros y encontrado persistido; Chef/HUD/fases/reset.
- Fallo de reemplazo inyectado y fallo real de apertura de temporal: original/backup/temporal, indicador de fracaso, texto discreto y supresión de avisos repetidos; recuperación de escritura.
- Revisión de carga: 227 scripts/recursos, sin fallos.
- Regresiones aprobadas: campaign_regression, inventory_regression, gameplay_regression, chef_supremo_casino, balance_regression (20), guardado_lectura, nueva_partida, nexo_final (111), organizacion_pisos (9 pisos y 596 rutas de nodos). Se verificaron los marcadores finales de tests/fixes_*.log, no solamente la salida temprana del ejecutable gráfico de Windows.
- Capturas MCP de Lenguaje y NEXO: contenido legible. Se demostró y corrigió la superposición del HUD sobre las opciones subiendo la capa de minijuegos de 20 a 50, sobre inventario 26/campaña 40 y debajo del celular 55. Sin cambios mecánicos.

Los errores de escritura de la fixture y advertencias del lector de JSON inválido son deliberados. Las pruebas usan persist=false/test_mode y rutas aisladas del proyecto; no sobrescriben la partida personal.

## PENDIENTE DE PRUEBA MANUAL

- Recorrido humano completo de campaña y accesos físicos de ascensores, puertas y apuntes.
- Actividades completas con entrada humana y distintas resoluciones.
- Chef: dificultad, muerte/reintento completo desde UI y continuación de partidas personales anteriores; los tests de HP/reset no son un playtest de combate.
- Recogida parcial/salir/reabrir en una partida de juego y fallo real de permisos/disco. La inyección no simula cortes de energía.

Documentación actualizada: RESUMEN_JUEGO.md, BALANCE_1_0.md, BALANCE_REPORT_1_0.md y PLAYTEST_1_0.md. Las cifras anteriores se conservan como historial explícito de auditoría; el checklist y recorrido actual del resumen se actualizaron.
