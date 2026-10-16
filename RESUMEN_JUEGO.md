# DuocGames: contenido y recorrido actual

Estado actual tras CIERRE DE CAMPAÑA 1.0 (16-10-2026): **16 misiones, seis bosses y cierre jugable con NEXO**, pendiente de balance humano. El archivo del subterráneo es ahora un paso intermedio. Detalle al final de este resumen y en [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md); las auditorías anteriores se conservan como historial.

Inventario revisado en la escena ejecutada el 15 de octubre de 2026. Los conteos de aulas excluyen oficinas, baños, pasillos y grupos que contienen otras salas. Una sala construida no implica que tenga una misión propia.

## Distribución temática indicada por el usuario

Esta organización rige el diseño de misiones, NPC, bosses, actividades y decoración:

| Piso | Temática |
| --- | --- |
| 1 | Entrada, Punto Estudiantil, casino y coordinación |
| 2 | Biblioteca, salas de estudio, auditorio y papelería |
| 3 | Informática y Telecomunicaciones: programación, redes, hardware, telecomunicaciones, ciberseguridad y tecnología |
| 4, sector norte | Enfermería y Odontología |
| 4, otro sector | Profesores |
| 5–8 | Formación general/transversal: Inglés, Lenguaje, Doctrina de la Iglesia, Ética y otras asignaturas generales |
| −1 | Mecánica Automotriz, Soldadura, Estructuras Metálicas, talleres, herramientas y maquinaria |

El Director de Informática existente permanece en el piso 8 por instrucción expresa del usuario. No reemplazarlo ni trasladarlo. La tabla siguiente inventaría el contenido construido; los desafíos tecnológicos superiores y apuntes antiguos requieren revisión de dependencias antes de cualquier redistribución. El subterráneo conserva su identidad técnica e industrial.

## Desarrollo por etapas: Proyecto NEXO

Primera etapa incorporada: personalización procedural del protagonista, vista previa con rotación al crear partida y menú PERSONALIZACIÓN desde pausa. La apariencia se guarda dentro de la campaña existente. Los cosméticos son visuales y se habilitan mediante progreso; algunos dependen de contenido futuro. Ver [PERSONALIZACION.md](PERSONALIZACION.md) para integración, pruebas y pendientes.

Las fases posteriores solicitadas (historia NEXO, nuevos desafíos y bosses, actividades por piso, subterráneo, final y postgame) todavía no se consideran implementadas. Se desarrollarán sobre los sistemas actuales, con validación por etapa. El Director y el Profesor de Redes se conservan.

## Inmersión: etapa 1 — celular y mensajes

Agregado **P: abrir/cerrar celular**, conectado a ocho aplicaciones: MAPA,
MISIONES, MENSAJES, CONTACTOS, NEXO, COLECCIONABLES, ESTADÍSTICAS y AJUSTES.
La interfaz tiene formato de teléfono vertical con carcasa, pantalla, iconos
de aplicaciones, barra superior y botones Atrás/Inicio/Cerrar. Sus páginas se
mantienen dentro del teléfono y se adaptan al tamaño de la ventana.
Mapa, misiones, registro y opciones reutilizan los menús actuales. En esta
versión, NEXO, coleccionables y estadísticas llevan al registro existente;
no se creó un segundo catálogo ni una campaña nueva.

Los contactos se agregan al hablar con NPC de campaña o responsables de duelos.
Se muestran nombre, rol, piso habitual, progreso de encargo y último mensaje.
Se recuperan también contactos conocidos según los eventos guardados anteriores.
No aparecen contactos desconocidos. Los mensajes tienen identificador estable,
lectura persistida y notificación diferida cuando no hay combate, minijuego o
ventana abierta. Los encargos completados pueden enviar agradecimientos.

Se añadió el campo `phone` al guardado de campaña existente, sin cambiar su
versión. Nueva Partida reinicia mensajes y contactos junto con el progreso.
No se añadieron armas, recompensas, bosses ni geometría.

Ver [CELULAR_Y_MENSAJES.md](CELULAR_Y_MENSAJES.md) para API, archivos, pruebas
y límites. Las etapas posteriores de esta nueva solicitud siguen pendientes.

