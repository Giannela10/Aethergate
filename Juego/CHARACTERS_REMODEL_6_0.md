# DuocGames 6.0 — remodelación de personajes

Fecha: 2026-11-05. Implementación directa en `Juego`, Godot 4.7.2 / Compatibility. Se utilizó el puente oficial de **godot-mcp-toolkit** dirigido a este proyecto para abrir las escenas, ejecutar las inspecciones y comprobar scripts/logs. Las imágenes son capturas del motor, no propuestas de diseño.

## Resultado y protección

Se remodeló la base compartida `Humanoid`/`StudentVisual` que utilizan protagonista, estudiantes, funcionarios, guardias y mentores. El resultado sigue siendo **procedural y estilizado**, con más anatomía, detalle y variedad; no se presenta como un humano fotorrealista ni como un GLB riggeado.

Se revisaron `PERSONAJES_2_0.md`, `PERSONALIZACION.md`, `PERFORMANCE_PROFILE.md`, los contratos del adaptador GLB, AnimationTree, sockets y LOD/SLEEP. Antes de editar se comprobó Git y se creó `../recovery/before_characters_remodel_6_0/`: **851 archivos verificados por SHA-256**, manifiesto y estado Git. Se conservan las modificaciones previas y los puntos 5.0/5.1. La copia contiene fuentes y recursos de texto; excluye secretos, guardados personales y assets binarios. No hubo push ni eliminación de assets originales.

La auditoría final compara contra ese inicio, no contra un HEAD limpio: [source_audit.json](reports/characters_6_0/source_audit.json). Cambian **siete scripts existentes y se añade uno de producción**. Main y las escenas existentes permanecen idénticos al inicio. Se conservan colisiones, estadísticas, campaña, inventario, economía, recompensas, desbloqueos, Supabase, cuentas y roles. También permanecen idénticos los métodos funcionales de locomoción/golpes, equipar/desequipar y el método principal `StudentVisual.animate`; no se alteraron los tiempos de daño o esquiva.

## Sistemas reutilizados

| Sistema | Tratamiento |
|---|---|
| Rig procedural | Mismos pivotes, longitudes de extremidades y origen en pies. Cambian las superficies dibujadas. |
| CharacterVisual / StudentVisual | Continúa como representación del Player y numerosos NPC; no se crea otro jugador. |
| Perfiles y guardado | Mismo `CharacterAppearance.normalize` y flujo de guardado existente. Campos cosméticos aditivos; sin cambio de versión o migración del guardado funcional. |
| Personalización | Mismo SubViewport 3D, rotación, zoom, confirmar/cancelar y restricciones cosméticas. Se añade selector de rostro y se amplían opciones al final de catálogos. |
| Mirada / diálogo | Se conserva LookAtController, límites y restauración de cámara. No se cambia el texto ni las misiones. |
| AnimationTree / GLB | Adaptador existente conservado, con validación de esqueleto, clips y sockets. El AnimationTree de reserva no se anuncia como animaciones humanas reales. |
| LOD/SLEEP | Mismos intervalos y reglas; dedos con límite visual de 14 m. Geometría base compartida y materiales independientes por actor para que el flash de uno no afecte a los demás. |

## Protagonista, anatomía y rostro

- Cabeza con contorno de mentón, mandíbula, mejillas y cráneo; sustituye la combinación anterior de óvalos. Cuatro variantes seleccionables: equilibrado, redondeado, alargado y mandíbula definida.
- Torso con transición cintura–pecho–hombros; brazos y piernas con secciones de volumen graduado. Se mantienen longitudes y articulaciones del controlador.
- Palmas y pulgares conservados; cuatro dedos sencillos por mano en una superficie agrupada. No se añade un esqueleto de dedos ni agarre físico independiente.
- Ojos más contenidos, puente y punta de nariz, relieve inferior del ojo y boca reposicionada para quedar fuera de la nueva superficie facial. Orejas y cabello siguen la cabeza.
- Cabello con casquete adaptado al contorno, en lugar de una semiesfera que podía sobresalir demasiado. Se mantienen los seis índices anteriores; largo, laterales, medio y rizado incorporan piezas sobre la cabeza/parte posterior.
- Continúan seis tonos de piel y seis colores de cabello. Las variantes de rostro no cambian la cápsula de colisión.

