# Informe de estado de DuocGames para revisión y mejoras con IA

Fecha de revisión: 19 de octubre de 2026.

## 1. Qué es el proyecto

DuocGames es un videojuego 3D de exploración de un campus, con combate, desafíos académicos, misiones y progresión. El jugador interpreta a un estudiante que recorre el edificio, ayuda a personajes, obtiene equipo y descubre Proyecto NEXO hasta enfrentarse a su núcleo.

Está desarrollado en Godot con GDScript. La documentación indica Godot 4.7.2; `project.godot` declara la familia 4.7 y utiliza Compatibility/OpenGL. La escena inicial es `Main.tscn`. El protagonista y varios sistemas y contenidos se crean durante la ejecución.

Este informe combina inspección del código y configuración con documentación y reportes existentes. No se ejecutó el juego ni se repitieron las pruebas durante esta revisión. Los resultados de rendimiento y validación que se mencionan son históricos, con sus límites; no certifican el funcionamiento actual de una partida completa.

## 2. Campus construido y regla obligatoria de distribución

Hay nueve niveles: subterráneo −1 y pisos 1–8; no existe un piso 0 independiente. Dispone de tres ascensores, escalera principal, escalera de emergencia y exterior con entrada, patio, estacionamientos y zona deportiva. La documentación de inventario registra 35 aulas identificadas, además de salas de estudio y recintos de servicios; ese conteo no se repitió en esta revisión.

Toda mejora debe respetar `AGENTS.md`:

| Ubicación | Temática autorizada |
|---|---|
| Piso 1 | Entrada, Punto Estudiantil, casino y coordinación |
| Piso 2 | Biblioteca, salas de estudio, auditorio y papelería |
| Piso 3 | Informática y Telecomunicaciones: programación, redes, hardware, ciberseguridad y tecnología |
| Piso 4, sector norte | Enfermería y Odontología |
| Piso 4, otro sector | Profesores |
| Pisos 5–8 | Formación general y transversal: Inglés, Lenguaje, Doctrina de la Iglesia, Ética y afines |
| Subterráneo −1 | Mecánica Automotriz, Soldadura, Estructuras Metálicas, talleres, herramientas y maquinaria |

El Director de Carrera de Informática permanece en el piso 8 por instrucción expresa del usuario. No trasladarlo ni reemplazarlo. Los nombres antiguos de nodos o scripts no autorizan a cambiar la temática de un sector. Antes de mover contenido existente hay que revisar misiones, accesos, recompensas y guardado.

La geometría se organiza en `PisoMenos1`, `Piso1` a `Piso8`, `SistemasCompartidos`, `Exterior` y herramientas de edición. Las carpetas de pisos tienen fichas `INFORMACION.md`. No toda sala construida tiene una actividad propia.

## 3. Sistemas que ya existen

### Movimiento e interacción

- Movimiento, carrera, salto, agacharse y cámara con zoom y comprobaciones de obstáculos.
- Interacción contextual con alcance y obstáculos para hablar, recoger objetos, usar computadores, puertas, ascensores y servicios.
- Gestos procedurales de conversación, recogida, lectura y uso de objetos.
- Posibilidad de sentarse en dos butacas fijas del auditorio. Las sillas recogibles conservan un comportamiento distinto.
- Ayuda de controles, pausa, mapa, registro y seguimiento de objetivo con piso y distancia.

### Combate, inventario y economía

- Ataques normales, ataque cargado, esquiva y estamina mediante extensiones del combate.
- Armas con equipamiento y durabilidad por instancia; caída, recogida y lanzamiento en objetos compatibles.
- 51 fuentes de armas de escenario definidas en `campus_content.gd`, más mobiliario recogible. Los reportes anteriores registran 779 sillas; no confundirlas con 779 tipos de arma.
- Mochila con categorías, cantidades, accesos rápidos, objetos clave y consumibles.
- Favoritos, protección de descarte y comparación de armas mediante las mejoras de Campus Vivo.
- Curación, alimentos, bebida energética y efectos especiales como USB infectado.
- Créditos, XP, niveles, mejoras, vendedores y recompensas protegidas frente a entregas duplicadas mediante un registro por origen.
- Checkpoints y centros de vida; la guía registra 12 centros gratuitos y reutilizables.

### Campaña y orientación

El código de `quest_manager.gd` define **16 misiones: 10 principales y 6 secundarias**. Hay estados, requisitos, objetivos contables, recompensas y desbloqueos. La guía de objetivos omite requisitos opcionales al elegir el siguiente paso obligatorio.