**Diferencia de versión detectada:** el usuario informa que toda la campaña
NEXO y los sistemas anteriores están completos. La carpeta revisada conserva
los scripts descritos arriba; no se localizaron los módulos de rutinas dinámicas,
ClassroomChallenge o final NEXO. Se solicitó la ruta/rama correspondiente para
ampliarlos sin recrearlos. Esta observación no elimina ni sustituye contenido.

## Campus vivo — fase 1: interacciones contextuales

Gestos procedurales breves del protagonista al recoger, hablar, usar computador,
expendedora, accesos, ascensor y routers; soporte visual para lectura,
inspección y banco de trabajo. No bloquean movimiento ni sustituyen combate.

Se puede usar **E para sentarse** en dos butacas fijas del auditorio del piso 2
(Butaca03_01 y Butaca04_01). Movimiento o E levanta; celular, inventario y apuntes
siguen disponibles. Las sillas recogibles mantienen su funcionamiento actual.
Se validan suelo/espacio y se guarda una posición segura de salida al sentarse.

No se añadieron todavía notas académicas, IA cooperativa, rutas, cambios de
NPC ni mejoras de bosses de esta solicitud. Detalle, archivos y pruebas en
[INTERACCIONES_CONTEXTUALES.md](INTERACCIONES_CONTEXTUALES.md).

## Vida estudiantil — fase 1: horario y asistencia

Nueva app **P → Horario**, dentro del teléfono existente. Muestra una jornada
de lunes con Programación (09:00, Sala 303/piso 3), Redes (11:00, punto compartido
en Sala 303/piso 3) e Inglés (14:00, punto académico del piso 5). Son opcionales.

Registra clases asistidas/perdidas y porcentaje. Asistir requiere presencia y
horario; faltar no bloquea campaña. La primera asistencia a cada materia entrega
25 XP y 10 créditos; repetir en otra jornada no repite el premio. Se guarda junto
a la campaña y se reinicia con Nueva Partida. Avisos no interrumpen combate.

Al no localizarse un reloj independiente en esta copia, se adapta el tiempo
jugado guardado (08:50 inicial, 10 segundos por minuto académico). Puede enlazarse
a otro reloj mediante proveedor. No se crearon calificaciones ni minijuegos en
esta fase. Ver [HORARIO_Y_ASISTENCIA.md](HORARIO_Y_ASISTENCIA.md) para controles,
compatibilidad, archivos, pruebas y pendientes.

## Tamaño del campus (inventario previo, sin cambios físicos)

**9 niveles: subterráneo −1 y pisos 1–8.** No hay un piso 0 independiente. Incluye tres ascensores, escalera principal, escalera de emergencia y exterior con acceso, patio, estacionamientos y zona deportiva.

| Nivel | Aulas identificadas | Otros lugares principales |
| --- | ---: | --- |
| −1 | 0 | Subterráneo, archivo secreto y computador secreto |
| 1 | 0 | Punto Estudiantil, casino y coordinación; inicio de campaña |
| 2 | 0 | Biblioteca con seis salas de estudio, auditorio y sala de impresiones/papelería |
| 3 | 1 | Sala 303 y local de comida |
| 4 | 16 | Sector docente, cowork, pañol de salud, oficinas de administración y dirección, sala de reuniones, cafetería y dos sectores de baños |
| 5 | 0 | Terraza de picnic, tienda y zona del funcionario |
| 6 | 6 | Salas 605–610, dos espacios de estudio y dos sectores de baños |
| 7 | 6 | Salas 705–710, dos espacios de estudio, dos sectores de baños y acceso restringido |
| 8 | 6 | Salas 805–810, dos espacios de estudio, dos sectores de baños y encuentro con el Director |
| Total | **35** | Más seis salas de estudio de biblioteca y seis espacios de estudio superiores |

Las 16 aulas del piso 4 son 401, 402, 404–413 y 415–418; no hay aulas identificadas como 403 o 414 en esa distribución. También hay recintos administrativos; no se suman al total de aulas. En pisos 6 y 7 los nombres internos de algunos nodos conservan números 805–810, mientras los rótulos del juego se adaptan al piso.

## Qué hacer para completar la campaña

Hay **15 misiones: nueve principales y seis secundarias**. La principal se activa automáticamente y el marcador amarillo sigue su próximo objetivo.