Las expresiones existentes NEUTRAL, HAPPY, SURPRISED y WORRIED se conservan sobre el nuevo rostro. Se añaden **FOCUSED, PAIN y VICTORY** al contrato visual, con cambios discretos de cejas/boca. Se conservan también ANGRY, TIRED, RELIEVED y ALERT. Las nuevas expresiones son estados visuales disponibles y comprobados: no se añadieron eventos de combate/campaña para dispararlas automáticamente. La victoria existente sigue usando RELIEVED donde el juego ya lo hacía.

## Vestuario, materiales y accesorios

Se eliminan del constructor del estudiante las solapas, franjas, placa y tirantes fijos que aparecían sobre cualquier ropa. El adaptador construye ahora detalles según la prenda elegida, conservando todas las opciones anteriores.

| Vestuario | Implementación |
|---|---|
| Polera / polerón | Silueta base nueva, dobladillo, mangas coherentes; capucha posterior y cordones cuando corresponde. |
| Camisa / sweater / chaqueta | Cuellos/solapas, puños, bolsillos y botones; chaqueta con superficie exterior contorneada. |
| Clínico ficticio | Uniformes existentes de Enfermería/Odontología con mangas, bolsillos, calzado y credencial; sin logos nuevos. |
| Taller | Overol con detalles, botas/casco existentes y color de guante sobre manos/dedos cuando se usa el overol. Solo cosmético. |
| Pantalones | Se conservan casual, jeans, formal y trabajo; se añade deportivo con franja lateral. |
| Calzado | Se mantienen zapatillas, zapatos y botas; cordones de zapatillas y acabados diferenciados. |
| Mochila | Color del cuerpo y bolsillo coordinado; tirantes solo cuando hay mochila. Socket y balanceo existentes conservados. |
| Lentes | Marcos abiertos alrededor del ojo, en lugar de bloques opacos; posición ajustada a la cara nueva. |
| Cabeza / chef | Se añade gorro liso como opción posterior a las existentes. El mentor Chef recibe ropa clara, delantal y gorro de cocina mediante su perfil visual, sin modificar el actor o sus reglas. |

La piel usa roughness alto y menor especular, evitando el aspecto plástico. Tela, lana, denim y calzado reciben acabados distintos; se añade una textura procedural compartida de roughness de **128×128**, sin descarga ni mapas de normales inventados. No se comparten materiales mutables entre actores. Las piezas de ropa compatibles se agrupan por **padre articulado, material y módulo**, sin fusionar articulaciones diferentes. Esto reduce superficies sin perder movimiento de codos/rodillas.

No se cambia WeaponSocket, ItemSocket, BackpackSocket, HairSocket o HeadAccessorySocket, sus bindings ni la lógica del inventario. Las piezas cosméticas nuevas no tienen colisión. La prueba de repetición comprueba que cambiar de apariencia ocho veces no acumula mallas.

## Profesores, funcionarios y NPC

La variedad de piel, rostro, cabello, color, ancho y vestimenta se resuelve de forma determinista. Los perfiles nuevos incluyen rostro derivado del ID; los antiguos sin ese campo resuelven una variante estable desde su identidad visual/actor. No se vuelve a sortear la apariencia en cada frame ni se reemplazan perfiles guardados completos. Los campos antiguos y sus índices conservan significado.

| Personajes revisados | Identidad conservada / detalle visual |
|---|---|
| Bases de Datos y Algoritmos | Perfil docente diferenciado; tablet y gesto de explicación visual. |
| Redes | Perfil informático, lentes/accesorios y tablet visual; mentor educativo conservado. |
| Enfermería y Odontología | Uniformes clínicos ficticios diferenciados, credencial y prop de explicación. |
| Coordinador de Profesores | Ropa formal y carpeta. |
| Inglés | Ropa docente y audífonos existentes, tablet/gesto de explicación. |
| Ética y Comunicación/Lenguaje | Ropa docente diferenciada y libro. Se conserva el ID existente de Lenguaje; no se crea otro profesor. |
| Matemáticas | Perfil docente con tablet. |
| Director | Traje/credencial reconocibles, carpeta y rig actualizado; no se modifica su lógica ni su ubicación. |
| Punto Estudiantil / Chef / Biblioteca | Identidad de función conservada; Chef con uniforme claro/delantal/gorro. Biblioteca mantiene sus lentes/libro y actor existente. |
| Estudiantes, auxiliares, funcionarios, técnico, monitor y guardias | Misma conducta/rutas, combinaciones estables y superficies compartidas nuevas. Los uniformes particulares de guardias se conservan. |

