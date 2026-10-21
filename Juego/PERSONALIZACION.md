# Etapa 1: personalización

Implementada con godot-mcp-toolkit sobre StudentVisual y la campaña actuales.
No se reconstruyeron movimiento, combate, inventario, duelos ni edificio.

## Uso

- Menú inicial → Nueva partida → Comenzar nueva partida → PERSONALIZACIÓN.
  La partida anterior solo se reinicia después de confirmar la apariencia.
- Esc → PERSONALIZACIÓN permite cambiar la apariencia durante la partida.
- Seleccionar opciones con ratón; deslizador para girar la vista previa.
- Confirmar aplica y guarda; cancelar descarta cambios. Desplazarse hacia abajo
  para ver todos los campos y los botones de confirmación.
- Piel, cabello, color de cabello, polera/polerón, colores de ropa, pantalón,
  zapatillas, mochila y accesorios. Son variantes procedurales sencillas.

## Scripts y nodos

Nuevos scripts de producción:
- `scripts/juego/character_appearance.gd`: catálogo, validación y desbloqueos.
- `scripts/juego/procedural_appearance_adapter.gd`: aplica materiales y accesorios.
- `scripts/campaign/appearance_menu.gd`: selección y vista previa.

Modificados: `student_visual.gd` añade `apply_appearance(profile)`;
`campus_campaign.gd` conecta Nueva Partida, pausa y campos de guardado.

Nodos creados en ejecución: `CampusCampaign/Personalizacion`, contenedor de vista,
SubViewport con mundo propio, StudentVisual de vista previa, cámara, luz,
WorldEnvironment, deslizador y selectores. Los accesorios son mallas sin colisión.
No se agregaron nodos ni geometría a ningún piso de Main.tscn.

## Cosméticos

| Progreso existente | Desbloqueo |
| --- | --- |
| Profesor de Redes | Mochila Informática y accesorio Telecomunicaciones |
| Chef | Delantal del Chef |
| Bibliotecaria | Polerón Biblioteca |
| Director | Credencial especial |

Se reconocen también bosses derrotados en partidas anteriores.
Guantes, casco, chaqueta mecánica y polerón de campeón tienen representación
procedural y reglas preparadas para futuros bosses `maestro_soldadura`,
`jefe_taller` y `nexo`. Esos encuentros aún no están implementados.
Estos cosméticos no entregan XP, créditos ni estadísticas. Las recompensas
originales de los duelos se conservan.

## Guardado y futuros modelos

Se reutiliza `campus_campaign_v1.json` con campos aditivos `appearance` y
`cosmetics`; no se cambia la versión ni se reemplaza el guardado general.
Partidas antiguas sin esos campos reciben valores por defecto. Nueva Partida
conserva la apariencia base recién elegida y reinicia desbloqueos de esa partida.

La lógica del jugador llama únicamente `body.apply_appearance(profile)`.
Para un modelo humano real, implementar ese contrato en el adaptador visual,
conservar rig/sockets y sustituir la representación procedural. Los datos de
apariencia y el menú pueden mantenerse. No hay modelo humano externo incluido.

## Validación

`tests/nueva_partida.gd`: confirmación, reinicio y apariencia persistida;
`tests/personalizacion.gd`: validación de datos, bloqueos, cancelación,
confirmación, controles y cambios repetidos;
`tests/campaign_regression.gd`: regresión de campaña;
`tests/revision_scripts.gd`: carga de los 178 recursos propios.
Pasaron sin fallos de prueba. Logs `tests/personalizacion*.log`.

`tests/PersonalizacionPreview.tscn` (F6) permite revisar el menú sin leer ni
sobrescribir la partida real. Se revisó visualmente el menú y se ajustó su cámara.
El puente MCP de ejecución devolvió AUTH_FAILED; la captura y las pruebas
headless funcionaron. No se presenta esa limitación como un error del juego.
Los logs headless muestran avisos del registro MCP por permisos y certificados
del entorno. El editor conserva mensajes históricos de MultiMesh y tareas;
esta etapa no los atribuye a personalización ni los considera resueltos.

Prueba manual pendiente: combinar todas las opciones y rotar, confirmar una
partida de prueba, recargarla, moverse/atacar/equipar armas, abrir inventario,
hablar con NPC y comenzar un duelo. Revisar también el menú en otra resolución.

## Próximas etapas

Pendientes las fases 2–35 de la solicitud: base narrativa de NEXO, Profesor de
Programación, ClassroomChallenge, contenido de Salud/profesores, Inglés,
Lenguaje y Ética, auditorio, carrera, Rival, eventos, identidad y desafíos del
subterráneo, bosses de taller, NEXO, final, postgame, trofeos, mapa y pulido.
No se considera implementado contenido futuro por figurar en este documento.
Continuar con historia NEXO base y verificar cada etapa antes de la siguiente.