| Orden | Misión principal | Qué hacer |
| --- | --- | --- |
| 1 | Primer día | Hablar con Punto Estudiantil, recoger un objeto, resolver el computador inicial y vencer al Encargado y al Chef |
| 2 | La guardiana del conocimiento | Visitar biblioteca, recoger tres libros y vencer a la Bibliotecaria contestando preguntas |
| 3 | Etapa académica del piso 3 | Llegar al piso y completar su computador Antivirus |
| 4 | Etapa académica del piso 4 | Llegar al piso y resolver su computador de contraseña |
| 5 | Etapa académica del piso 5 | Llegar al piso y ordenar archivos en su computador |
| 6 | Práctica avanzada | Completar el computador de seguridad del piso 6 |
| 7 | Acceso restringido | Conseguir TarjetaAcceso, abrir el acceso del piso 7 y completar su computador |
| 8 | Modo Administrador | Completar el computador del piso 8 y vencer al Director |
| 9 | Archivos del subterráneo | Encontrar el archivo secreto; ahora es un paso intermedio |
| 10 | El núcleo de Proyecto NEXO | Autorizar acceso en el −1, prepararse y desactivar NEXO mediante duelo y tres enlaces |

Las etapas desbloquean destinos del ascensor. Las escaleras permiten explorar antes: no existe un bloqueo físico de todo el edificio.

| Secundaria | Encargo |
| --- | --- |
| Las llaves perdidas | Auxiliar del piso 1: encontrar las llaves en el 4 y devolverlas |
| El cargador | Estudiante del piso 2: buscar cargador en el 3 y devolverlo |
| Documentos importantes | Profesor del 3: llevar documentos al Funcionario del 5. Entrega TarjetaAcceso, necesaria para la principal |
| Implementos perdidos | Monitor del piso 1: reunir y devolver balón, paleta y raqueta de los pisos 3–5 |
| Computador infectado | Técnico del 3: completar Antivirus; recompensa USB infectado |
| Ayuda en el casino | Ayudante del piso 1: aceptar el duelo con el Chef |

## Desafíos y personajes

- **Seis jefes:** Encargado Punto Estudiantil, Chef Supremo, Bibliotecaria, Profesor de Redes (opcional), Director de Informática y NEXO. Cinco duelos de combate y uno de preguntas. NEXO sigue pendiente de balance humano. Antes de atacar hay que hablar y aceptar.
- Cada victoria recupera toda la vida. El jefe queda caído y su derrota permanece al cargar.
- **Ocho computadores:** siete del recorrido principal y uno secreto del subterráneo.
- **Tres tipos de minijuego:** ordenar archivos, Antivirus y contraseña. La dificultad varía por piso.
- **Nueve enemigos normales colocados por la campaña**, además de invocaciones de los encuentros. Cinco variantes: normal, rápida, pesada, a distancia y tecnológica.
- **Ocho NPC de campaña**, además de papelería y vendedor adicional.
- Tres máquinas expendedoras y un vendedor adicional usan créditos; la papelería tiene su propio servicio.

## Objetos y progreso

- **51 armas colocadas**, de distintos tipos; la cifra es de objetos, no de modelos diferentes.
- **779 sillas del mobiliario registradas como recogibles** en la ejecución contada, adicionales a las armas colocadas. Las butacas fijas y bancos no se incluyen. E recoge y equipa; J/clic golpea; G suelta. Tienen durabilidad.
- **12 centros de vida** gratuitos y reutilizables, fuera de los duelos; también fijan reaparición con vida completa.
- **Seis checkpoints automáticos** adicionales.
- Bebidas, comida, botiquines, energética y objetos especiales.
- **20 tarjetas**, cuatro apuntes temáticos y cuatro zonas secretas. El computador secreto añade otro descubrimiento.
- Llaves, TarjetaAcceso y CredencialDirector; tres puertas con acceso restringido.
- XP, niveles, créditos y **cinco mejoras:** vida, resistencia, mochila, fuerza y velocidad.
- **Seis logros definidos**, inventario, cuatro accesos rápidos, registro, marcador de objetivo y mapa como lista de pisos.
- Ataque normal, ataque fuerte, estamina, esquiva, lanzamiento de armas compatibles y distracciones.
- Pausa, guía, guardado automático, Continuar y Nueva partida con respaldo. Un único espacio de guardado.

## Qué conviene añadir

