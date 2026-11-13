# Auditoría final 7.0 — pisos −1, 1 y 2

Fecha: 13-11-2026. Se trabajó sobre el proyecto actual `Juego/project.godot` mediante Godot MCP Toolkit, su puente oficial local y herramientas de archivos. **Auditoría por sectores y pruebas específicas; no inspección exhaustiva de cada instancia. No aprobación global para defensa.**

Evidencia: [run_20261113_103850](reports/final_7_0/run_20261113_103850/). El [informe del protagonista](CHARACTER_ANIMATION_FINAL_7_0.md) documenta la prioridad de animaciones.

## Protección y límites

Antes de editar se guardaron HEAD, estado Git, parche binario de cambios locales, archivo ZIP de los archivos versionados y copia de los archivos sin seguimiento existentes. El ZIP tiene checksum en `recovery_archive_sha256.json`; queda local y excluido de Git para no incorporar un respaldo de aproximadamente 548 MB. Las copias individuales de cada archivo editado están en la misma carpeta de evidencia.

Cambios previos preservados: `DUOCGAMES_4_0_REPORT.md`, eliminación pendiente de `tests/placement_stairs_visual_check.gd.uid` e importaciones de capturas anteriores. No hubo reset, clean destructivo, eliminación de escenas, push, modificación de credenciales ni publicación remota.

Los fixtures usan campaña `persist=false`, `test_mode`, inventario no persistente y credencial persistente desactivada antes de montar el campus. El único guardado intencional de prueba usa archivos `res://reports/final_7_0/.../isolated_campaign*.json`, nunca una partida personal. Se cargó el campus completo por sus dependencias; no se remodelaron ni recorrieron los pisos 3–8. Del piso 3 solo se comprobó su desbloqueo como dependencia de biblioteca.

## Registro de defectos y decisiones

| ID | Piso / sector / nodo o script | Evidencia | Acción, riesgo y resultado |
|---|---|---|---|
| AN-01 | Protagonista / `human_student_6_2.gd` | Matrices de reposo y secuencias antes/después | Corregido retargeting completo de extremidades, solo en el camino del protagonista. Riesgo acotado a representación; pruebas de movimiento y sockets ejecutadas. |
| AN-02 | Protagonista / `character_footwear_6_3.gd` | Anclaje de ambos pies en código y muestras de suelas | Corregida separación avance/apoyo, plano de rodilla y penetración tras desplazar pelvis. Medición final por pie sin penetraciones en las muestras registradas. |
| AN-03 | Ciclo de vida / `humanoid.gd` | Error al reanudar `_install_human63` tras liberar la instancia | Corregido con callbacks de señal; suite repetida sin ese error. |
| P1-01 | Punto Estudiantil / `interaction_controller.gd` | `survey_checks.json` fallaba; prueba posterior identifica `BossAyudaEstudiantil/CuerpoBoss` como obstáculo | Corregido reconocimiento del cuerpo hijo asociado a la simulación. Escáner y diálogo pasan. Una pared sólida temporal sigue bloqueando la interacción. No se ignoraron paredes ni se alteró el boss. |
| M1-01 | Rampa / `LosaInclinada`, malla y `ColisionEstatica/Forma` | Ruta completa se detuvo en `(24.37,-12.05818,-115.9638)` contra la propia losa | Corregido empalme inferior: longitud real de pendiente y centro de la losa para alinear su cara superior. Misma malla/nodo y colisión conservados. El ensayo aislado con esos valores supera la entrada y sube hasta el siguiente obstáculo. |
| M1-02 | Salida superior de rampa / `Piso1/LosasYAccesos/LosaRecortada_46_1/Cuerpo` | `ramp_diagnostic.json`: atasco cerca de `(24.37,-3.199525,-150.4284)` | **PENDIENTE CRÍTICO**. La losa superior impide continuar de pie. Requiere resolver hueco de forjado, continuidad de circulación del piso 1 y protección contra caídas. No se eliminó la colisión ni se abrió un hueco sin una solución estructural completa. |