El censo de la fixture final de Main registra **57 instancias visuales**, 35 visibles en ese estado. No equivalen a 57 NPC únicos: incluyen representaciones antiguas ocultas y modelos de mentores que comparten actor funcional. Se capturaron 35 vistas de instancias visibles, incluida una toma del visual antiguo de Punto Estudiantil cuyo encuadre resulta vacío/no válido; esa toma no se considera aprobación visual. Se revisan las otras vistas y los 13 mentores identificados en el censo, además de los perfiles del estudio. No se certifican como inspeccionados visualmente los 22 modelos ocultos por progresión/estado. [Censo con rutas y perfiles](reports/characters_6_0/campus_census.json).

## Animación: cambios y reutilización

Se añaden gestos procedurales **GREET, EXPLAIN y CELEBRATE** al adaptador social. EXPLAIN combina tablet en una mano con gesto suave de la otra; los mentores docentes pueden usarlo desde su perfil. Se reutilizan TYPE, WRITE, READ, PHONE, EAT, REPAIR e INSPECT. Los props se ocultan en estados incompatibles mediante las reglas existentes.

Quieto, caminar, correr, saltar, caer, aterrizar, agacharse, atacar, esquivar, daño, muerte, recoger, puertas, computadores, conversación, asiento/levantarse y teléfono **reutilizan las poses y transiciones existentes**. No se añadieron clips capturados de movimiento ni se reescribió la locomoción para aparentar una animación nueva. Las mallas contorneadas, dedos y ropa siguen esos mismos pivotes. Los nuevos gestos de saludo/celebración quedan disponibles como acciones visuales; no se añade un sistema de navegación o agenda social ni nuevos eventos de recompensa.

Continúan pendientes animaciones humanas de alta calidad, flexión independiente de dedos, foot IK y una comprobación exhaustiva del deslizamiento del pie. No se afirma haber resuelto todos los casos de intersección en cada frame de todos los gestos.

## Modelos externos y licencia

La búsqueda local no encontró archivos GLB, GLTF, FBX u OBJ humanos para validar/integrar. El Skeleton3D vacío de reserva no se cuenta como un humano skinned.

