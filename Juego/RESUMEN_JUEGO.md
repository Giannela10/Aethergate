# DuocGames: contenido y recorrido actual

## DUOCGAMES EDUCATIVO 1.0 — 20-10-2026

F5 abre Login y carga el menú STUDENT/TEACHER/ADMIN según el perfil. Google está
implementado con PKCE y callback local, pero necesita configurar y validar una
instancia real de Supabase. En debug existen DEV STUDENT/TEACHER/ADMIN sin red.
El panel docente permite crear, editar, activar y previsualizar preguntas.
El Piso 3 añade un desafío INF_GENERAL con progreso local separado del desbloqueo
argumental. Campaña, inventario, NEXO y bosses anteriores se conservan.

Documentación: [sistema educativo](EDUCATION_SYSTEM_1_0.md),
[arquitectura](AUTH_ARCHITECTURE.md), [configuración Google](GOOGLE_SUPABASE_SETUP.md)
y [plan del Piso 3](FLOOR3_EDUCATION_PLAN.md). No se construyeron salas ni se
convirtieron todavía docentes a mentores. Las estadísticas docentes y la
administración avanzada siguen pendientes. Las secciones anteriores de combate
describen el sistema conservado para su futura conversión a simulaciones.

## Estado vigente: bosses académicos 3.0 — 19-10-2026

Hay **15 bosses y 20 misiones** (10 principales y 10 secundarias). Los apartados fechados anteriormente son historial; sus pisos/conteos no prevalecen sobre esta actualización. Detalle en [ACADEMIC_BOSSES_3_0.md](ACADEMIC_BOSSES_3_0.md).

- Piso 1: Encargado y Chef intactos (Chef 350 HP). Piso 2: Bibliotecaria intacta.
- Piso 3: Datos (500) y Algoritmos (525); basta vencer uno para la principal. Redes (550) se conserva opcional con su ID/recompensa.
- Piso 4 norte/salud: Enfermería y Odontología (475 cada uno). Sector docente: Coordinador (500), con misión de hablar con Algoritmos, Inglés y Matemáticas y regresar.
- Piso 5: exploración general y servicios anteriores; Funcionario/documentos/TarjetaAcceso conservados. Sin boss nuevo.
- Piso 6: Inglés (450) y Ética (550). Piso 7: Habilidades de Comunicación (500, profesor_lenguaje conservado) y Matemáticas (525). Son opcionales.
- Piso 8: Director (700) intacto, con pruebas previas de conexión, Antivirus breve y configuración PC01/02/03. −1: NEXO (1200) intacto.

pc5/pc6/pc7 se trasladan a 6/7/6 conservando IDs, game_id, preparación, señales y progreso; pc8 permanece en 8. No se reinician victorias antiguas. Director ya derrotado recibe sus tres flags previas por compatibilidad. Los premios nuevos tienen efectos y ledger único. **Balance y recorrido humano pendientes**, independientemente de resultados automáticos.

Estado actual (16-10-2026): **16 misiones, nueve bosses y cierre jugable con NEXO**. Inglés/Lenguaje/Ética añaden duelos de acción en pisos 5/6/7; computadores 5–8 son preparación opcional. Personajes con ropa modular ampliada y fallback procedural. Nuevos HP pendientes de balance humano. Detalle en [BOSSES_SUPERIORES_2_0.md](BOSSES_SUPERIORES_2_0.md); las auditorías anteriores se conservan como historial.

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

El Director de Informática existente permanece en el piso 8 por instrucción expresa del usuario. No reemplazarlo ni trasladarlo. Se revisaron las dependencias: las actividades superiores ahora usan contenido docente/transversal y documental NEXO sin cambiar sus IDs; los apuntes tecnológicos están en piso 3. El subterráneo conserva su identidad técnica e industrial.

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

Hay **16 misiones: diez principales y seis secundarias**. La principal se activa automáticamente y el marcador amarillo sigue su próximo objetivo.

