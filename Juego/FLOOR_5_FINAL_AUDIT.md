# DuocGames 7.1 — Piso 5: Terraza y tienda

Fecha: 13-11-2026. Estado: revisión parcial con evidencia, no aprobación exhaustiva.

## Sectores y objetos inspeccionados

TerrazaPicnic, su cerca y acceso; TiendaEsquinaPiso5; vestíbulo y escaleras centrales. Mobiliario, mostradores, vidrios y señalización en encuadres cardinales.

Inventario de 1805 nodos bajo el piso, 8 luces y 0 CharacterBody3D presentes en ese subárbol. No equivale al total de objetos de campaña creados fuera del piso. Los 13 encuadres válidos cubren muestras interiores/cardinales, mobiliario, materiales, texturas, ventanas, techos y rótulos. No se revisó individualmente cada instancia.

## Defectos y correcciones

Los 22 paneles CSG frontales declaraban use_collision, pero las sondas físicas no los interceptaban. El pasamanos sí detenía al jugador. Se añadió un StaticBody3D con BoxShape3D coincidente a cada panel frontal, sin mover la terraza ni alterar su apariencia. Repetir la instalación no duplica cuerpos. Después: 34/34 muestras de cerca (frente y laterales) y prueba con el controlador real mantuvieron al jugador dentro.

Archivos y nodos: `Main.tscn`, nodo `Piso5/TerrazaPicnic/CercaVidrio/Frente`: referencia al nuevo `scripts/pisos/piso_5/terrace_guard_collision_7_1.gd`.

Riesgo: cambios limitados y reversibles. Se conservaron world_id, identificadores de computadores, guardados personales, preguntas existentes, recompensas y parámetros de combate. Luces corregidas: 0; no hubo ajuste masivo de sombras. Carteles físicos corregidos: 0; los directorios PlanoPisos mostraron Casino/Coordinación en piso 1 y Biblioteca/Auditorio en piso 2, con el piso actual correcto. Los textos de objetivos corregidos no son carteles físicos.

## Personajes y educación

Funcionario: E y entrega de Documentos; no se inventó un docente exclusivo del piso.

Práctica mediante botones reales de LearningActivityView: tres preguntas por perfil inspeccionado; alternativas, explicación, continuación y ausencia de repetición inmediata comprobadas. La regresión adicional recorrió los mazos completos de los once perfiles, incluido el Director con tres áreas. Banco: 150 preguntas válidas, IDs y enunciados únicos, sin agregar contenido. Los resultados locales permanecen verified=false y no otorgaron mentor_passes oficiales. No se publicaron preguntas ni se modificó Supabase.

## Misiones, accesos y persistencia

Documentos: entrega real, una TarjetaAcceso y comprobación de que repetir la conversación no duplica XP/créditos/recompensa. Requisitos de visita y computadores opcionales conservados.

Escaleras centrales: recorrido real 5→6 y retorno, con altura final comprobada: PASS. Se trasladó al personaje al inicio diagnóstico; esto comprueba movimiento/colisiones, no el derecho de acceso de una partida normal. Ascensor: rechazo de destino no ganado PASS; viaje autorizado BLOCKED por requisitos de la fixture nueva, sin inyección de autorizaciones. Guardado y lectura semántica del payload de campaña en archivo exclusivo de este informe: PASS. No certifica recuperar toda la apariencia/inventario tras una sesión completa.

## Pruebas ejecutadas

Último resultado por identificador: 15 PASS, 0 FAIL, 1 BLOCKED, 0 NOT RUN. Los archivos originales conservan también diagnósticos iniciales y pruebas repetidas.

| Prueba | Resultado |
|---|---|
| capsule_sample_TerrazaPicnic | PASS |
| capsule_sample_TiendaEsquinaPiso5 | PASS |
| capsule_sample_VestibuloAscensores | PASS |
| directory_destinations | PASS |
| campaign_gates_not_bypassed | PASS |
| npc_E_Funcionario | PASS |
| npc_Funcionario_deliver | PASS |
| documents_reward_once | PASS |
| terrace_fence_physics_samples | PASS |
| hall_walk_5 | PASS |
| stairs_5_up | PASS |
| stairs_5_down | PASS |
| elevator_campaign_gate | PASS |
| authorized_elevator_trip | BLOCKED |
| isolated_save_read | PASS |
| terrace_front_guard | PASS |

## Rendimiento y errores

260 muestras de intervalos entre cuadros, 20 por encuadre: media diagnóstica 19.14 ms, FPS informado 46.2, draw calls 7361, primitivas 262279. Actor/protagonista congelados salvo pruebas específicas; varias salas y todo Main cargados. No representa un benchmark de juego ni una mejora de FPS. Para comparaciones válidas de monitores, consultar monitor_before_views.json y monitor_after_views.json, misma cámara y condiciones. Ninguna optimización de iluminación/LOD se aplicó sin evidencia.

Cinco suites independientes ejecutadas sin fallos: inventario, gameplay, lectura de guardado, protagonista 6 y educación/correcciones 7.1. Las advertencias de JSON corrupto son deliberadas en guardado_lectura. Hubo un error de búsqueda del Director en un auxiliar nuevo de prueba; se corrigió y repitió. No fue una regresión del producto. Ver informe general para incidentes de herramienta.

## Limitaciones y pendientes manuales

Muestreo de paneles y prueba frontal no cubren cada esquina, salto ni posible caída exterior. Revisar manualmente el contorno completo. Todos los productos de tienda e inventarios de vendedores: NOT RUN. No se certifica navegación exterior ni toda la misión principal.

Todos los NPC de fondo, animaciones completas de cada humano, iluminación desde cada puerta, interacción con cada objeto y rendimiento durante combate quedan NOT RUN donde no exista una prueba explícita. La interfaz local se observó a resolución de captura, sin certificar todos los tamaños, teclado, daltonismo o lector de pantalla. Sin fotografías nuevas no se certifica fidelidad arquitectónica.

## Evidencia

[guard_after_walk.png](reports/final_7_1/run_20261113_145917/floor_5/guard_after_walk.png)

[Galería de capturas](reports/final_7_1/run_20261113_145917/index.html) · [Resultados finales](reports/final_7_1/run_20261113_145917/floor_5/final_checks.json) · [Inventario](reports/final_7_1/run_20261113_145917/floor_5/inventory.json) · [Requisitos efectivos](reports/final_7_1/run_20261113_145917/floor_5/effective_quests.json)

Los nombres before indican la primera inspección; donde no hubo cambios no se fabricó un después. Los JSON contienen posición de cámara y muestras. Las capturas iniciales del piso 3 con cámara dentro del protagonista, las vistas exteriores por AABB vacío del encuentro del Director y el frontal ocluido de Enfermería no son evidencia de aprobación visual.
