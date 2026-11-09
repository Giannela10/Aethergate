# Demo Capstone — recorrido probado de 60–90 segundos

Presentadores: Nicolás Hernández y Giannela Gajardo. Escena probada: **`res://tests/CapstoneDemo.tscn`**. Resultado: [demo_test.json](demo_test.json), 60,688 segundos desde que Main queda listo, 1,30 m recorridos por entrada real, una pregunta respondida correctamente y una práctica registrada, cero pase oficial.

## Preparación exacta

1. Abrir **Juego/project.godot** en Godot 4.7.2. Mantener los archivos actuales del banco generado. No ejecutar seeds ni modificar usuarios remotos.
2. Abrir `tests/CapstoneDemo.tscn`. Grabar la ventana del juego con la herramienta de grabación disponible en el equipo. Ejecutar **esta escena con F6**, no F5: la entrada normal del proyecto es Login y actualmente depende de servicios remotos no verificables.
3. Esperar la carga de Main, observada alrededor de 13,5 s en arranque headless, variable en editor. Empezar el clip útil cuando el jugador ya aparece en el piso 3. La escena realiza el recorrido automáticamente, incluyendo entrada de movimiento, scanner de interacción y señales de los botones reales. No interactuar manualmente durante la grabación automática.
4. Escena aislada con `persist=false`, credencial no persistente y modo de prueba. No modifica la partida habitual ni inicia sesión remota. El guardia de acceso se suspende solo para el inicio diagnóstico en piso 3. El objetivo de campaña «Primer día» puede seguir visible: no fingir que se completó para llegar allí.
5. Al finalizar se muestra MI PROGRESO ACADÉMICO; detener grabación y luego detener la ejecución en Godot. Las escenas de pruebas están excluidas del preset de exportación; **esta preparación se graba en editor, no es una función de acceso normal de una build distribuida**.

La reproducción por herramientas utilizada fue `node Juego/tests/run_scene_6_3.cjs Juego/tests/capstone_demo.json Juego/reports/capstone/demo_test.json`. Ese runner usa Godot MCP, no una recreación de la interfaz. No se generó un archivo de vídeo durante esta tarea: se entregan escena reproducible, guion y capturas reales.

## Recorrido y narración (aproximadamente 65–75 s con título inicial)

| Clip desde escena lista | Acción real | Voz sugerida |
|---|---|---|
| 0–7 s | Campus de Informática, jugador y docente visibles | **Nicolás:** «DuocGames propone practicar contenidos en un campus virtual. Esta demostración comienza en el piso de Informática y usa un banco local identificado como práctica.» |
| 7–12 s | Camina hacia el profesor de Bases de Datos; scanner identifica el objetivo | **Nicolás:** «Nos acercamos al profesor. El mismo sistema de interacción permite conversar e iniciar una actividad.» |
| 12–20 s | Diálogo del profesor | **Giannela:** «El docente guía la actividad. Las prácticas y las simulaciones de acción se mantienen separadas.» |
| 20–26 s | Selecciona ACTIVIDAD DEL DOCENTE, luego PRÁCTICA LOCAL | **Giannela:** «Elegimos práctica local. Está señalada como material sin validación institucional y no entrega desbloqueos oficiales.» |
| 26–39 s | Pregunta SQL con cuatro alternativas | **Nicolás:** «La actividad presenta una pregunta y cuatro alternativas. Para este ejemplo elegimos SELECT, la instrucción que consulta filas.» |
| 39–49 s | Respuesta correcta y explicación | **Giannela:** «La respuesta se evalúa y entrega una explicación. También probamos respuestas incorrectas, reintentos y reapertura de los desafíos.» |
| 49–61 s | MI PROGRESO ACADÉMICO | **Giannela:** «El contador registra una práctica local. Distinguirla de una respuesta validada por el servidor evita presentarla como nota o evaluación oficial.» |
| 61–70 s, opcional | Mantener imagen del progreso o volver a la diapositiva de resultados | **Nicolás:** «Los once docentes se probaron con esta ruta. La publicación remota y una validación docente son los siguientes pasos.» |

Los tiempos son aproximados; el reporte automatizado registró 60,688 s. No acelerar la respuesta hasta que el público lea las alternativas. La secuencia no demuestra completar una misión ni acceder al piso con progresión normal: muestra el contador de práctica, que sí pasó las pruebas.

## Ubicación reproducible

- Piso 3, sector Informática y Telecomunicaciones, punto «Laboratorio sin conexión» próximo al mentor de Bases de Datos.
- Inicio del clip: **(-45, 23.96642, -132.8)**.
- Fin de aproximación: **(-45, 23.96852, -134.3001)**.
- Mentor visible: **(-45, 24.00767, -137)**.
- Recorrido: avanzar hacia **−Z**, interacción con Profesor de Bases de Datos → ACTIVIDAD DEL DOCENTE → PRÁCTICA LOCAL → SELECT → CONTINUAR → MI PROGRESO ACADÉMICO.
- Cámara fija de demostración construida solo en la fixture. El movimiento del jugador usa `Input.action_press("move_forward")`, no animación de un vídeo ni desplazamiento simulado del HUD.

## Capturas listas para diapositivas

| Archivo en `reports/capstone_capturas/` | Contenido | Uso |
|---|---|---|
| [01_campus_demo.png](../capstone_capturas/01_campus_demo.png) | Protagonista y mentor en piso 3 | Solución/demo |
| [02_dialogo_profesor.png](../capstone_capturas/02_dialogo_profesor.png) | Diálogo y selección de actividad | Interacción |
| [03_pregunta_demo.png](../capstone_capturas/03_pregunta_demo.png) | Cuatro alternativas y rótulo práctica local | Sistema educativo |
| [04_respuesta_demo.png](../capstone_capturas/04_respuesta_demo.png) | Respuesta correcta y explicación | Retroalimentación |
| [05_progreso_academico.png](../capstone_capturas/05_progreso_academico.png) | Contador con práctica y verificación diferenciadas | Resultado comprobado |
| `piso_-1.png`, `piso_1.png`…`piso_8.png` | Puntos reales inspeccionados en nueve niveles | Alcance del campus; no panorámica completa de cada piso |
| [06_panel_docente_fixture.png](../capstone_capturas/06_panel_docente_fixture.png) | Panel real con datos de prueba en memoria | Solo anexo con rótulo visible **FIXTURE / BACKEND SIMULADO** |
| [07_panel_admin_fixture.png](../capstone_capturas/07_panel_admin_fixture.png) | Panel administrador con datos de prueba en memoria | Mismo límite; no presentar como producción |

El panel docente no forma parte de la demo remota principal: pasó pruebas contra fixture, pero no login/RLS/despliegue reales. Si se muestra su captura, explicitar ese alcance en la diapositiva.

## Contingencia y seguridad de presentación

Si el editor o equipo de exposición no reproduce la escena, usar las capturas ya generadas y explicar que corresponden a la ejecución documentada. No afirmar que una secuencia de imágenes es una demo en vivo. No abrir configuración de autenticación, consola con tokens ni cuentas reales durante la defensa. No intentar resolver el fallo remoto cambiando RLS o permisos.