| Secuencia principal | Contenido |
|---|---|
| Primer día | Hablar con Punto Estudiantil, recoger un objeto, completar PC inicial y vencer al Encargado y al Chef |
| Biblioteca | Visitarla, reunir tres libros y superar a la Bibliotecaria |
| Piso 3 | Completar el desafío académico del computador |
| Piso 4 | Completar el desafío de documentación docente |
| Piso 5 | Vencer al Profesor de Inglés |
| Piso 6 | Vencer al Profesor de Lenguaje |
| Piso 7 | Abrir el acceso restringido y vencer al Profesor de Ética |
| Piso 8 | Vencer al Director |
| Archivo del −1 | Encontrar el archivo secreto, que sirve de etapa intermedia |
| Final NEXO | Autorizar el acceso al núcleo y desactivar NEXO |

Los computadores de los pisos 5–8 son preparación opcional: el código adapta los requisitos antiguos conservando IDs y partidas completadas. Los ascensores desbloquean destinos por progreso; las escaleras permiten explorar antes, por lo que esos desbloqueos no equivalen a cerrar físicamente todos los pisos.

Secundarias existentes: llaves perdidas, cargador, entrega de documentos, implementos deportivos, computador infectado y ayuda en el casino. La misión de documentos entrega `TarjetaAcceso`, necesaria para avanzar por el acceso del piso 7; aunque se clasifica como secundaria, tiene una dependencia de la principal que debe preservarse o rediseñarse explícitamente.

### Bosses

Hay nueve encuentros identificados en código y documentación actual:

1. Encargado de Punto Estudiantil.
2. Chef Supremo.
3. Bibliotecaria, mediante preguntas.
4. Profesor de Redes en piso 3, opcional.
5. Profesor de Inglés en piso 5.
6. Profesor de Lenguaje en piso 6.
7. Profesor de Ética en piso 7.
8. Director de Informática en piso 8.
9. NEXO en el subterráneo.

Los duelos requieren conversación y aceptación. Hay introducciones, señales de ataques y persistencia de derrotas. Campus Vivo incorpora reintento con snapshot temporal de vida, inventario, equipo, durabilidad y estamina; no es un segundo guardado permanente.

El final NEXO se integra desde `campus_campaign.gd` y tiene scripts específicos y un Resource editable. Su diseño documentado incluye tres fases, proyectiles, pulsos, zonas y tres enlaces que deben desactivarse durante la última fase. El RouterPortatil ayuda y el USBInfectado aplica un efecto especial, pero no son obligatorios. La victoria marca el final, restaura el estado del campus y ofrece créditos y estadísticas. Los bosses nuevos y NEXO siguen pendientes de balance humano.

### Celular y vida académica

- Celular integrado con mapa, misiones, mensajes, contactos y accesos al registro, opciones y horario.
- Contactos descubiertos, mensajes con lectura persistida y notificaciones diferidas para evitar interrumpir encuentros.
- Historial de diálogos importantes, actividad reciente y contactos favoritos.
- Horario opcional con Programación y Redes en piso 3 e Inglés en piso 5.
- Registro de asistencia y faltas con recompensas iniciales limitadas; faltar no bloquea la campaña.
- Reloj académico adaptado al tiempo jugado: comienza a las 08:50 y utiliza 10 segundos por minuto académico.

Esto no constituye todavía una simulación académica completa con notas, semanas, exámenes y rutinas independientes para todos los NPC.

### Campus Vivo y mundo reactivo

`scripts/live/` contiene un director de actividad, catálogo de eventos ambientales, estados del campus, presentación reactiva y momentos narrativos.

- Catálogo documentado de 20 situaciones, como estudio, almuerzo, reunión docente, talleres, orientación, ayuda y anomalías NEXO.
- Límite de una situación activa, pausas y bloqueos durante combates, menús, muerte o condiciones incompatibles.
- Eventos únicos persistidos y presupuesto limitado de recompensas ambientales.
- Reacciones visuales, pantallas y avisos que cambian con el progreso.
- Descubrimiento de pisos y áreas, anotaciones del mapa y viaje rápido postgame condicionado a destinos descubiertos y seguros.
- Figurantes temporales y poses ambientales; no equivalen a una IA completa de estudiantes con navegación, relaciones y rutinas.

### Personajes y personalización

- Protagonista y personajes con visuales procedurales articulados y estilizados.
- Variantes de ropa, cabello, accesorios, mochila y cosméticos ligados al progreso.
- Apariencia del jugador y perfiles de NPC persistidos.
- Mirada limitada, parpadeo, expresiones y cámara de diálogo con comprobaciones de espacio.
- Presupuesto visual por distancia y piso mediante niveles de detalle y suspensión de animación secundaria.
- Adaptador preparado para modelos importados con rig, animaciones y sockets compatibles, conservando el procedural si falla.

