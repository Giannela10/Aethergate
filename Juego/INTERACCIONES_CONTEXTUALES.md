# Campus vivo — fase 1: gestos y sentarse

Se amplía el rig y la interacción E existentes usando godot-mcp-toolkit.
Esta entrega corresponde a la primera fase del orden solicitado; las fases
2–16 no se consideran implementadas por este cambio.

## Gestos

`StudentVisual.play_context_action(tipo)` acepta:
`pickup`, `door`, `computer`, `button`, `elevator`, `sit`, `stand`, `inspect`,
`talk`, `vending`, `workbench`, `read`.

Son movimientos procedurales breves (0,42–0,65 segundos) sobre articulaciones
existentes. No ponen al jugador en busy, no añaden colisiones y no retrasan la
entrega de objetos. Locomoción, daño y ataques tienen prioridad. Con arma se
usa principalmente el brazo libre. Lectura/inspección preparan una pose visible
antes de que una interfaz pause el mundo.

La interacción E conecta los gestos a recogida, NPC/duelos, computadores,
expendedoras, acceso cerrado, ascensor y routers. F prepara lectura de apuntes.
`inspect` y `workbench` son soporte visual para interacciones que los usen:
esta fase no crea un inspector de objetos ni un taller nuevo.

Un interactuable futuro puede definir `context_action() -> String` para indicar
su gesto sin modificar el controlador central ni duplicar la interacción.

## Sentarse: piloto en Piso 2

Se habilitan **Butaca03_01** y **Butaca04_01** del auditorio, ambas existentes.
El registro comprueba suelo y espacio libre antes de habilitar dos butacas;
Butaca03_02 se descartó porque no superó esa comprobación. Si cambia el
escenario, solo se habilitan butacas que sigan siendo seguras.

- E muestra Sentarse y ocupa la butaca.
- E o WASD levanta al jugador. Saltar/atacar/esquivar primero lo levanta.
- Ratón conserva la cámara. P permite celular, I inventario y F apuntes si tiene.
- No se convierten las sillas recogibles en asientos. Sus 779 registros se
  conservan. No se añade procesamiento individual a esas sillas.
- Se comprueban distancia, alcance, suelo y cápsula completa antes de sentarse.
  No se permite sentarse durante un duelo, golpe, esquiva o aturdimiento.
- El asiento reserva ocupante. Solo se ignoran temporalmente las colisiones
  de esa butaca; se conservan las excepciones que ya existían.
- Levantarse busca suelo y espacio válidos. Si el paso está ocupado, espera.
  Recibir daño libera el asiento. Un teletransporte externo cancela la pose.
- La cápsula y la cámara mantienen su configuración. La pose solo dobla las
  piernas y ajusta la altura visual de la cadera.

## Guardado

El estado sentado es transitorio. Al guardar, la posición del jugador se toma
de su salida segura; al cargar aparece de pie, evitando quedar dentro de una
butaca. Se conserva el archivo, versión y resto del contenido del guardado.
No se añaden objetos, XP, créditos ni recompensas por sentarse.

## Archivos

Nuevos de producción:
- `scripts/juego/contextual_pose.gd`.
- `scripts/juego/player_seating.gd`.
- `scripts/campaign/seat_interactable.gd`.

Modificados:
- `student_visual.gd`: API y aplicación de pose tras animación normal.
- `player.gd`: reposo sentado y levantarse antes de atacar.
- `interaction_controller.gd`: gestos y texto de levantarse.
- `player_combat.gd`: levantarse antes de esquiva/ataque con ratón.
- `campus_campaign.gd`: registro, lectura y posición segura al guardar.

Nodos en ejecución: `Player/SeatController` y dos hijos `Sentarse` en butacas.
Main.tscn, geometría, bosses y NPC no se modifican.

## Validación

60 comprobaciones sin fallos en `tests/contextual_interactions.gd`: doce gestos, butacas
reales, acceso, reserva, guardado de salida segura, celular/inventario/apuntes, pose, levantarse con
movimiento, reacción al daño y conservación de inventario/misiones/vida.
Logs: `tests/contextual_contextual_interactions.log`.
Regresión de campaña y 31 comprobaciones del celular pasaron; carga de 183
recursos propios sin fallos. Logs `tests/contextual_campaign_regression.log`,
`tests/contextual_student_phone.log`, `tests/contextual_revision_scripts.log`.

Se corrigieron errores de inferencia de tipos detectados durante desarrollo y
se descartó la butaca sin espacio. Los avisos de certificados/registro MCP del
entorno no son errores de gameplay. No se inventan medidas de FPS.

## Qué probar manualmente

Abrir `tests/ContextualPreview.tscn` y ejecutar F6: arranca en una butaca del
auditorio con persistencia deshabilitada, sin modificar la partida real.
Probar cámara, P, I, E y WASD. En Main, visitar el auditorio del piso 2 y probar
las dos butacas. Guardar sentado y recargar debe dejar al jugador de pie.
Comprobar recogida, conversaciones, expendedora, ascensor, computador y ataque
inmediatamente después de un gesto. Revisar visualmente armas y cosméticos.

## Pendientes de la solicitud

NPCActivityPoint y ampliación de rutinas, conversaciones y reacciones; IA
cooperativa; distracciones; contenedores; aulas; notas académicas; bosses
dinámicos; inspección/códice; cadenas de misiones; campus reactivo; rutas;
ambientación; ayudas; postgame adicional y validadores integrales.
El sistema de notas y sus recompensas todavía no se han añadido en esta fase.