| Orden | Misión principal | Qué hacer |
| --- | --- | --- |
| 1 | Primer día | Hablar con Punto Estudiantil, recoger un objeto, resolver el computador inicial y vencer al Encargado y al Chef |
| 2 | La guardiana del conocimiento | Visitar biblioteca, recoger tres libros y vencer a la Bibliotecaria contestando preguntas |
| 3 | Etapa académica del piso 3 | Llegar al piso y completar su computador Antivirus |
| 4 | Etapa académica del piso 4 | Llegar al piso y organizar documentos docentes |
| 5 | Etapa académica del piso 5 | Llegar al piso y vencer al Profesor de Inglés; vocabulario como preparación opcional |
| 6 | Práctica de Lenguaje | Vencer al Profesor de Lenguaje; comprensión lectora como preparación opcional |
| 7 | Acceso restringido | Conseguir TarjetaAcceso, abrir acceso7 y vencer al Profesor de Ética; decisiones como preparación opcional |
| 8 | Modo Administrador | Vencer al Director; revisión documental NEXO como preparación opcional |
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

- **Nueve jefes:** Encargado Punto Estudiantil, Chef Supremo, Bibliotecaria, Profesor de Redes (opcional), Profesor de Inglés, Profesor de Lenguaje, Profesor de Ética, Director de Informática y NEXO. Ocho duelos de acción y uno de preguntas (Bibliotecaria). Nuevos bosses/NEXO pendientes de balance humano. Antes de atacar hay que hablar y aceptar.
- Cada victoria recupera toda la vida. El jefe queda caído y su derrota permanece al cargar.
- **Ocho computadores:** pc_intro/pc3/pc4 del recorrido, pc5–pc8 de preparación opcional y uno secreto del subterráneo; IDs intactos.
- **Minijuegos:** clasificación de archivos y sus variantes docente, Inglés, Lenguaje, Ética y NEXO; Antivirus en piso 3 y PC industrial secreto. Contraseña permanece disponible como sistema heredado, sin actividades obligatorias incompatibles en pisos superiores. Los IDs originales se conservan.
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

## Correcciones de actividades, guardado y Chef — 16-10-2026

Esta actualización reemplaza los valores y actividades anteriores que se conservan como registro histórico.

- FIX: Actividades por piso. pc4 (game_id 2): organización docente; pc5 (0): vocabulario de Inglés; pc6 (2): comprensión lectora de Lenguaje; pc7 (1): decisiones de Ética; pc8 (2): revisión documental NEXO. Reutilizan la clasificación existente, su señal completed y el circuito finished(success). No se renumeran game_id, campaign_id, quest_id ni eventos computer:ID. pc_intro, pc3 y pc_secreto conservan sus juegos. Director permanece en piso 8.
- FIX: Apuntes. Apunte_datos pasa de piso 4 a 3, Apunte_redes de 6 a 3 y Apunte_ia de 8 a 3. Apunte_programacion ya estaba en 3. Se conservan world_id, item_id hoja_impresa, textos y flags collected; no se duplican.
- FIX: Error de autoguardado. Se comprueban apertura, escritura/flush, copia .bak y reemplazo .tmp → definitivo. Un fallo no marca éxito ni borra original/backup/temporal recuperable. Consola registra ruta y error; jugador recibe «No se pudo guardar la partida.» una sola vez por racha de fallos. Tras guardar correctamente se habilita un nuevo aviso. Nueva partida reutiliza el mismo escritor.
- FIX: WorldItem parcial. Se descuenta solo la cantidad aceptada; el sobrante permanece visible/interactivo y muestra xN. Solo al agotarse se marca collected y se emiten eventos de recogida especial/apunte. El JSON añade remaining_quantity[world_id]; collected sigue siendo booleano. Saves antiguos sin cantidad usan el valor original, salvo collected=true. Respawn explícito mantiene su comportamiento. Save_version sigue en 2 y el snapshot previo al boss incluye el nuevo diccionario.
- BALANCE: Chef Supremo HP reducido de 450 a 350, tanto actor como BossDuelController de Main.tscn. Tres fases conservadas a 60% y 30% (210/105 con el nuevo máximo). No cambian daño, velocidad, ataques, bandejas, cooldowns, recompensas, economía, XP, precios ni otros bosses.