Existe un piloto GLB aislado en `assets/characters/human_pilot/` y escenas de prueba. El reporte de inspección encontró **ausencia de esqueleto, skin y animaciones**, además de geometría muy densa. Por eso no debe describirse como protagonista humano animado terminado. El piloto sirve para inspección estática y el personaje funcional sigue utilizando el visual procedural.

### Guardado y ajustes

- Continuar y nueva partida; respaldo al reiniciar y comprobación de errores de escritura.
- Guardado de campaña en `user://campus_campaign_v1.json`, con `save_version = 2` y envoltorio `version = 1` por compatibilidad.
- Persistencia de misiones, bosses, objetos, inventario, apuntes, progreso, apariencia, celular, asistencia y Campus Vivo.
- Migración de datos anteriores y bloqueo de escritura ante versiones futuras no soportadas.
- Preferencias separadas del progreso en `campus_settings.cfg`.
- Calidad gráfica, límite de FPS, modos de ventana e infraestructura ES/EN con traducción parcial.
- Audio procedural y sistema de audio de campaña; una banda sonora y un paisaje sonoro final no están certificados.

## 4. Estructura técnica para orientar a otra IA

| Ruta | Responsabilidad |
|---|---|
| `project.godot` | Inicio, renderizador y complementos |
| `Main.tscn` | Campus y estructura principal; aproximadamente 8,84 MB al revisar |
| `scripts/juego/` | Jugador, visuales, movimiento y sistemas base |
| `scripts/campaign/campus_campaign.gd` | Orquestación e integración de campaña, guardado, UI y sistemas |
| `scripts/campaign/quest_manager.gd` | Definiciones, requisitos y avance de las 16 misiones |
| `scripts/campaign/campus_content.gd` | Generación de objetos, armas, NPC y otros contenidos |
| `scripts/inventory/` | Inventario, catálogo y efectos de objetos |
| `scripts/live/` | Eventos, estados, ajustes, calidad de vida, diagnóstico y migración |
| `scripts/pisos/` | Contenido propio de cada nivel |
| `scripts/compartidos/` | Ascensores, puertas y utilidades reutilizables |
| `resources/live/` | Configuraciones editables de bosses superiores, NEXO y eventos |
| `tests/` | Regresiones, recorridos, inspecciones y escenas de diagnóstico |
| `reports/` | Datos y capturas de validaciones anteriores |

El complemento habilitado es `godot_mcp_toolkit`; también existe `godot_ai`, que no figura habilitado. Las herramientas de edición y ciertos generadores no deben ejecutarse indiscriminadamente: pueden modificar geometría. Encontrar un script no demuestra que esté activo; comprobar siempre su integración desde la escena o los sistemas de arranque.

## 5. Validación y rendimiento conocidos

Hay pruebas de campaña, inventario, movimiento, nueva partida, lectura de guardado, organización de pisos, ascensores, rutas, celular, horario, interacciones, personajes, bosses, Campus Vivo y NEXO. Los documentos registran ejecuciones aprobadas en etapas anteriores. Este informe no vuelve a certificar esas ejecuciones.

El perfil más reciente consultado, `PERFORMANCE_PROFILE.md`, documenta aproximadamente 45.184 nodos cargados, 24.213 MeshInstance3D y 510 luces, con una luz que proyectaba sombras en la captura. Son cifras del campus ejecutado en esa prueba, no de objetos simultáneamente visibles ni un nuevo censo actual.

La medición aisló un coste importante en el renderizado de sombras del campus. Se redujo el alcance del sol por calidad y se mejoró el presupuesto visual de personajes. Las capturas posteriores rondaron 60–65 FPS en una vista concreta, pero hubo encuentros sintéticos con muestras inferiores. No se dispone de una certificación de 60 FPS para todo el juego ni de una separación concluyente entre coste de GPU y CPU de renderizado.

La escena sigue siendo grande y el campus se carga completo. No existe `export_presets.cfg` en la carpeta revisada y no se certifica una distribución final fuera del editor. Tampoco se encontró un comando Godot disponible en PATH durante esta revisión.

## 6. Qué está pendiente o requiere mejoras

Estas son propuestas y verificaciones pendientes, no fallos reproducidos ahora:

