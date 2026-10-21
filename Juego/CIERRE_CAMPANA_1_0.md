# CIERRE DE CAMPAÑA 1.0

Implementación: 16-10-2026. **NEXO: PENDIENTE DE BALANCE HUMANO.** No se modificaron estadísticas de armas, enemigos, bosses anteriores, consumibles, XP, precios ni recompensas anteriores. El nuevo boss reutiliza la recompensa común existente de 75 créditos / 150 XP; la misión final no añade otra recompensa económica. No se crean Boss Rush, NG+, Rival ni boss secreto ausentes.

## Las nueve sillas

No faltaban IDs: cada una ya tenía `silla:` seguido de su ruta única y persistente. Se conservaron IDs, mobiliario, colisiones, alcance de 2,2 m, estadísticas y comportamiento.

El validador anterior ensayaba cuatro candidatos a solo 0,9 m del origen del mueble. En los ocho sillones/sillas de BoxesAyuda, la cápsula se solapaba con Asiento/Respaldo; en la dirección del escritorio el rayo encontraba el tablero a 1,44 m, no un suelo válido. En Puesto19 de Biblioteca aparecían tablero a 13,238 m, Asiento y/o muro frontal. Era una muestra insuficiente de posiciones, no una prueba de inaccesibilidad.

`tests/chair_access_probe.gd` ahora busca radios 0,9/1,3/1,7/2 m y 16 ángulos, con suelo, cápsula completa, alcance real y raycast. No ignora las colisiones del propio mueble al buscar dónde pararse. Los ocho de Punto pasan desde 1,3 m lateralmente; Puesto19 pasa diagonalmente desde 1,3 m. La nueva suite recoge realmente los nueve y comprueba que no se dupliquen. La auditoría general pasa 779/779 aproximaciones locales; esto no demuestra navegación desde spawn.

Evidencia con bloqueadores y puntos seguros: `reports/closure_chairs.json`. El reporte histórico `reports/balance_1_0_data.json` conserva los nueve casos originales como fixture de regresión. No se convirtió ningún mueble fijo en recogible.

## Archivo y progresión

Se conserva `postgame`, sus recompensas y su estado guardado por compatibilidad. Ahora representa el archivo intermedio. Tras completarlo se activa **nexo_final**, una nueva principal con dos requisitos:

1. `door:nexo_core`: «Encuentra el núcleo de NEXO».
2. `boss:nexo`: «Desactiva NEXO».

Al encontrar el archivo se muestra información final de Proyecto NEXO cuando se libera el diálogo/duelo actual. Queda guardada como `notes.proyecto_nexo_final` y se puede releer en Registro. No se acepta ni inicia combate automáticamente. El mapa muestra una zona aproximada, la bahía industrial este del −1. El marcador lleva al acceso, no revela terminales ni secretos.

El acceso comprueba archivo completado, Director derrotado, CredencialDirector y lectura de la revelación. E autoriza el núcleo y registra `door:nexo_core`, sin mover físicamente al jugador. El núcleo puede verse apagado antes: tocarlo o entrar en su zona no activa IA. En partidas antiguas se conserva la misión del archivo completada; se añade la final pendiente. Si falta la credencial pese a la derrota guardada del Director y al archivo completado, se recupera únicamente esa clave mediante el helper de recompensa existente. Los cosméticos ya desbloqueados no se revocan.

## Arena y nodos

Ubicación: **bahía abierta ya construida en el este de PisoMenos1**, centro aproximado `(48, −12,018, −100)`, sobre el suelo original a −12,0584. La cuadrícula de 81 puntos pasó antes de añadir el núcleo; después el propio collider del núcleo ocupa su centro. No se tocaron losas, muros, escaleras, accesos ni sectores de talleres.

`campus_campaign.gd` incorpora en runtime `Main/PisoMenos1/NexoFinalArea`, siguiendo el patrón procedural existente. Contiene NEXO/BossDuelController, acceso, tres terminales, dos racks/pantallas decorativos, iluminación local, avisos y contorno de arena. No hay paredes invisibles. El radio operativo es 10,5 m; fuera de él se cancelan ataques y se conserva el retorno voluntario de arena existente.