1. **Una actividad propia para cada piso.** Los pisos 3–7 repiten principalmente computadores. Añadir un desafío distinto por nivel antes de construir más habitaciones.
2. **Uso para las aulas existentes.** Sobre todo en el piso 4, que tiene 16: talleres, encargos de profesores, pistas o recompensas por explorar. Actualmente no hay una misión independiente por aula.
3. **Mapa visual y numeración uniforme.** Mostrar la sala exacta del objetivo, escaleras, ascensores y centros de vida.
4. **Desafío del auditorio y de la terraza.** Hay espacios construidos que pueden tener más protagonismo en la campaña.
5. **Final NEXO implementado en CIERRE DE CAMPAÑA 1.0.** Validar manualmente el duelo, la secuencia, estadísticas y créditos; el archivo ahora conduce al núcleo. Balance y diversión siguen pendientes.
6. **Sonido.** Los sistemas tienen espacios preparados, pero no se encontraron archivos de música o efectos de audio del juego. Añadir ambiente, pasos, golpes y avisos.
7. **Equilibrio de recursos.** Con 779 sillas y 12 centros de curación, comprobar si el combate resulta demasiado fácil antes de seguir aumentando cantidades.
8. **Mejor navegación de enemigos.** Su persecución puede atascarse entre muebles; falta una navegación completa por zonas.
9. **Eventos y jefe opcional del subterráneo.** Son posibilidades de ampliación; no están completos como contenido actual.
10. **Prueba final y exportación.** Recorrer una partida completa, comprobar rendimiento en el equipo objetivo y validar un ejecutable distribuible.

Las ideas de esta última sección son propuestas, no funciones añadidas durante el conteo.

## PERSONAJES 2.0

Se amplía el visual procedural existente sin reconstruir campaña, inventario, combate ni campus. El Player mantiene su cápsula y API body; su único visual ahora se llama CharacterVisual. Se añaden módulos visuales identificables, palmas menos esféricas, transiciones de velocidad visual, mirada limitada, parpadeo, expresiones discretas, variantes de idle y balanceo ligero de mochila.

El adaptador imported_character_visual.gd permite instalar posteriormente un GLB/GLTF con esqueleto, animaciones y sockets. Usa AnimationTree con BlendSpace1D para locomoción; si falta un clip vuelve al procedural y conserva equipamiento y temporización de daño. Los estados de reserva no representan animaciones humanas reales.

Los ocho NPC de campaña tienen perfiles estables por ID guardados en npc_visuals, roles de ropa y variación de tonos/cabello/cuerpo. Papelería y guardias conservan sus servicios/rutas con identidad visual determinista. Hay props/poses de trabajo reutilizables y LOD visual por distancia/piso, sin detener misiones o combate.

Las conversaciones importantes pueden usar cámara cercana con comprobación de obstáculos y mirada mutua. Punto, Chef, Bibliotecaria, Director y el Profesor de Redes reutilizan su aspecto previo y reciben una capa de pose/props neutrales. No se crean bosses ni personajes que falten en esta versión.

Personalización conserva sus recompensas y guardado, añade zoom, retirada de accesorios, TECH SET, SPORT SET y NEXO JACKET. Esta última se desbloquea al completar postgame o con una futura derrota de NEXO; nunca cambia la ropa elegida. Espejo/armario junto a la entrada abren el menú existente fuera de combate.

Los catorce puntos de entrega, instrucciones de importación, estados reales/preparados, limitaciones, pruebas y recursos externos pendientes están documentados en [PERSONAJES_2_0.md](PERSONAJES_2_0.md). No se han creado escenas de historia, Rival, rutinas dinámicas o modelos externos que todavía no existían; Foot IK y ragdoll siguen desactivados.

Validación: diez suites aprobadas, incluidas 59 comprobaciones nuevas, 60 de interacciones, 31 del celular y revisión de 192 scripts/recursos. Se restauró el tipo QUIZ ausente en el controlador de la Bibliotecaria para conservar su duelo de preguntas.

## CAMPUS VIVO 2.0

GameplayDirector observa el estado existente de campaña, misión, piso, vida, combate y reloj académico. Coordina QUIET/NORMAL/ACTIVE/STORY_LOCK y oportunidades ambientales con cooldown, sin generar durante bosses, modales, minijuegos o escenas bloqueadas.

