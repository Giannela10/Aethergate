# DuocGames: contenido y recorrido actual

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
| 9 | Archivos del subterráneo | Encontrar el archivo secreto del subterráneo |

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

- **Cuatro jefes:** Encargado Punto Estudiantil, Chef Supremo, Bibliotecaria y Director de Informática. Tres duelos de combate y uno de preguntas. Antes de atacar hay que hablar y aceptar.
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
5. **Final presentado al jugador.** Dar un cierre narrativo al archivo del subterráneo con pantalla de victoria, resumen de estadísticas y créditos; no confundir completar el objetivo actual con una cinemática final ya hecha.
6. **Sonido.** Los sistemas tienen espacios preparados, pero no se encontraron archivos de música o efectos de audio del juego. Añadir ambiente, pasos, golpes y avisos.
7. **Equilibrio de recursos.** Con 779 sillas y 12 centros de curación, comprobar si el combate resulta demasiado fácil antes de seguir aumentando cantidades.
8. **Mejor navegación de enemigos.** Su persecución puede atascarse entre muebles; falta una navegación completa por zonas.
9. **Eventos y jefe opcional del subterráneo.** Son posibilidades de ampliación; no están completos como contenido actual.
10. **Prueba final y exportación.** Recorrer una partida completa, comprobar rendimiento en el equipo objetivo y validar un ejecutable distribuible.

Las ideas de esta última sección son propuestas, no funciones añadidas durante el conteo.
