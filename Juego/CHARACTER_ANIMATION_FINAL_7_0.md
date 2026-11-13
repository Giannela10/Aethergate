# Protagonista — corrección final 7.0

Fecha: 13-11-2026. Proyecto real: `Juego/project.godot`, DuocGames, Godot 4.7.2, renderizador Compatibility. Evidencias nuevas: [run_20261113_103850](reports/final_7_0/run_20261113_103850/). No se hizo push ni se descartó trabajo local.

## Resultado y alcance

Se aplicaron correcciones reales al retargeting de brazos y piernas, al apoyo de los pies y a la instalación diferida del visual. Se observaron secuencias de movimiento renderizadas y se ejercitó el controlador real del protagonista. **Caminata y carrera verificadas en los escenarios registrados; la aprobación no se extiende a todas las acciones, prendas, armas, pendientes o situaciones posibles.**

La versión todavía tiene un bloqueo estructural en la salida superior de la rampa del −1, detallado en el [informe de pisos](FLOORS_MINUS1_1_2_FINAL_AUDIT.md). No se declara toda la versión lista para defensa mientras ese bloqueo permanezca.

## Implementación actual y causas

Se revisaron `player.gd`, la cadena `main_character_visual_6_2.gd` → `main_character_visual_6.gd` → `student_visual.gd` → `humanoid.gd`, `human_student_6_2.gd`, `human_npc_6_3.gd`, `npc_visual_6_3.gd`, `character_footwear_6_3.gd`, el cálculo de superficie visible y los sockets.

El protagonista utiliza el humano importado 6.2 con **Skeleton3D de 53 huesos y skin real**. Las matrices de reposo se guardaron en `before_animation.json`. Los AnimationPlayer del modelo se detienen al inicializarlo; la locomoción efectiva procede de las articulaciones procedurales y se transfiere al esqueleto mediante overrides globales. No se sustituyó el sistema por un AnimationTree ni se añadieron clips externos.

Defectos comprobados en el código y las pruebas:

1. Cada hueso de extremidad se orientaba mediante un nuevo arco mínimo desde un eje de reposo hasta una dirección. Ese cálculo conserva la dirección, pero descarta el resto de la rotación procedural y el plano de flexión al girar los padres. Los ejes de reposo importados tienen inclinaciones distintas; no equivalen todos a un eje vertical común.
2. El corrector 6.3 trataba ambos pies como apoyos hasta 25 cm sobre la superficie. Podía anclar el pie que avanzaba y volver a resolver su rodilla contra la animación de recuperación.
3. La referencia de flexión de la rodilla podía resultar inestable cerca de la extensión total.
4. La corrección vertical común podía bajar un pie que estaba libre antes del desplazamiento de la pelvis y hacerlo penetrar en el suelo. Las muestras iniciales motivaron la corrección adicional; las últimas muestras no registraron penetración.
5. Una suite detectó una corrutina de instalación del visual que se reanudaba después de liberar su instancia. Se corrigió ese ciclo de vida y se repitió la suite sin ese error.

No se atribuyó el problema solamente a velocidad de reproducción. Los primeros diagnósticos de la rampa también se contrastaron con matrices del motor: **su orientación efectiva era correcta**, y no se invirtió en el archivo final.

## Cambios aplicados

| Archivo | Corrección |
|---|---|
| `scripts/juego/human_student_6_2.gd` | Para el protagonista, transfiere la rotación completa entre el marco procedural neutral y el marco del hueso importado. Conserva la orientación de reposo y el plano de movimiento. El camino anterior sigue disponible para los NPC 6.3. |
| `scripts/juego/character_footwear_6_3.gd` | Distingue avance y apoyo con la fase real de la marcha; libera el anclaje del pie de avance; comprueba penetración después del desplazamiento de pelvis; mantiene estable el lado de flexión de la rodilla; ajusta el recorrido permitido del anclaje del protagonista. |
| `scripts/juego/humanoid.gd` | Sustituye las dos esperas de instalación por callbacks de señal de un solo uso, desconectados automáticamente al liberar el objeto. Mantiene la espera de dos fotogramas. |

La cadencia del humano importado del protagonista también sigue la velocidad real: conserva 8,75 rad/s de fase a 2,5 unidades/s y 10 rad/s a 5,5, aumenta a 12 rad/s a 6,6 y se detiene a velocidad cero. Se ensayaron esos cuatro casos en `verified_final_cadence.json`; no se modificaron las constantes de velocidad del controlador ni los tiempos de ataque.

Se conservó el corrector de dos segmentos que ya existía. No se añadió otro sistema de IK, huesos, geometría, luces o sombras. No se cambiaron velocidad real, salto, daño, stamina, duración de ataques, inventario, sockets ni requisitos de campaña.

## Proporciones y cámara