Scripts del encuentro: `scripts/pisos/piso_menos_1/nexo_*.gd`. Datos editables: **`resources/live/nexo_final.tres`**, con exports de `nexo_config.gd`. No depende de GLB, imágenes, música o animaciones externas.

## NEXO y sus fases

Vida inicial: **1200 HP**, aproximadamente 1,71 veces los 700 HP actuales del Director. Se eligió un incremento moderado para un encuentro de tres fases con desplazamiento e interacción, no una duración garantizada. El actor toma su vida de Resource; no utiliza un literal de HP para resolver combate. **PENDIENTE DE VALIDACIÓN HUMANA.**

| Fase | Umbral | Mecánicas |
|---|---|---|
| Sistema activo | 100–70% | Paquete corrupto telegrafiado, pulso de radio 3,5 m y zona de error temporal |
| Aprendizaje | 70–35% | Selección ponderada añade patrón de dos paquetes de Redes e interferencia simplificada de suelo; no invoca Bugs inexistentes |
| Sistema crítico | ≤35% | Tres enlaces activos, iluminación local naranja y Protocolo de Borrado; desactivar enlaces expone el núcleo |

Valores de primera versión, todos pendientes de balance humano:

| Parámetro | Valor |
|---|---|
| Daño paquete / pulso / zona | 18 / 14 / 10 |
| Zona | radio 2,1 m; aviso 1,2 s; activa 3 s; daño como máximo cada 1 s |
| Aviso de ataques normales | 1,1 s; la zona añade su aviso propio al aparecer |
| Separación entre selecciones por fase | 3,2 / 2,8 / 2,5 s + variación 0–0,4 s, además del windup |
| Cooldown paquete / pulso / zona | 4 / 7 / 9 s |
| Cooldown patrón doble / interferencia / borrado | 8 / 10 / 13 s |
| Amenazas | máximo 3 proyectiles y 1 zona, más un único aviso en preparación |
| Protocolo de Borrado | aviso 2 s; radio 6,5 m; daño 30; zona exterior segura dentro de arena |
| Protección por enlace | 18%, total 54% con tres; se reduce al desactivarlos |

No se repite inmediatamente el último ataque; los cooldowns se comprueban también al intentar iniciarlo. No se usan todas las mecánicas a la vez. El aviso de zona precede al daño; proyectiles usan el barrido y las colisiones existentes. Pulsos requieren estar dentro del radio y tener línea de visión. No hay muerte instantánea diseñada.

## Terminales y objetos

`TerminalNexo_A`, `_B` y `_C` se activan solamente en fase 3. E a 2,4 m y con línea de visión desactiva cada enlace una sola vez. Protección: 54% → 36% → 18% → 0%. Mientras queden enlaces, la vida no baja de 1: no se puede saltar la interacción mediante un golpe grande. Después: «NÚCLEO EXPUESTO». El estado de enlaces es temporal; reintentar reinicia los tres.

**RouterPortatil real:** ayuda pasiva al comenzar el duelo si está en la mochila, sin consumirlo. Cada enlace protege 12% en lugar de 18%; protección total 36%. Sigue siendo necesario desactivar los tres. Descripción actualizada sin alterar su obtención.

**USBInfectado real:** usa el receptor existente; daño base 40 × factor NEXO 1,5 = 60 antes de protección, stun 2 s y cancelación del ataque en preparación. Se consume por el flujo de uso existente solo si surte efecto. El factor 2 y stun del Director no se modificaron. `DepuradorPortatil` e `InsigniaIntegridad` no existen en esta versión; no se inventan. Se puede derrotar NEXO sin Router ni USB.

## Diálogo, checkpoint y reintento

El núcleo ofrece «Desactivar NEXO» / «Retirarse», con mundo pausado durante la elección. Retirarse deja al boss neutral. Aceptar reutiliza intro `NEXO / NÚCLEO DEL SISTEMA`, cámara existente con comprobación de obstáculos, tono procedural y luces locales. No mueve al jugador.

El acceso fija un checkpoint cercano. La aceptación usa **BossRetry.capture**, con vida, inventario, UID de arma equipada, durabilidad, quickslots, estamina y copia coherente de campaña. No se crea otro guardado/retry. Al morir se ofrece «NEXO · REINTENTAR» / «REINTENTAR NEXO» y las opciones anteriores. Reintentar restaura recursos previos y reinicia fases, enlaces y amenazas. Recompensas siguen protegidas por ledger. Elegir checkpoint abandona snapshot.