Validación nueva: tests/CampusFixesCheck.tscn y tests/campus_fixes.gd. Reporte de ejecución: reports/campus_fixes_result.json. Incluye inventario real lleno, 5 → acepta 2 → quedan 3, guardar/cargar campaña real, recoger sobrante, saves antiguos, claves, IDs/señales de los cinco perfiles, desbloqueos 7/8, apuntes, HUD/fases/reset Chef y fallo de reemplazo inyectado. Los errores de consola provocados expresamente por el test de guardado son esperados.

PENDIENTE DE PRUEBA MANUAL:

- [ ] Recorrer los pisos 3–8; comprobar accesibilidad de apuntes y lectura de actividades a distintas resoluciones.
- [ ] Completar la ruta de campaña jugando cada actividad; verificar ascensores y puertas con una partida personal respaldada.
- [ ] Chef: comprobar HUD 350/350, morir/reintentar y continuar una partida anterior; evaluar dificultad humana manteniendo el resto del balance.
- [ ] Probar aviso discreto ante un fallo real de disco/permisos y recuperación; la inyección automática no simula un corte de energía.
- [ ] Recoger parcialmente un lote en juego, salir/reabrir y recoger el resto tras liberar espacio.

Los resultados automáticos concretos y sus límites se registran a continuación; las casillas manuales permanecen pendientes.

Resultado automático verificado (16-10-2026): nueva fixture ejecutada mediante godot-mcp-toolkit: 73 comprobaciones, cero fallos (reports/campus_fixes_result.json). Regresiones aprobadas con resultados finales sin fallos en los logs: campaña, inventario, gameplay, Chef 350 HP, balance (20), lector de guardado, nueva partida, NEXO (111) y organización (9 pisos/596 rutas de nodos). Revisión de carga: 227 scripts/recursos. Los logs son tests/fixes_*.log (ignorados por Git); no se confunde la salida temprana del ejecutable gráfico con éxito: se comprobaron los marcadores de resultado de cada archivo.

FIX visual adicional demostrado con captura MCP: la capa de minijuegos (antes 20) quedaba debajo del HUD de inventario (26) y campaña (40). Ahora es 50; las opciones quedan delante del HUD. Se inspeccionaron Lenguaje y NEXO con renderizado. No altera estadísticas ni mecánicas. Las pruebas humanas completas y otras resoluciones siguen pendientes.
## BOSSES DE ACCIÓN Y PERSONAJES — actualización 16-10-2026

Estado actual: 16 misiones existentes y nueve bosses (seis anteriores + Profesor de Inglés/Piso 5, Lenguaje/Piso 6 y Ética/Piso 7). Los nuevos duelos son de acción, voluntarios al aceptar E/diálogo y con fases al 60%/30%; no son cuestionarios. HP iniciales 450/500/550, TODOS PENDIENTES DE PLAYTEST HUMANO. Director existente conserva 700 HP y añade FIREWALL/ACCESO DENEGADO con avisos; Chef permanece en 350 HP. No se cambian armas, consumibles, enemigos normales, precios ni recompensas anteriores. Los nuevos bosses usan premios académicos/cosméticos y el premio estándar existente de boss.

Computadores pc5/pc6/pc7/pc8 mantienen actividades de Inglés/Lenguaje/Ética/documentos NEXO, game_id 0/2/1/2, campaign_id, flags y señales. Son preparación opcional: ENGLISH_PREPARED retrasa 2 s el siguiente ataque tras Word Rush; LECTURA_PREPARADA reduce duración/ralentización de tinta; REFLEXION_PREVIA amplía elección física de zonas de 6 a 10 s; NEXO_INFORMATION reduce HP de los dos virus del Director de 50 a 40 al invocarlos. Las misiones academico5/seguridad6/acceso7/direccion conservan IDs, recompensas y cadena; los bosses pasan a ser su objetivo de acción. Los estados completados antiguos y desbloqueos se conservan. La puerta acceso7 sigue necesitando TarjetaAcceso. No se marca un computador como resuelto por vencer al boss.