| Prioridad | Trabajo | Criterio para considerarlo resuelto |
|---|---|---|
| Alta | Partida completa de principio a final | Llegar desde nueva partida hasta NEXO con guardado/carga, documentos, accesos y recompensas correctos |
| Alta | Balance de bosses y economía | Medir duración, muertes, daño recibido, consumo de curación y disponibilidad de armas con jugadores reales |
| Alta | Sincronizar documentación | Un único estado vigente, con guías acordes a bosses superiores y final NEXO |
| Alta | Preparar distribución | Exportar, revisar complementos y probar el ejecutable en otro equipo y con datos de usuario limpios |
| Media | Rendimiento representativo | Perfilar recorridos y duelos completos con tiempos de frame, memoria y hardware objetivo |
| Media | Claridad de progresión | Verificar que el jugador entienda la entrega de documentos, la TarjetaAcceso y los objetivos opcionales |
| Media | Presentación visual y cámara | Revisar proporciones, clipping, puertas, escaleras, sombras y encuadres con renderizado real |
| Media | Consistencia del guardado | Comprobar partidas antiguas, corrupción, errores de escritura y reintentos consecutivos sin duplicaciones |
| Media | Narrativa y vida académica | Evaluar variedad de diálogos y actividades sin multiplicar sistemas existentes ni volver obligatoria la asistencia por accidente |
| Media | Audio y traducción | Revisar mezcla y feedback de acciones; completar cadenas de interfaz pendientes |
| Posterior | Personajes humanos importados | Probar primero un rig y clips reales con presupuesto de geometría, sockets, armas y rendimiento |
| Posterior | Modularizar el campus | Estudiar escenas por piso, mallas/materiales compartidos y sustitución de CSG conservando accesos y guardados |

Boss Rush, Nueva Partida+, Rival, notas académicas completas y rutinas autónomas de toda la población no están confirmados como sistemas implementados. Tratarlos como ampliaciones propuestas hasta verificar código e integración.

## 7. Contradicciones documentales detectadas

- `REVISION.md` enumera como pendientes campaña, pausa y guardado que actualmente tienen implementación.
- `GUIA.md` conserva un recorrido donde los computadores superiores son obligatorios y el archivo cierra la principal. El código actual utiliza bosses superiores y una misión final NEXO posterior.
- `RESUMEN_JUEGO.md` mezcla un resumen actualizado con apartados antiguos que dicen que no existe el final NEXO. La integración actual de `nexo_final_area.gd` y la misión `nexo_final` contradicen ese pendiente antiguo.
- `PERSONAJES_2_0.md` contiene observaciones históricas anteriores a los bosses de Inglés, Lenguaje, Ética y NEXO.
- `RENDIMIENTO.md` conserva cifras de un campus anterior; para las optimizaciones posteriores hay que consultar también `PERFORMANCE_PROFILE.md`.

Para resolver diferencias, revisar código integrado y reportes de cada etapa. No sumar conteos de versiones distintas ni asumir que un pendiente histórico sigue abierto.

## 8. Prompt listo para enviar a otra IA

> Estoy desarrollando DuocGames, un juego 3D en Godot sobre un campus con exploración, combate y desafíos académicos. Usa este informe como contexto y distingue implementación existente, resultados históricos y propuestas. Ya hay 16 misiones, nueve bosses incluido el final NEXO, inventario, guardado con migración, personalización procedural, celular, horario opcional, eventos ambientales y mejoras de rendimiento.
>
> Quiero mejorar la experiencia y la calidad del proyecto conservando lo construido. Primero evalúa sus fortalezas, dependencias y riesgos. Después propón mejoras priorizadas de jugabilidad, progresión, narrativa, interfaz, combate, ambiente, arte y rendimiento. Para cada mejora indica el problema concreto, comportamiento esperado, sistemas afectados, esfuerzo aproximado y cómo validarla. Separa correcciones necesarias de ampliaciones opcionales. Si no tienes acceso al repositorio, identifica tus hipótesis y no presentes bugs como comprobados.
>
> Respeta estrictamente la temática por piso descrita en el informe y AGENTS.md. El Director de Informática debe permanecer en el piso 8. No dupliques campaña, inventario, reloj, celular, guardado o director de eventos. Conserva IDs y compatibilidad de partidas; antes de mover contenido analiza requisitos, accesos y recompensas. El modelo humano GLB actual no tiene rig ni animaciones: cualquier sustitución visual requiere un piloto compatible y medido. No prometas rendimiento sin mediciones representativas ni des por existentes sistemas como Rival, Boss Rush o Nueva Partida+.
>
> Organiza las propuestas en etapas pequeñas y verificables. Comienza con una etapa de cierre y pulido que permita completar y distribuir una versión estable, y deja la expansión de contenido para después. Solicita solo la información indispensable que no pueda deducirse del informe o del código disponible.