Se consultaron fuentes primarias de Kenney: [Animated Characters 3](https://kenney-assets.itch.io/animated-characters-3), con licencia CC0 y tres animaciones declaradas, y [Animated Characters Protagonists](https://kenney.nl/assets/animated-characters-protagonists), también CC0. Se intentó la descarga del ZIP enlazado por la segunda página, primero en sandbox y después con autorización de red. El segundo intento produjo **18.368 bytes de HTML**, no un ZIP válido; la validación del directorio del archivo comprimido falló. No se introdujo ese contenido en el proyecto ni se afirmó una importación exitosa.

**Modelos humanos externos incorporados: cero.** Quedan pendientes un asset riggeado descargable y verificable, sus huesos/skin, clips compatibles, escala/orientación y sockets. El adaptador GLB original queda preparado y sus pruebas de bindings, rechazo seguro y fallback siguen ejecutándose.

## Rendimiento comparable

Datos: [performance_comparison.json](reports/characters_6_0/performance_comparison.json), junto a `before_performance.json` y `after_performance.json`. Estudio renderizado aislado, misma cámara, FOV 45°, resolución de las capturas, semilla 600, luz y configuración; calentamiento de 1.5 s y 90 intervalos reales `frame_post_draw` por población. Los NPC están dentro del encuadre y usan animación procedural; no es un benchmark de Main con todas las sombras del campus.

| Población | FPS antes / después | ms por frame antes / después | Draw calls antes / después | Primitivas antes / después |
|---|---|---|---|---|
| Protagonista | 75 / 75 | 13.330 / 13.328 | 61 / 53 | 18144 / 20012 |
| Protagonista + 5 NPC | 75 / 75 | 13.334 / 13.330 | 422 / 375 | 140820 / 137660 |
| Protagonista + 15 NPC | 75 / 75 | 13.334 / 13.333 | 1107 / 994 | 370512 / 360032 |
| Protagonista + 30 NPC | 75 / 75 | 13.332 / 13.332 | 2139 / 1939 | 710640 / 691652 |

Son medianas de las muestras. Se observa un techo de 75 FPS: **no se afirma una mejora de FPS ni margen de GPU ilimitado**. Se reducen draw calls en estas poblaciones; el protagonista aislado aumenta primitivas por el detalle nuevo. Primitivas es el contador nativo, no un recuento independiente de triángulos GPU. Se conservan LOD/SLEEP y la reducción de animación/sombras a distancia. La regresión `performance_regression` también valida registros históricos del proyecto: sus cifras de 65/39.5 FPS no son mediciones de esta actualización y no se usan para atribuirle una mejora.

## Evidencia visual

| Vista | Antes | Después |
|---|---|---|
| Protagonista frontal | [Captura](reports/characters_6_0/before_front.png) | [Captura](reports/characters_6_0/after_front.png) |
| Rostro cercano | [Captura](reports/characters_6_0/before_face.png) | [Captura](reports/characters_6_0/after_face.png) |
| Espalda / mochila | [Captura](reports/characters_6_0/before_back.png) | [Captura](reports/characters_6_0/after_back.png) |
| Costado izquierdo | [Captura](reports/characters_6_0/before_left.png) | [Captura](reports/characters_6_0/after_left.png) |
| Costado derecho | [Captura](reports/characters_6_0/before_right.png) | [Captura](reports/characters_6_0/after_right.png) |
| 30 NPC | [Captura](reports/characters_6_0/before_population_30.png) | [Captura](reports/characters_6_0/after_population_30.png) |

Hay además primeros planos de las cuatro variantes faciales, siete expresiones, siete prendas superiores, perfiles por función, locomoción y gestos sociales en `reports/characters_6_0/after_*.png`; vistas reales de Main en `campus_*.png`. Las hojas de contacto se generan con `tests/characters_contacts_6_0.ps1`. Los planos de estudio no se presentan como rutas caminadas por el campus.

## Pruebas y pendientes

La batería principal registra **32 suites PASS AUTOMÁTICO, cero FAIL**: [regressions.json](reports/characters_6_0/regressions.json). Incluye las 26 regresiones usadas al cerrar 5.1, más la nueva de personajes 6.0, `personajes2` (70 checks), `characters3` (23), personalización, nueva partida y rendimiento histórico. Las últimas modificaciones de uniforme reciben una comprobación adicional separada en `regressions_visual_recheck.json`.

La prueba nueva comprueba normalización/serialización y lectura de apariencia desde un archivo aislado, cambio repetido sin acumulación, identidad del socket, ausencia de colisiones cosméticas, un solo evento funcional de golpe, estados faciales, perfiles deterministas y SLEEP/reactivación. El archivo temporal de apariencia se elimina; no se usa una partida personal.

Las regresiones existentes incluyen inventario, campaña, guardado, roles offline, mentores/bosses académicos, Director, NEXO, nueve niveles, accesos, ascensores y escaleras. Las pruebas renderizadas comprueban movimiento real por input y vistas de interfaz. Las pruebas offline de Supabase/roles no certifican login o RLS reales.

**PASS VISUAL:** anatomía y vestuario en las vistas de estudio; frente, espalda y ambos lados; variantes faciales/cabello; los retratos útiles del campus y gestos capturados. La inspección de estos fotogramas no equivale a probar todas las combinaciones durante toda una partida.

**PENDIENTE MANUAL / ASSET:** modelos humanos y clips externos válidos; todas las armas y objetos recogibles en todos los gestos; flexión de dedos, pie/terreno irregular y ausencia de clipping en todos los frames; todas las combinaciones de ropa, gorros/cabello y resoluciones; modelos ocultos por estado/progresión; guardado/carga con una cuenta real y sesión remota. No se modificó el servicio de guardado para realizar estas pruebas.

**Problemas conocidos:** apariencia todavía estilizada, detalle facial sencillo y sin blendshapes; dedos rígidos unidos a la mano; variaciones sutiles de prendas del mismo color; solapamientos que puedan aparecer en combinaciones no muestreadas; benchmark con techo de FPS y sin carga completa de campus. El informe distingue estas limitaciones de las correcciones realmente implementadas.

## Archivos de producción

`scripts/juego/humanoid.gd`, `student_visual.gd`, `procedural_appearance_adapter.gd`, `character_appearance.gd`, `character_visual_presets.gd`, `character_activity_visual.gd` y `scripts/campaign/appearance_menu.gd`; nuevo `scripts/juego/character_surface_6.gd`.

Las escenas nuevas `tests/CharactersRemodel60.tscn` y `tests/CharactersCampus60.tscn`, sus scripts y las utilidades de auditoría/regresiones/capturas son herramientas de prueba. No se añaden a la campaña ni sustituyen Main.
