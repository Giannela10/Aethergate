# DuocGames 7.1 — Piso 8: Director de Informática

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

PasilloReferencia; aulas, baños, zonas de estudio, vestíbulo; mentor Director y puntos informáticos de campaña. EncuentroDirectorInformatica conserva sus nodos y credencial; su AABB vacío produjo vistas exteriores inválidas, excluidas de aprobación y sustituidas por capturas del mentor y la simulación reales.

Inventario de 5267 nodos bajo el piso, 112 luces y 1 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 53 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

No se modificó el producto del piso 8: las pruebas no demostraron un defecto seguro adicional. Se conservó la simulación digital y el docente humano separado.

Archivos y nodos: Sin cambios de producto específicos del piso 8. Nuevos auxiliares de prueba: final_director_play_7_1.gd y final_director_sim_7_1.gd.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Director: E, diálogo, tres preguntas locales por interfaz, retroalimentación, visual importado, reposo y representación separada de entidad digital.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

Conexión: cuatro opciones reales; configuración: elección correcta; antivirus: completado pulsando los botones VIRUS existentes conforme aparecieron, sin emitir completed ni cambiar temporizadores. Tres tareas registradas. Se inició la simulación mediante su botón con el catálogo local no autenticado, comprobando holograma visible, mentor visible y visual humano del actor de combate oculto; se reinició sin victoria ni credencial. Esto no valida una evaluación publicada. Antes de completar las tareas, se comprobó su bloqueo. Archivo y NEXO permanecieron restringidos.

Escaleras centrales: 7→8 y 8→7 probados desde el bloque del piso 7: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 39 PASS, 0 FAIL, 2 BLOCKED, 2 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

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
| capsule_sample_EncuentroDirectorInformatica | NOT RUN |
| directory_destinations | PASS |
| E_selection_director | PASS |
| dialogue_director | PASS |
| question_options_director_0 | PASS |
| feedback_director_0 | PASS |
| question_options_director_1 | PASS |
| feedback_director_1 | PASS |
| question_options_director_2 | PASS |
| feedback_director_2 | PASS |
| no_early_repeat_director | PASS |
| local_practice_no_official_pass_director | PASS |
| campaign_gates_not_bypassed | PASS |
| hall_walk_8 | NOT RUN |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| director_connection_steps | PASS |
| director_configuration_real_choice | PASS |
| director_antivirus_started | PASS |
| director_antivirus_completed | PASS |
| director_prerequisites_enforced | PASS |
| director_official_integrator | BLOCKED |
| nexo_access_stays_locked | PASS |
| human_imported_director | PASS |
| director_three_tasks | PASS |
| director_reward_not_faked | PASS |
| director_E_after_tasks | PASS |
| director_digital_simulation_start | PASS |
| director_simulation_reset_no_reward | PASS |

## Rendimiento y errores

1060 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 16.57 ms, FPS informado 54.8, draw calls 4229, primitivas 107545. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Evaluación integradora publicada y su nota verificada: BLOCKED (V4 404/PGRST205, sin sesión de estudiante). Victoria completa de simulación, recompensa, CredencialDirector, guardado después de obtenerla y continuidad final hacia NEXO: NOT RUN. No se inyectaron victorias ni desbloqueos.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[npc_motion_npc_director_front.png](reports/final_7_1/run_20261113_145917/floor_8/npc_motion_npc_director_front.png) · [antivirus_before_play.png](reports/final_7_1/run_20261113_145917/floor_8/antivirus_before_play.png) · [director_simulation_retry_digital_entity_and_mentor.png](reports/final_7_1/run_20261113_145917/floor_8/director_simulation_retry_digital_entity_and_mentor.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_8/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_8/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_8/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