La política actual del campus es **2,7 unidades de altura**, con cápsula de 2,7 y radio 0,45. El modelo se normaliza uniformemente según su geometría neutral. No se deformaron piernas, brazos, cabeza, manos ni torso; se conservaron los morphs y la diversidad de perfiles de NPC. No se afirma que 2,7 unidades equivalgan a 2,7 metros reales. Adoptar 1,75 como altura numérica exigiría recalibrar campus, cápsulas, mobiliario y accesos; no se hizo como solución cosmética.

La cámara existente mantiene su seguimiento y su raycast de colisión. Se capturó con caminata, carrera, salto, giros, escaleras y recorridos interiores. No se remodeló su sistema. La colisión de cámara en todas las paredes, todos los ángulos y todas las transiciones sigue **NO VERIFICADA exhaustivamente**.

El controlador gira el cuerpo hacia el movimiento también al usar lateral o retroceso: no se añadieron animaciones independientes de strafe/backpedal ni se cambió ese diseño.

## Pruebas y evidencia

- `FinalAnimation70.tscn`: escena aislada con suelo físico, modelo real y secuencias antes/después de idle, caminar, correr, lateral, retroceso, salto, aterrizaje, agachado, ataque y recogida. Se traslada el actor para acompañar la animación: **no equivale a jugar una ruta**. Capturas de frente, espalda y ambos perfiles en caminata, y secuencias temporales `before_walk_*`, `after_walk_*`, `final_walk_*` y equivalentes de carrera.
- `FinalCampus70.tscn`: controlador real con inputs de caminar, correr, lateral, retroceso, salto, agachado, ataque y giro. `survey_game_*` y `survey_checks.json` registran cámara, estados, posiciones y sockets. Las comprobaciones de valores finitos no sustituyen la evaluación visual.
- `final_ground/extra_checks.json`: **40 muestras por estado durante 4 segundos de caminata y 4 de carrera**, con arma equipada, malla de zapatillas deformada por el esqueleto y raycast por pie. Se distingue suelo físico de superficie visible.
- Caminata: apoyo sobre superficie visible aproximadamente **4,15–4,16 mm**; mínimo de ambos pies aproximadamente **4,00 mm** en esas muestras. Carrera: apoyo aproximadamente **4,00–20,89 mm**, con una variación breve entre superficies; mínimo de ambos pies aproximadamente **4,00 mm**. El pie libre alcanza mayor altura de forma intencional. No es una garantía para todas las pendientes ni una medición completa de deslizamiento horizontal.
- Socket de arma conservado por identidad y con transformaciones finitas durante las secuencias. Mochila observada. Recogida real del objeto inicial y de libros; computador y diálogos ejercitados.
- Escaleras completas −1 → 1, 1 → 2 y 2 → 1: recorridos por input real con altura final comprobada (`transitions/transitions_done.json`). Ascensores 1 → 2 → 1 → 2: viajes de plataforma con el desbloqueo obtenido por la misión en el fixture.
- Suites frescas: `inventory_regression`, `gameplay_regression`, `guardado_lectura`, `main_character_regression_6`. Las cuatro terminaron sin fallos en su resultado. La última se repitió después de corregir la instalación diferida; véanse `regressions.json` y los logs finales. Las advertencias por archivos de guardado deliberadamente inválidos pertenecen al ensayo de recuperación.

Los resultados iniciales se conservaron, incluidos los fallos del propio fixture. En particular, comparar JSON textual con enteros/floats no era una prueba válida de pérdida de guardado; la comparación semántica posterior pasó. Un contador de conversación mayor que uno tampoco invalida el requisito de hablar una vez.

## Pendientes

- Esquiva, ataque pesado, lanzar y usar todos los objetos, todas las armas y todas las combinaciones de vestuario: **PENDIENTES de evaluación visual específica**.
- Deslizamiento horizontal de cada pie durante todos los ciclos, aceleraciones y giros: **NO medido exhaustivamente**. Se corrigió el anclaje incompatible y se observaron secuencias; no se afirma eliminación universal del deslizamiento.
- Apoyo en todas las escaleras, rampas, plataformas y desniveles: pendiente fuera de las muestras documentadas.
- El encuentro final NEXO no se desbloqueó ni se jugó artificialmente para aprobarlo.
- No hay vídeo MP4: se entregan secuencias PNG reales y una galería HTML reproducible. La galería identifica claramente la prueba aislada y las capturas del controlador real.
- Las mediciones de FPS no se usan para afirmar mejoras; véase el informe de pisos.

Galería final: [evidence_gallery_verified.html](reports/final_7_0/run_20261113_103850/evidence_gallery_verified.html). Resumen verificable: [final_summary.json](reports/final_7_0/run_20261113_103850/final_summary.json). El resumen comprueba también que se mantienen los 53 huesos y sus matrices de reposo.