Ética usa zonas físicas A (+20% daño, −15% defensa) y B (+20% defensa, −15% daño), sin opción correcta ni preguntas. Los efectos están limitados a su duelo y se limpian al reset. Todos reutilizan BossDuelController, guardado pre-duelo, checkpoint/BossRetry, recursos/arma/desgaste/quickslots, curación y premio único. No se reconstruyen pisos; ubicación con cápsula/suelo/rayos de continuidad. Ninguna prueba automática certifica el recorrido físico humano.

CharacterVisual amplía el rig y adaptador GLB existentes: torso/ojos más discretos, ropa articulada, camisa/sweater/chaqueta/uniforme ficticio/overol, pantalón/calzado, colores de mochila, audífonos/bolso/insignia/dispositivo. Perfiles estables por ID y guardados; no autoequipa premios al protagonista. AnimationTree importado conserva blend de locomoción y transiciones de salto/caída/aterrizaje; sin clips reales se mantiene fallback procedural. BLOCK/PARRY son soporte visual, no nuevas mecánicas. LookAt, diálogo/cámara y LOD se reutilizan; no se descargan assets.

Detalles y scripts: [BOSSES_SUPERIORES_2_0.md](BOSSES_SUPERIORES_2_0.md). Ropa, estados, workflow GLB y assets faltantes: [PERSONAJES_2_0.md](PERSONAJES_2_0.md). Prueba nueva: tests/UpperCampusCheck.tscn; resultados en reports/upper_campus_result.json. Las pruebas humanas siguen pendientes en PLAYTEST_1_0.md. Las secciones anteriores son historial y no deben usarse como valores actuales cuando difieran de esta actualización.

### Validación de esta ampliación

Godot 4.7.2, mediante godot-mcp-toolkit y ejecutable del editor (sin depender de PATH). Preview de nueve roles: sin fallos. Suite nueva UpperCampusCheck: 104 comprobaciones, sin fallos; nueve muestras transitables por arena, neutralidad/aceptación, fases 60/30, proyectiles/zonas con límites y sin daño anticipado, ventajas, elección física A/B, reintento real, premios únicos, guardado/carga, identidad/ropa, LOD y compatibilidad de etapas completadas.

Regresiones aprobadas y verificadas por marcador final del log: personajes (70), personalización, campaña, inventario, gameplay, Director, Chef 350, Campus Vivo (52), balance (20), nueva partida, NEXO (111), interacciones (60), recogidas parciales/guardado previo (74) y carga de 236 scripts/recursos. Logs tests/upper_*.log; los errores deliberados de fixture de escritura no se confunden con errores de partida. No basta el código de salida del ejecutable gráfico de Windows.

Medición orientativa headless: frame 120 a 5133 ms, 377,69 MiB de memoria estática, 45120 nodos; no es FPS gráfico ni comparación controlada con versiones anteriores. Una muestra estabilizada de la fixture renderizada en Piso 5 dio 19 FPS, 58,14 ms de proceso/2,81 ms de física y ~2132 MiB tras dos cargas de Main. Esa muestra no certifica rendimiento general ni 60 FPS: hace falta profiler/recorrido humano con hardware, resolución/calidad y memoria GPU controlados. La muestra de 1 FPS registrada justo al recargar corresponde al pico de carga, no al combate jugable.

