# DuocGames 7.1 — Piso 3: Informática y Telecomunicaciones

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

Laboratorios 301, 302, 303, 304-B, 305, 306 y técnica de servidores; encuentro de Redes; costados y vestíbulo. Se usó la distribución realmente creada por DuocGames4, sin agregar salas.

Inventario de 3043 nodos bajo el piso, 16 luces y 3 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 41 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

Se confirmó una separación de 0,225 m entre la mesa y el borde inferior de 24 monitores de los seis TeachingLab. Se añadieron 24 bases y 24 soportes sin colisión. Se mantuvo la escala de pantallas, mesas y salas.

Archivos y nodos: `scripts/education/teaching_lab_v4.gd`, función de construcción de los laboratorios; nodos BaseMonitor y SoporteMonitor bajo las instancias existentes.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Bases de Datos, Algoritmos y Redes: selección con E, diálogo, práctica local y visual humano importado. ProfesorNPC: aceptación real de Documentos.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

Documentos: aceptada por su interfaz real y entregada al funcionario del piso 5. Rescate, laboratorio sin conexión y programa infectado: catálogo efectivo inspeccionado; ejecución publicada BLOCKED por V4. No se fabricaron resultados verificados. Computadores y requisitos finales registrados en effective_quests.json.

Escaleras centrales: recorrido real 3→4 y retorno, con altura final comprobada: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 52 PASS, 0 FAIL, 4 BLOCKED, 1 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

| Prueba | Resultado |
|---|---|
| capsule_sample_laboratory_301 | PASS |
| capsule_sample_laboratory_302 | PASS |
| capsule_sample_laboratory_304-B | PASS |
| capsule_sample_laboratory_305 | PASS |
| capsule_sample_laboratory_306 | PASS |
| capsule_sample_laboratory_TÉCNICA | PASS |
| capsule_sample_laboratory_303 | PASS |
| capsule_sample_VestibuloAscensores | PASS |
| capsule_sample_EncuentroProfesorRedes | PASS |
| capsule_sample_CostadosReferencia | PASS |
| directory_destinations | PASS |
| E_selection_profesor_redes | PASS |
| dialogue_profesor_redes | PASS |
| question_options_profesor_redes_0 | PASS |
| feedback_profesor_redes_0 | PASS |
| question_options_profesor_redes_1 | PASS |
| feedback_profesor_redes_1 | PASS |
| question_options_profesor_redes_2 | PASS |
| feedback_profesor_redes_2 | PASS |
| no_early_repeat_profesor_redes | PASS |
| local_practice_no_official_pass_profesor_redes | PASS |
| E_selection_profesor_datos | PASS |
| dialogue_profesor_datos | PASS |
| question_options_profesor_datos_0 | PASS |
| feedback_profesor_datos_0 | PASS |
| question_options_profesor_datos_1 | PASS |
| feedback_profesor_datos_1 | PASS |
| question_options_profesor_datos_2 | PASS |
| feedback_profesor_datos_2 | PASS |
| no_early_repeat_profesor_datos | PASS |
| local_practice_no_official_pass_profesor_datos | PASS |
| E_selection_profesor_algoritmos | PASS |
| dialogue_profesor_algoritmos | PASS |
| question_options_profesor_algoritmos_0 | PASS |
| feedback_profesor_algoritmos_0 | PASS |
| question_options_profesor_algoritmos_1 | PASS |
| feedback_profesor_algoritmos_1 | PASS |
| question_options_profesor_algoritmos_2 | PASS |
| feedback_profesor_algoritmos_2 | PASS |
| no_early_repeat_profesor_algoritmos | PASS |
| local_practice_no_official_pass_profesor_algoritmos | PASS |
| campaign_gates_not_bypassed | PASS |
| monitor_supports | PASS |
| published_incident_v4_rescue | BLOCKED |
| published_incident_v4_network | BLOCKED |
| published_incident_v4_bugs | BLOCKED |
| hall_walk_3 | NOT RUN |
| stairs_3_up | PASS |
| stairs_3_down | PASS |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| npc_E_Profesor | PASS |
| npc_Profesor_accept | PASS |
| human_imported_profesor_redes | PASS |
| human_imported_profesor_datos | PASS |
| human_imported_profesor_algoritmos | PASS |

## Rendimiento y errores

820 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 22.90 ms, FPS informado 41.2, draw calls 7738, primitivas 334649. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Recorrido continuo dentro de cada laboratorio, cableado individual, todas las puertas y salas no incluidas en los encuadres: NOT RUN. Encuentros completos de Redes/Bases de Datos/Algoritmos y sus recompensas: NOT RUN. Comparación física del edificio con fotografías: pendiente.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[monitor_before_detail_monitor_301.png](reports/final_7_1/run_20261113_145917/floor_3/monitor_before_detail_monitor_301.png) · [monitor_after_detail_monitor_301.png](reports/final_7_1/run_20261113_145917/floor_3/monitor_after_detail_monitor_301.png) · [npc_motion_npc_profesor_algoritmos_front.png](reports/final_7_1/run_20261113_145917/floor_3/npc_motion_npc_profesor_algoritmos_front.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_3/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_3/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_3/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