CampusState expone NORMAL, ANOMALY_LOW/MEDIUM/HIGH y RESTORED a partir de progreso NEXO existente. Pantallas, luces de monitores, carteleras, poses y conversaciones reaccionan sin modificar geometría ni objetivos. El pulso es breve, raro y no causa daño.

Hay veinte definiciones ambientales, eventos únicos persistentes, escenas con figurantes limitados que reutilizan Personajes 2.0, ayudas voluntarias y recompensas acotadas. No se crea otro sistema de NPC dinámicos.

StoryMoments presenta hitos existentes y primeras visitas, con descubrimiento persistente. El mapa incorpora notas y viaje postgame a destinos descubiertos con llegada segura. Inventario añade favoritos/protecciones/comparador; celular añade actividad reciente, historial importante y contactos favoritos.

Los cinco bosses existentes conservan sus estadísticas, fases y cooldowns. El controlador común añade señal de especial pendiente, checkpoint pre-duelo, snapshot y reintento rápido sin duplicar progreso ni recompensas; hay retorno voluntario a la arena sin nuevas paredes.

BalanceTools/QA generan reportes locales de datos, economía, IDs, referencias y navegación pendiente de revisión. La telemetría de desarrollo es local, limitada y opt-in. El guardado incorpora save_version 2 con migración compatible y conserva datos anteriores.

Se incorporan recursos de extensión, helpers de contenido, localización ES/EN parcial y ajustes persistentes de ventana, calidad y FPS. El LOD existente se conserva y amplía, manteniendo activos los sistemas críticos.

Documentación: [CAMPUS_VIVO_2_0.md](CAMPUS_VIVO_2_0.md) y [GUIA_CREAR_CONTENIDO.md](GUIA_CREAR_CONTENIDO.md). La prueba nueva cubre 52 comprobaciones; las regresiones existentes siguen siendo parte de la validación. El recorrido completo, clipping, rutas físicas y FPS con renderizado requieren revisión manual.

## PLAYTEST Y BALANCE 1.0 — auditoría del 15-10-2026

Se revisaron scripts, Resources/configuración, escena principal y herramientas locales existentes usando godot-mcp-toolkit y ejecuciones aisladas de Godot. Se conserva todo el contenido anterior. Inventario actual: 15 misiones (9 principales y 6 secundarias), 5 bosses, 23 armas de catálogo, 51 pickups de arma, 779 sillas y 12 centros de vida. El Profesor de Redes es opcional; Documentos importantes es necesaria para obtener TarjetaAcceso aunque esté etiquetada secundaria.

Se corrigió el bloqueo de documentos con mochila llena y su recuperación en partidas antiguas; objetivos de boss aceptan la derrota persistida aunque falte el evento redundante. Los lotes de inventario respetan capacidad, los stacks llenos no informan éxito y add_item devuelve cantidad añadida. No se modificaron daño, vida, durabilidad, precios, XP, recompensas, ubicación de contenido ni geometría.

Guardar/cerrar durante intro, combate o muerte pendiente de boss conserva un estado completo y coherente previo al duelo: campaña, objetos, vida, inventario y checkpoint. Continuar deja al boss neutral. El reintento existente mantiene su snapshot; elegir checkpoint lo abandona. La política se explica antes de aceptar el duelo. save_version sigue en 2, con migración existente.

CampaignUI tiene cola limitada y deduplicada de avisos CRITICAL/MISSION/REWARD/INFO; espera durante modales/intros. El tutorial evita avanzar mientras el jugador está ocupado. El escaneo contextual descarta otros pisos antes de consultas: 2001,69 → 605,51 microsegundos por consulta en una muestra de 100 cerca del spawn; no es una medición de FPS global.

Duración analítica pendiente de playtest: principal 1–2,5 h; principal + secundarias 2–4 h; contenido disponible completo 3–6 h; postgame abierto. El cierre implementado es el archivo del subterráneo, no un combate final NEXO. Tampoco se encontraron Boss Rush, NG+, modos de dificultad, bosses académicos adicionales ni taller de reparación de armas; no se recrean en esta etapa.

