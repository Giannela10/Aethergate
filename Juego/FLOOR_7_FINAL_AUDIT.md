# DuocGames 7.1 — Piso 7: Comunicación, Matemáticas y acceso

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

PasilloReferencia; aulas, baños, estudio, vestíbulo; puerta de Sala805 con CampaignAccess; señalización visual del piso 7.

Inventario de 5715 nodos bajo el piso, 112 luces y 2 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 53 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

Sin cambios físicos específicos: no se demostró un defecto seguro adicional. La aclaración de ubicación de pc6 está incluida en la corrección textual compartida de QuestManager.

Archivos y nodos: Sin cambios en geometría del piso 7. Texto compartido en `scripts/campaign/quest_manager.gd`.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Comunicación/Lenguaje y Matemáticas: selección E, diálogo, práctica y retroalimentación locales; visual importado con rig y reposo.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

TarjetaAcceso obtenida al entregar Documentos en la fixture. La puerta restringida reconoció la tarjeta y registró door:acceso7. El piso 8 continuó restringido por requisitos principales pendientes: abrir una puerta no completó artificialmente la campaña. La prueba fue del controlador de puerta, no un recorrido completo del vano.

Escaleras centrales: recorrido real 7→8 y retorno, con altura final comprobada: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 46 PASS, 0 FAIL, 1 BLOCKED, 1 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

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
| E_selection_profesor_lenguaje | PASS |
| dialogue_profesor_lenguaje | PASS |
| question_options_profesor_lenguaje_0 | PASS |
| feedback_profesor_lenguaje_0 | PASS |
| question_options_profesor_lenguaje_1 | PASS |
| feedback_profesor_lenguaje_1 | PASS |
| question_options_profesor_lenguaje_2 | PASS |
| feedback_profesor_lenguaje_2 | PASS |
| no_early_repeat_profesor_lenguaje | PASS |
| local_practice_no_official_pass_profesor_lenguaje | PASS |
| E_selection_profesor_matematicas | PASS |
| dialogue_profesor_matematicas | PASS |
| question_options_profesor_matematicas_0 | PASS |
| feedback_profesor_matematicas_0 | PASS |
| question_options_profesor_matematicas_1 | PASS |
| feedback_profesor_matematicas_1 | PASS |
| question_options_profesor_matematicas_2 | PASS |
| feedback_profesor_matematicas_2 | PASS |
| no_early_repeat_profesor_matematicas | PASS |
| local_practice_no_official_pass_profesor_matematicas | PASS |
| campaign_gates_not_bypassed | PASS |
| hall_walk_7 | NOT RUN |
| stairs_7_up | PASS |
| stairs_7_down | PASS |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| earned_access_card | PASS |
| access7_card_controller | PASS |
| floor8_main_requirements_preserved | PASS |
| coordinator_E_return | PASS |
| locate_teachers_dependency | PASS |
| human_imported_profesor_lenguaje | PASS |
| human_imported_profesor_matematicas | PASS |

## Rendimiento y errores

1060 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 17.82 ms, FPS informado 51.7, draw calls 6176, primitivas 169517. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Completar legítimamente acceso7 y certificar el desbloqueo de piso 8 en una partida normal: NOT RUN. Paso físico por cada acceso restringido y todos los secundarios: NOT RUN. Los resultados locales no sustituyen autorización académica remota.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[npc_motion_npc_profesor_lenguaje_front.png](reports/final_7_1/run_20261113_145917/floor_7/npc_motion_npc_profesor_lenguaje_front.png) · [npc_motion_npc_profesor_matematicas_front.png](reports/final_7_1/run_20261113_145917/floor_7/npc_motion_npc_profesor_matematicas_front.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_7/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_7/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_7/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