La lectura inicial de los componentes de la matriz sugirió pendiente invertida. La medición de las bases efectivas en Godot la descartó: **no se cambió la orientación**. Asimismo, la primera prueba parcial de rampa había encontrado la losa del piso 1 mediante un raycast desde arriba; se conserva como prueba inválida de la rampa, no como acceso aprobado.

## Piso −1

Se inventariaron los nodos del nivel y se capturaron cuatro direcciones por sector de Mecánica Automotriz, Soldadura/Estructuras Metálicas, Maquinaria Industrial, Área Central de Estudiantes, Negocio/Cafetería, Pasillo de Salas Técnicas y Rampa. Se observaron talleres, vehículos, herramientas decorativas, casilleros, mesas centrales, local, tuberías y señalización; no se redistribuyeron. Las siete zonas tienen muestras de colocación con espacio para la cápsula. Las capturas no prueban que cada herramienta o mueble tenga una interacción.

Se conservó la distribución y no se sustituyó por una organización nueva. La correspondencia exacta con fotografías originales y cada orientación al salir de cada ascensor sigue **PENDIENTE**: las vistas actuales no bastan para certificarla.

**Corrección real:** losa y colisión de la rampa pasan de longitud 47,54 a aproximadamente 49,06409; su centro baja de −6,029193 a −6,246011. El generador `reconstruccion_visual_2026.gd` usa hipotenusa y compensación del espesor para conservar esa corrección al reconstruir. No se cambiaron paredes, talleres, luces, máquinas o contenidos NEXO.

**Accesos:** escalera central −1 → 1 recorrida completamente, llegada a y≈0; rechazo del destino −1 por ascensor con campaña nueva verificado. El viaje autorizado al −1 con todos los requisitos finales y las rutas por cada puerta técnica no se aprobaron. **La salida completa de rampa falla por M1-02.**

**NEXO:** área real en `Main/PisoMenos1/NexoFinalArea`, con puntos de colocación válidos. Se verificó que archivo, credencial y puerta del núcleo siguen siendo requisitos; llamar al acceso sin ellos no lo desbloquea. No se alteraron balance, estadísticas, checkpoints ni estados finales. Archivo autorizado, núcleo y encuentro final jugado: **PENDIENTES**.

## Piso 1

Se inspeccionaron mediante cámara y muestras de cápsula Punto Estudiantil, Casino, Interior de Coordinación, Pasillo Derecho/Capilla, Vestíbulo de Ascensores y pasillos. Se conservaron muebles, sillas recogibles, iluminación y arquitectura al no demostrarse un defecto adicional seguro de corregir. No se afirma revisión individual de cada asiento o computador.

**Corrección real P1-01:** el propio cuerpo hijo del encargado ya no bloquea hablar con su mentor. `targeted_checks.json` identifica el obstáculo original; `refined/extra_checks.json` comprueba tanto el acceso como que una pared ajena continúa bloqueando la línea de interacción.

**Primer día:** se comprobaron estado inicial activo, selección por escáner y diálogo del encargado tras la corrección, primer objeto, selección e inicio de `pc_intro`, señal de finalización del minijuego, actualización de objetivos, recompensa, activación de biblioteca y desbloqueo de piso 2. Se refrescaron misiones repetidamente sin repetir recompensas. La finalización del computador por señal y las victorias de Punto/Chef se inyectaron **solo en el fixture**, para probar integración; no equivalen a completar sus desafíos jugando normalmente.

**Casino:** ambos encuentros COMBAT conservan mentor visible y entidad digital de simulación. Se comprobó inicio y resolución de recompensa en el fixture; no se modificaron estadísticas ni representación. Victoria de principio a fin con entradas normales de combate: **PENDIENTE**.

**NPC:** inventario de 15 visuales humanos visibles de los tres niveles en `refined/npc_selected_floors.json`, con perfiles, escalas y huesos. Punto y Chef se probaron funcionalmente; el resto no tiene aprobación individual de todos sus diálogos, comportamiento y contacto con suelo.

## Piso 2

