# DuocGames 7.1 — Piso 6: Inglés y Ética

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

PasilloReferencia; sus aulas, baños, zonas de estudio y vestíbulo; numeración visual de salas y directorio. Los nombres internos heredados 8xx se conservaron.

Inventario de 5727 nodos bajo el piso, 112 luces y 2 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 53 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

Se confirmó pc5 en piso 6 (Inglés), pc6 en piso 7 (Comunicación) y pc7 en piso 6 (Ética). Se corrigieron únicamente sus textos de requisitos opcionales en academico5, seguridad6 y acceso7. Ningún ID persistente, opcionalidad, cantidad, recompensa o desbloqueo cambió.

Archivos y nodos: `scripts/campaign/quest_manager.gd`: tres textos descriptivos después de construir las definiciones; evidencia en computer_caption_changes.json.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Inglés y Ética: E, diálogos, tres preguntas por interfaz para cada mentor, explicación y separación de progreso local/oficial. Inspección frontal/lateral del modelo importado y reposo.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

Asociaciones reales de computadores registradas. El requisito de acceso al siguiente piso permanece efectivo. Banco local de Inglés/Ética probado; las actividades publicadas no se sustituyeron con aciertos locales.

Escaleras centrales: recorrido real 6→7 y retorno, con altura final comprobada: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 42 PASS, 0 FAIL, 1 BLOCKED, 1 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

| Prueba | Resultado |
|---|---|
| capsule_sample_PasilloReferencia | PASS |
| capsule_sample_Sala807 | PASS |
| capsule_sample_Sala808 | PASS |
| capsule_sample_Sala805 | PASS |
| capsule_sample_Sala806 | PASS |
| capsule_sample_Sala809 | PASS |
| capsule_sample_Sala810 | PASS |
| capsule_sample_BanosMujeres | PASS |
| capsule_sample_BanosHombres | PASS |
| capsule_sample_ZonaEncuentroDuoc | PASS |
| capsule_sample_SalaEstudioExtremoSur | PASS |
| capsule_sample_SalaEstudioExtremoSur_4187 | PASS |
| capsule_sample_VestibuloAscensores | PASS |
| directory_destinations | PASS |
| E_selection_profesor_ingles | PASS |
| dialogue_profesor_ingles | PASS |
| question_options_profesor_ingles_0 | PASS |
| feedback_profesor_ingles_0 | PASS |
| question_options_profesor_ingles_1 | PASS |
| feedback_profesor_ingles_1 | PASS |
| question_options_profesor_ingles_2 | PASS |
| feedback_profesor_ingles_2 | PASS |
| no_early_repeat_profesor_ingles | PASS |
| local_practice_no_official_pass_profesor_ingles | PASS |
| E_selection_profesor_etica | PASS |
| dialogue_profesor_etica | PASS |
| question_options_profesor_etica_0 | PASS |
| feedback_profesor_etica_0 | PASS |
| question_options_profesor_etica_1 | PASS |
| feedback_profesor_etica_1 | PASS |
| question_options_profesor_etica_2 | PASS |
| feedback_profesor_etica_2 | PASS |
| no_early_repeat_profesor_etica | PASS |
| local_practice_no_official_pass_profesor_etica | PASS |
| campaign_gates_not_bypassed | PASS |
| computer_captions_only | PASS |
| hall_walk_6 | NOT RUN |
| stairs_6_up | PASS |
| stairs_6_down | PASS |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| human_imported_profesor_ingles | PASS |
| human_imported_profesor_etica | PASS |

## Rendimiento y errores

1060 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 20.10 ms, FPS informado 46.0, draw calls 7344, primitivas 219737. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Completar cada computador y los encuentros normales, comprobar sus recompensas y avance principal: NOT RUN. Ruta de pasillo propuesta sin inicio seguro: NOT RUN; no implica por sí sola un defecto del piso. No se recorrió cada baño, puerta y asiento.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[npc_motion_npc_profesor_ingles_front.png](reports/final_7_1/run_20261113_145917/floor_6/npc_motion_npc_profesor_ingles_front.png) · [npc_motion_npc_profesor_etica_front.png](reports/final_7_1/run_20261113_145917/floor_6/npc_motion_npc_profesor_etica_front.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_6/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_6/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_6/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