Capturas MCP revisaron variantes de ropa y presentación neutral de Inglés. La apariencia continúa procedural/estilizada; no se afirma realismo fotográfico. Quedan manuales todos los casos añadidos al checklist: caminar/saltar/escaleras/armas, ropa y apariencia al cargar, NPC sentados, cámara, combate real con/sin preparación, rutas/puertas/arenas, muerte/reintento mediante UI, lectura de telegraphs, dificultad y FPS. Ninguna casilla humana se marca PASS.
## OPTIMIZACIÓN + PERSONAJES REALISTAS 3.0 — 16-10-2026

Diagnóstico y datos crudos en PERFORMANCE_PROFILE.md y reports/performance_*.json. En la misma fixture renderizada (dos cargas de Main, cámara frente al profesor de Inglés), el coste demostrado más grande corresponde a sombras: alcance de LuzExterior reducido de 100 m a 40/30/20 m según ALTO/MEDIO/BAJO, manteniendo sombras cercanas. No se certifica 60 FPS en todo el juego ni se atribuye el problema a IA sin medición.

FloorActivityManager clasifica visuales registrados cada 0,35 s: LOD0 completo; LOD1 a intervalos de 0,12 s; LOD2 a 0,5 s; SLEEP sin rig secundario ni AnimationTree importado. Piso actual FULL, vecino REDUCED, más de 18 m verticales SLEEP; distancia también limita. El protagonista, intro/combate, daño/impactos y caída de muerte tienen excepciones. Los enemigos normales de otros pisos omiten percepción/movimiento; no se detienen misiones, horarios, guardado ni interacción. Al volver se recalcula LOD inmediatamente. No había NavigationAgent3D que desactivar.

Geometría procedural idéntica comparte Mesh; materiales permanecen por actor para no propagar flash de daño/personalización. Expresiones y apertura de ojos solo escriben cambios; blink usa Timer pausado por LOD. HUD de objetivo se compone una vez y solo se asigna si cambia. Se conservan el escaneo contextual, las sillas recogibles y sus colisiones.

GLB conserva install_imported_visual(scene, clips, bindings): valida asset/rig/clips/sockets antes de reemplazar, acepta aliases de clips, bindings por rutas o huesos con BoneAttachment3D, HairSocket/HeadAccessorySocket, caché de sockets, blendshapes opcionales y hooks de mirada/parpadeo. Sin clip/modelo válido usa fallback procedural visible. Perfiles internos preparados: student_male/student_female, professor, staff, health, workshop, boss_english, boss_language, boss_ethics, director; no imponen género ni cambian apariencia ya guardada. CHARACTER_HIGH/MEDIUM/LOW se corresponden con ajustes existentes; materiales PBR reales requieren assets adecuados, no se inventan.

MODELO HUMANO EXTERNO NECESARIO. Sin GLB/GLTF/FBX humano encontrado; no se descarga nada. Consultar HUMAN_MODEL_IMPORT.md. Las pruebas sintéticas validan contrato, no realismo humano. Ropa skinned y retargeting se preparan en una escena importada mediante el flujo documentado, sin simulación compleja.

No se agregan bosses/misiones ni se cambia balance: Chef 350, Inglés 450, Lenguaje 500, Ética 550, Director 700 HP; daño, economía y recompensas se conservan. Se mantienen caps existentes de proyectiles/zonas y dos virus. Una protección explícita evita Firewall duplicado. FIX demostrado: una zona sin objetivo vivo ya no conserva su callback indefinidamente; expira y detiene procesamiento antes de liberarse.
# Acabados según fotografías — 19-10-2026

Se unificó el pavimento de los pisos 2–8, conservando los de 1 y −1. Se adaptaron 35 puertas de aulas y sus frentes, detalles industriales de cielo, laboratorio 303, café Paradiso, señalética y bordes de escalera. La entrada incorpora jardín con estatua estilizada sobre pedestal, mobiliario y señalética. Detalles, referencias y checklist humano en ARQUITECTURA_REFERENCIAS_2026_10.md. Se conservan IDs y sistemas de campaña; las puertas mantienen el bloqueo CampaignAccess. La revisión mediante capturas y pruebas automáticas no equivale a playtest humano.

