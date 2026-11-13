# DuocGames 7.1 — Piso 4: Salud y sector docente

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

DistribucionPlanoPiso4; SectorDocentesPiso4/ProfesoresCoordDocente; FilaFrontalPiso4/CoworkDocente; SalasCentralesPiso4/415, 417 y 418; FilaFrontalPiso4/PanolSalud; vestíbulo.

Inventario de 5191 nodos bajo el piso, 33 luces y 3 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 33 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

Sin cambios de geometría, vidrio, luces ni NPC: los encuadres no demostraron un defecto que justificara remodelar. Las aperturas superiores de 415/417/418 se conservaron para contraste fotográfico. El vidrio de Cowork se conservó.

Archivos y nodos: Ningún archivo de producto específico del piso 4 modificado.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Enfermería, Odontología y Coordinador: E, diálogo, preguntas y retroalimentación locales. Se conservaron los modelos importados, vestuario y rig de 53 huesos; un segundo de reposo por mentor.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

Coordinación: la búsqueda de docentes quedó sin faltantes tras hablar realmente con Algoritmos, Inglés y Matemáticas en la fixture; comprobación de retorno con E registrada en floor_7/restricted_access_checks.json. Emergencia simulada publicada: BLOCKED por V4. No se atribuye certificación clínica a la práctica.

Escaleras centrales: recorrido real 4→5 y retorno, con altura final comprobada: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 47 PASS, 0 FAIL, 2 BLOCKED, 1 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

| Prueba | Resultado |
|---|---|
| capsule_sample_DistribucionPlanoPiso4 | PASS |
| capsule_sample_SectorDocentesPiso4_ProfesoresCoordDocente | PASS |
| capsule_sample_FilaFrontalPiso4_CoworkDocente | PASS |
| capsule_sample_SalasCentralesPiso4_415 | PASS |
| capsule_sample_SalasCentralesPiso4_417 | PASS |
| capsule_sample_SalasCentralesPiso4_418 | PASS |
| capsule_sample_FilaFrontalPiso4_PanolSalud | PASS |
| capsule_sample_VestibuloAscensores | PASS |
| directory_destinations | PASS |
| E_selection_docente_enfermeria | PASS |
| dialogue_docente_enfermeria | PASS |
| question_options_docente_enfermeria_0 | PASS |
| feedback_docente_enfermeria_0 | PASS |
| question_options_docente_enfermeria_1 | PASS |
| feedback_docente_enfermeria_1 | PASS |
| question_options_docente_enfermeria_2 | PASS |
| feedback_docente_enfermeria_2 | PASS |
| no_early_repeat_docente_enfermeria | PASS |
| local_practice_no_official_pass_docente_enfermeria | PASS |
| E_selection_docente_odontologia | PASS |
| dialogue_docente_odontologia | PASS |
| question_options_docente_odontologia_0 | PASS |
| feedback_docente_odontologia_0 | PASS |
| question_options_docente_odontologia_1 | PASS |
| feedback_docente_odontologia_1 | PASS |
| question_options_docente_odontologia_2 | PASS |
| feedback_docente_odontologia_2 | PASS |
| no_early_repeat_docente_odontologia | PASS |
| local_practice_no_official_pass_docente_odontologia | PASS |
| E_selection_coordinador_profesores | PASS |
| dialogue_coordinador_profesores | PASS |
| question_options_coordinador_profesores_0 | PASS |
| feedback_coordinador_profesores_0 | PASS |
| question_options_coordinador_profesores_1 | PASS |
| feedback_coordinador_profesores_1 | PASS |
| question_options_coordinador_profesores_2 | PASS |
| feedback_coordinador_profesores_2 | PASS |
| no_early_repeat_coordinador_profesores | PASS |
| local_practice_no_official_pass_coordinador_profesores | PASS |
| campaign_gates_not_bypassed | PASS |
| published_incident_v4_emergency | BLOCKED |
| hall_walk_4 | NOT RUN |
| stairs_4_up | PASS |
| stairs_4_down | PASS |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| human_imported_docente_enfermeria | PASS |
| human_imported_docente_odontologia | PASS |
| human_imported_coordinador_profesores | PASS |

## Rendimiento y errores

660 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 21.82 ms, FPS informado 43.6, draw calls 6898, primitivas 274999. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Verificar con fotografías los vanos superiores de 415/417/418. El encuadre frontal de Enfermería quedó ocluido por una pared; el lateral permite observar al mentor, pero la aprobación frontal queda pendiente. Recorrer íntegramente todas las oficinas, salas clínicas y puertas: NOT RUN. Recompensas completas de desafíos: NOT RUN.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[npc_motion_npc_docente_enfermeria_side.png](reports/final_7_1/run_20261113_145917/floor_4/npc_motion_npc_docente_enfermeria_side.png) · [npc_motion_npc_docente_odontologia_front.png](reports/final_7_1/run_20261113_145917/floor_4/npc_motion_npc_docente_odontologia_front.png) · [npc_motion_npc_coordinador_profesores_front.png](reports/final_7_1/run_20261113_145917/floor_4/npc_motion_npc_coordinador_profesores_front.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_4/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_4/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_4/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