La suite nueva de balance pasa 20 comprobaciones; también pasan las regresiones de campaña, inventario, gameplay, Chef, Director, Redes (38), horario (27), celular (31), campus (52), Personajes 2.0 (59), interacciones (60), nueva partida, lector de guardado y revisión de 219 scripts/recursos. La carga headless registró 5577 ms hasta frame 120 y 368,11 MiB de memoria estática; render/GPU y recorrido humano siguen pendientes.

Detalle de valores, razones, cambios y ruta crítica: [BALANCE_1_0.md](BALANCE_1_0.md). Conclusiones y hallazgos abiertos: [BALANCE_REPORT_1_0.md](BALANCE_REPORT_1_0.md). Ruta y casillas por boss/misión: [PLAYTEST_1_0.md](PLAYTEST_1_0.md). Datos de la ejecución aislada: [reports/balance_1_0_data.json](reports/balance_1_0_data.json). No se inventaron resultados de partidas humanas ni se envió telemetría a internet.

## CIERRE DE CAMPAÑA 1.0 — 16-10-2026

El archivo secreto del −1 conserva su misión/recompensa y ahora revela Proyecto NEXO, añade una nota legible en Registro y activa **El núcleo de Proyecto NEXO**: encontrar acceso y desactivar NEXO. No inicia combate automáticamente. El acceso comprueba progreso, archivo leído y CredencialDirector; el mapa señala la bahía industrial este del −1 aproximadamente.

El nodo runtime `PisoMenos1/NexoFinalArea` ocupa espacio existente alrededor de `(48, −12,018, −100)`, sin reconstruir ni mover talleres. Incluye núcleo digital no humano, pantallas/racks, luces locales y tres terminales. NEXO ofrece Desactivar/Retirarse; aceptar reutiliza cámara, intro, boss_duel_controller, HUD, proyectiles, efectos, snapshot/reintento y guardado existentes.

NEXO tiene **1200 HP provisionales, configurables en resources/live/nexo_final.tres; PENDIENTE DE BALANCE HUMANO**. Fase 1: paquete/pulso/zona; fase 2: selección de patrones simplificados de Redes/interferencia; fase 3 ≤35%: tres enlaces, protección parcial y Protocolo de Borrado telegrafiado. Cada terminal reduce protección; desactivar las tres es necesario para el apagado. Máximo tres proyectiles y una zona, cooldowns y sin repetir inmediatamente ataque.

RouterPortatil ayuda pasivamente reduciendo protección, sin consumo; USBInfectado usa ItemEffects (60 antes de escudo y stun 2 s contra NEXO). Ninguno es obligatorio. No se inventan DepuradorPortatil ni InsigniaIntegridad. Los valores de armas, enemigos, cinco bosses anteriores, curación, XP, créditos/precios y recompensas anteriores se conservan.

La muerte ofrece REINTENTAR NEXO con recursos, arma/desgaste y quickslots previos. La victoria limpia amenazas, muestra NEXO DESACTIVADO/SISTEMAS RESTAURADOS, guarda campaign_completed y derrota/misión, restaura CampusState, desbloquea los cosméticos NEXO existentes y permite créditos omitibles, estadísticas reales y continuar explorando. Director y Técnico comentan el final. NEXO permanece derrotado al cargar; las secundarias/actividades pendientes continúan disponibles. Boss Rush, NG+, Rival, finales múltiples y NEXO_0 no existen en esta versión y no se crean.

Las nueve sillas pendientes tenían IDs correctos: el validador buscaba demasiado cerca y chocaba con asiento/respaldo/escritorio. Se corrigió la muestra, sin cambiar geometría/IDs/alcance, y se probaron sus recogidas. Resultado local general: 779/779; la navegación humana sigue pendiente.

La suite de cierre pasa 111 comprobaciones y las regresiones anteriores siguen aprobadas; revisión de 226 scripts/recursos. Se inspeccionaron con renderizado diálogo, núcleo, HUD y fase 3 mediante fixture, sin afirmar playthrough ni balance. Partidas antiguas conservan progreso y desbloqueos, reciben la final pendiente y no se marcan completadas solo por el archivo. Save_version sigue en 2.

Documentación completa: [CIERRE_CAMPANA_1_0.md](CIERRE_CAMPANA_1_0.md). Balances nuevos pendientes de validación humana en [BALANCE_1_0.md](BALANCE_1_0.md); recorrido en [PLAYTEST_1_0.md](PLAYTEST_1_0.md), sección FINAL NEXO.