Se capturaron biblioteca, impresiones, vestíbulo y las **seis salas de estudio por separado**, con mesa, sillas, pizarra, luz y accesos visibles. Se comprobaron muestras de cápsula en cada sala. No se detectó en esas vistas un defecto de mobiliario o iluminación que justificara una edición; no se activaron sombras masivas ni se eliminaron objetos.

El muestreo automático del nodo global Auditorio produjo inicialmente un AABB que incluye geometría heredada de otras alturas. Ese muestreo se considera **NO CONCLUYENTE**, no un bloqueo real. Se añadieron recorridos con el jugador por las dos entradas y capturas interiores y desde el escenario; ambos accesos recorridos pasaron. Los pasillos de acabado estrechos tampoco se aprobaron mediante su AABB; no se confundió el espacio de una moldura con un pasillo transitable.

**Carteles:** los dos nodos solicitados en `EntradasAuditorio` existen y están ocultos; se conservaron. Sus equivalentes activos en `AuditorioAmpliado` son de una cara, legibles por el frente y no muestran letras invertidas por detrás. Se capturaron ambas caras de ambos grupos. No se eliminó ningún duplicado ni se atribuyó a esta tarea una corrección que ya estaba aplicada. Carteles modificados: **0**.

**Biblioteca y misión:** se recogieron los tres objetos reales `LibroBiblioteca` manteniendo sus `world_id`; se abrió el diálogo, se inició el duelo QUIZ de la bibliotecaria, se validaron pregunta y tres alternativas, se emitieron las señales de los botones correctos y se verificó retroalimentación en cinco preguntas. Finalización, registro del boss, misión completada, recompensa única y desbloqueo del piso 3 pasaron. La mecánica se conservó como duelo de preguntas, sin convertirla en combate físico.

Las preguntas son del banco local integrado. **No se publicó ni creó contenido remoto**, ni se consideró una respuesta local como aprobación de todas las actividades académicas. Supabase, evaluaciones publicadas y cuentas reales: **NO PROBADOS**.

## Matriz transversal A–T

“Muestreado” implica alcance parcial con inventario/capturas, no aprobación de cada instancia.

| Categoría | Piso −1 | Piso 1 | Piso 2 |
|---|---|---|---|
| A Arquitectura | Talleres muestreados; salida rampa bloqueada | Sectores muestreados; losa sobre rampa pendiente | Biblioteca/salas e interior auditorio muestreados |
| B Texturas | Vistas actuales; comparación fotográfica pendiente | Vistas actuales, sin ediciones | Vistas actuales, sin ediciones |
| C Materiales | Sin cambio; revisión por superficie pendiente | Sin cambio | Sin cambio |
| D Iluminación | Inventario y vistas; sin nuevas sombras | Casino/pasillos observados | Cada sala observada; sin modificación masiva |
| E Señalización | Inventario, lectura completa pendiente | Inventario; lectura de todos los rótulos pendiente | Cuatro nodos de auditorio y ambas caras comprobados |
| F Mobiliario | Muestras; no cada herramienta | Muestras; sillas/interacciones preservadas | Seis salas y biblioteca; no cada libro decorativo |
| G Colisiones | Empalme rampa corregido; techo bloquea salida | Escalera recorrida; obstáculo superior rampa conservado | Entradas auditorio y pasillo biblioteca recorridos |
| H Accesos | Bloqueos de campaña conservados | Inicio y destinos de ascensor probados | Acceso de biblioteca y desbloqueo siguiente probados |
| I Personajes | Inventario visible parcial | Punto/Chef funcionales en fixture; resto parcial | Bibliotecaria funcional; estudiantes parcial |
| J Animaciones | Protagonista corregido; no cada NPC | Movimiento y simulaciones probados | Locomoción/quiz observados; resto parcial |
| K Interacciones | NEXO bloqueado correctamente; herramientas pendientes | Escáner, objeto, computador, diálogos probados | Tres libros y botones de preguntas probados |
| L Misiones | No se saltó la campaña final | Primer día por integración aislada | Biblioteca por recogida y respuestas reales |
| M Preguntas | Actividades remotas pendientes | Publicadas/Supabase pendientes | Banco local y retroalimentación probados |
| N Guardado | Sistemas conservados | Escritor/lector/migración local de fixture probados | Misiones/recompensas/IDs recuperados semánticamente |
| O Ascensores | Rechazo por requisitos comprobado; viaje final pendiente | Viajes 1→2 y regreso comprobados | Viajes 2→1 y regreso comprobados |
| P Escaleras | −1→1 central aprobada en ruta | 1→2 central aprobada | 2→1 central aprobada |
| Q Rendimiento | Muestras por vista; sin promesa de FPS | Ídem | Ídem |
| R Motor | Bloqueo físico registrado; sin colisión eliminada | Error de ciclo de vida corregido | Sin error nuevo atribuido a estos cambios en pruebas finales |
| S Accesibilidad UI | No auditoría completa | Texto/contexto observados; contraste/tamaños pendientes | Preguntas, botones y feedback observados; auditoría completa pendiente |
| T Persistencia | Identificadores existentes conservados | Objetos/recompensas sin duplicación en pruebas | Tres libros y estados guardados/recuperados |