Cerrar durante duelo conserva en disco el estado previo; cargar deja al núcleo neutral, no continúa una pelea parcialmente guardada. Las terminales y proyectiles no se guardan a mitad del encuentro.

## Victoria y postgame

La derrota detiene IA, limpia proyectiles/zonas/avisos, apaga enlaces y contrae el núcleo a una forma verde estable; no desaparece instantáneamente. Se marca `campaign_completed`, `bosses.nexo` y la misión final; se guarda antes de la presentación. La secuencia breve muestra «NEXO DESACTIVADO / SISTEMAS RESTAURADOS».

CampusState pasa a RESTORED mediante la victoria real, ya no al completar únicamente el archivo. Pantallas/luces reutilizan su restauración y los eventos NEXO quedan excluidos por el director existente. Técnico y Director tienen comentarios breves. No hay Rival implementado al que añadir diálogo. Desbloqueos NEXO existentes se conservan sin cambiar ropa elegida.

Primera victoria permite ver o saltar créditos. Luego se muestran estadísticas de registros existentes: tiempo activo, nivel, principales/secundarias, bosses/Redes opcional, enemigos derrotados, secretos, tarjetas, cuatro apuntes y pickups `Arma_` encontrados. «Armas de escenario» se limita a las 51 fuentes registradas; no inventa un contador histórico de todas las armas manipuladas.

El porcentaje es un cálculo transparente del registro: 10 principales + 6 secundarias + 6 bosses + 20 tarjetas + 4 apuntes + 5 secretos + 51 pickups de arma = 102 entradas. No incluye 779 sillas, eventos raros ni actividades repetibles. No sustituye un sistema anterior de finales múltiples: no se encontró uno. Créditos/opciones pueden revisarse otra vez en el núcleo o acceso restaurado.

Opciones: continuar explorando, ver créditos y menú existente. Boss Rush/NG+ no se muestran porque no existen. Los sistemas opcionales ya presentes siguen activos. NEXO queda derrotado en campaña normal; no se crea rematch ni boss secreto NEXO_0.

Persisten `campaign_completed`, derrota, misión, acceso y lectura del archivo, notas, elección de créditos, cosméticos, inventario, quickslots/durabilidad, estadísticas y progreso anterior. RESTORED se deriva de esa victoria. Se mantienen `save_version=2` y campos opcionales con defaults compatibles; no se borran ni reinician partidas anteriores.

## Validación y límites

Suite nueva `tests/nexo_final.gd`: **111 comprobaciones** aprobadas, usando una fixture de progreso para probar el cierre, no una partida humana desde cero. Incluye recogidas reales, elección/retirada, fase 2/3, límites/cooldowns, protección, enlaces, objeto opcional, borrado evitable, muerte/retry exacto, recompensa única, JSON antes/después y destrucción/carga real de escena postgame.

Regresiones aprobadas: balance (20), campus (52), Personajes 2.0 (59), inventario, gameplay, campaña, horario (27), celular (31), interacciones (60), Chef, Director, Nueva partida, lector de guardado, Redes (38). Revisión: **226 scripts/recursos** sin fallos. QA de referencias: cero errores; puertas/rutas físicas siguen pendientes de recorrido.

Se ejecutó fixture renderizada con godot-mcp-toolkit: se vieron núcleo, diálogo y botones, HUD de combate, zonas y fase 3 con enlaces activos. No se completó una victoria humana ni un benchmark de FPS. Los errores de autenticación inicial y de sintaxis de una expresión del toolkit se resolvieron al conectar/usar `Vector3(0,0,0)`; no fueron errores del juego. Warnings del lector JSON corresponden a archivos deliberadamente corruptos de su test.

Pendientes humanos: acceso caminando desde archivo, preparación/checkpoint, cámara/visibilidad con HUD, telegraphs a 1080p/1440p, seguridad de rutas a terminales, tiempo real de pelea, dificultad sin opcionales, estrategia con Router/USB, reintentos consecutivos, victoria/créditos/postgame y cerrar/reabrir aplicación real. Lista completa en PLAYTEST_1_0.md.