## Rendimiento y errores

Se guardaron FPS y draw calls de las escenas aisladas antes/después, y muestras de tiempo de fotograma, FPS, draw calls y primitivas por cada vista del campus. **No se afirma mejora de FPS**: son muestras breves y las pruebas posteriores incorporan cámaras e instrumentación adicionales. “Primitivas” no se presenta como un conteo exacto de triángulos. Las luces visibles en árbol no equivalen a luces efectivamente renderizadas.

No se añadieron luces, sombras, huesos ni mobiliario. El apoyo sigue evaluando el sistema existente; no se asegura coste idéntico sin un benchmark dedicado. Las pruebas finales de inventario, gameplay, lectura de guardados y personaje terminaron sin fallos declarados y sin el error de instancia liberada que se corrigió. Las advertencias de JSON inválido son casos intencionales de `guardado_lectura`.

La consola del editor mostró además diagnósticos de `addons/godot_ai/utils/server_lifecycle.gd` y un material de entrada. No se atribuyen a esta corrección ni se borraron para ocultarlos; su reproducción y resolución quedan pendientes. Los registros de los fixtures fallidos también se conservan separados de las ejecuciones válidas.

## Pendientes que impiden una aprobación global

1. **Crítico: salida superior de rampa M1-02.** Resolver abertura y protección del piso 1, volver a caminar en ambos sentidos y revisar cámara/colisiones. No se considera aprobada la rampa completa.
2. Campaña NEXO completa con una partida de prueba que cumpla realmente todos sus requisitos; ascensor autorizado hacia −1 y checkpoints del final.
3. Terminar Punto/Chef con combate normal; completar el computador inicial jugando su minijuego sin inyectar resultado.
4. Recorrido individual de todas las puertas, pasillos, casilleros, talleres, muebles e interactivos; no se inspeccionó cada instancia.
5. Revisión fotográfica estructural y de escala real, accesibilidad integral y benchmark prolongado comparable.
6. Evaluaciones publicadas, guardado remoto, paneles por rol y Supabase con banco/cuentas de pruebas autorizados; sin datos de producción.

La lectura fresca de `Main.tscn` mediante Godot confirma los valores persistidos de malla y colisión en `ramp_persisted_resource_check.json`. El control de diferencias en `final_summary.json` confirma que solo cambiaron tres bloques de la escena: la transformación de la losa de rampa y sus dos recursos de tamaño. Los demás nodos y recursos de la escena permanecen iguales a la copia previa.

Galería de evidencia: [evidence_gallery_verified.html](reports/final_7_0/run_20261113_103850/evidence_gallery_verified.html). Las suites repetidas con la cadencia final quedan en `cadence_regression/`.

No se modificaron QuestManager, requisitos, recompensas, contenidos remotos, credenciales ni campaña final. No se remodelaron los pisos 3–8. No se hizo push.
