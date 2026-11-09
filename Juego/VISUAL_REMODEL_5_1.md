# DuocGames 5.1 — correcciones visuales finales

Fecha: 2026-11-05. Proyecto `Juego`, Godot 4.7.2, GL Compatibility. Trabajo sobre el campus existente mediante el puente oficial de **godot-mcp-toolkit** dirigido a este proyecto. Se revisó previamente `VISUAL_REMODEL_5_0.md`; sus 27 correcciones y 72 ajustes de luz se conservan y no se cuentan nuevamente.

## Resultado implementado

Se corrigieron cuatro grupos de problemas confirmados: texto espejado del auditorio, señalización redundante de sus entradas, destinos sin número de piso en siete directorios y cuatro directorios ocultos desde la circulación pública. Los grupos se solapan en algunos objetos: no son cuatro objetos ni cuatro pisos.

| Sector / objeto | Problema confirmado | Cambio aplicado | Estado |
|---|---|---|---|
| Piso 2, `AuditorioPiso2e/EntradasAuditorio/LetreroEntrada-118_5` y `LetreroEntrada-90_5` | Dos rótulos antiguos repetían las mismas entradas que `AuditorioAmpliado`; las capturas desde ambos lados mostraban escritura inversa. | Se ocultan los dos rótulos antiguos, conservando nodos e identificadores. Se desactiva `double_sided`. Ningún acceso se elimina. | PASS VISUAL |
| Piso 2, `AuditorioPiso2e/AuditorioAmpliado/LetreroEntrada-118_5` y `LetreroEntrada-90_5` | Los dos rótulos activos también se veían espejados desde dentro y carecían de un soporte claro. | Una sola cara, texto más contenido, sin contorno y dos placas grafito mate. Conservan las denominaciones ENTRADA 1 y ENTRADA 2. Texto en X=71.26724, Y=16.25, Z=-118.5/-90.5; placa 35 mm detrás del texto. Comprobados frente y reverso. | PASS VISUAL |
| Pisos 2–8, `VestibuloAscensores/PlanoPisos` | Siete directorios indicaban destinos sin asociarlos claramente a su nivel. | Texto uniforme: piso actual; PISO 1: Casino · Coordinación; PISO 2: Biblioteca · Auditorio. No se inventan salas ni otros destinos. `pixel_size=0.003`, sin contorno. Comprobados a 2 y 4 m. | PASS VISUAL |
| Pisos 5–8, `VestibuloAscensores/{CartelPlano,CabeceraPlano,PlanoPisos}` | El directorio del 5 quedaba dentro de la tienda; los del 6–8 quedaban ocultos tras paredes de aulas desde el pasillo. | Reubicación exclusivamente visual hacia el corredor central, normal hacia +X. Panel local (-19.92,2.15,-143), cabecera (-19.81,3.8,-143), texto (-19.835,2.3,-143). En 6–8 queda junto a pared; en 5 se añaden dos patas y base. La puerta de emergencia y sus colisiones se conservan. | PASS VISUAL |

**Duplicados:** dos rótulos redundantes confirmados y desactivados; cero nodos eliminados. **Muebles interactivos reubicados:** cero. **Colisiones modificadas:** cero. **Luces modificadas en 5.1:** cero. **Materiales existentes modificados en 5.1:** cero; las placas de Main reutilizan `MAT_Sign_Backplate_5.tres`. Se añaden cinco mallas visuales simples, con tres recursos BoxMesh compartidos, sin cuerpos ni formas de colisión.

## Protección y archivos

El estado inicial de Git ya contenía numerosas modificaciones, incorporaciones y eliminaciones (533 líneas en el registro inicial); no representa un árbol limpio ni cambios exclusivos de 5.1. Se conserva el punto 5.0 y se crea `../recovery/before_visual_remodel_5_1/`: **842 archivos**, manifiesto SHA-256 y estado Git. Es una copia de fuentes y recursos de texto, no una copia de assets binarios, secretos ni guardados personales. No hubo reset, sobrescritura remota ni push.

La auditoría compara las fuentes con ese punto inicial, no con HEAD: [source_audit.json](reports/visual_5_1/source_audit.json). Solo cambian tres archivos de producción existentes:

- `Main.tscn`: 19 nodos visuales existentes y ocho secciones nuevas, incluyendo tres recursos y cinco mallas.
- `scripts/pisos/piso_2/auditorio_piso_2e.gd`: constructor visual del auditorio.
- `scripts/compartidos/edicion/interiores_referencia_campus.gd`: constructor visual de directorios.

Total: **una escena y dos scripts de producción**. Se añaden aparte una escena de inspección, utilidades de captura, auditoría, comparación y ejecución de regresiones en `tests/`, más este informe y evidencias. No se guarda Main completo desde el editor: sus generadores `@tool` podrían reserializar cambios ajenos. Se aplican parches selectivos y se verifican sus resultados cargando Main. La revisión detectó una orientación candidata incorrecta por el formato matricial de la escena; fue corregida antes de las capturas finales y regresiones. `candidate_orientation_views.json` es evidencia de un candidato rechazado, no del resultado aprobado.

La comparación confirma cero secciones eliminadas, cero cambios de cuerpos/colisiones/actores e identificadores persistentes conservados. Las demás fuentes protegidas permanecen idénticas byte por byte al inicio 5.1. No cambian campaña, misiones, inventario, combate, NPC, bosses, NEXO, recompensas, Supabase, login ni guardado.

## Capturas y método

Evidencia en `reports/visual_5_1/`: `before_views.json` (194 vistas), `before_extra_views.json` (11 adicionales) y `after_views.json` (205 vistas únicas). Los registros contienen posición, objetivo, nombre de captura, observaciones y muestras cuando corresponde. Hay además secuencias de movimiento continuo de la celosía (`before_motion.json`, `after_motion.json`); no se cuentan como sectores adicionales.

Main se instancia en una escena diagnóstica, con persistencia desactivada, actores congelados, FOV real del estudiante de 60° y resolución 1152×648. Se conserva el procesamiento de sectores y LOD de producción. La cámara se traslada a altura de ojos de 2.2 m; **no equivale a caminar todas las rutas**. Las vistas superiores y cercanas complementan esa cámara. Las seis salas de estudio y el patio posterior no ofrecieron una muestra libre para la cápsula en la pequeña cuadrícula probada: sus imágenes son diagnósticas y no certifican transitabilidad. No se movió mobiliario para obtenerlas.

| Comprobación | Antes | Después |
|---|---|---|
| Auditorio, entrada 1 exterior | [Captura](reports/visual_5_1/before_auditorio_AuditorioAmpliado-118_5_front.png) | [Captura](reports/visual_5_1/after_auditorio_AuditorioAmpliado-118_5_front.png) |
| Auditorio, entrada 1 interior | [Captura](reports/visual_5_1/before_auditorio_AuditorioAmpliado-118_5_back.png) | [Captura](reports/visual_5_1/after_auditorio_AuditorioAmpliado-118_5_back.png) |
| Auditorio, entrada 2 exterior | [Captura](reports/visual_5_1/before_auditorio_AuditorioAmpliado-90_5_front.png) | [Captura](reports/visual_5_1/after_auditorio_AuditorioAmpliado-90_5_front.png) |
| Directorio 6 desde pasillo, misma cámara | [Captura](reports/visual_5_1/before_directory_public_6.png) | [Captura](reports/visual_5_1/after_directory_public_6.png) |

## Cobertura adicional por piso

La cobertura es por sectores y ángulos muestreados. Ningún piso se declara completamente inspeccionado objeto por objeto.

| Piso | Vistas adicionales revisadas | Límite / siguiente comprobación |
|---|---|---|
| −1 | Mecánica, soldadura, maquinaria, área central con casilleros, salas técnicas, NEXO; rampa inferior, media y salida. Techos y luminarias, incluida la transición de rampa. | Falta recorrer físicamente todos los rincones detrás de máquinas y casilleros. Un reverso de señal de electromecánica aparece en la toma de retorno del área central: comprobar de cerca su soporte y caras antes de atribuirlo a un duplicado o cambiarlo. |
| 1 | Punto Estudiantil, casino, coordinación, entrada principal y entorno de acceso lateral/posterior. | Algunas vistas de casino y Punto Estudiantil terminan en una pared; no acreditan toda la sala. Falta recorrido continuo de todas las entradas y transiciones de luz. |
| 2 | Dos entradas del auditorio por ambos lados; biblioteca; cada sala de estudio 1–6 con vistas hacia ambos extremos y techo; directorio a 2/4 m. | Las seis salas tienen tomas diagnósticas sobre su zona central, no un recorrido con cápsula entre mesa y asientos. Falta inspección cercana de cada estante y encuentros ocultos. |
| 3 | Laboratorio de Informática dentro de Sala 303, filas de computadores desde dos sentidos, retorno y luminarias superiores. | Las tomas generales no muestran todos los conectores y reversos individuales de monitores/racks. Requieren recorrido manual cercano; no se certifican todos los equipos. |
| 4 | Salud 411/412, profesores/coordinación docente, Cowork, salas centrales 418/417/415. Nuevas tomas cercanas en puerta desde pasillo e interior, más techos y encuentros superiores. | Las aperturas hacia atrio necesitan fotos reales. Las tomas centrales de algunas oficinas miran paredes: cobertura parcial del equipamiento. |
| 5 | Tienda desde ambos lados y retorno, terraza, mobiliario, barandas y directorio desde circulación. | Faltan extremos de cada baranda y recorrido continuo tienda–terraza; no se han certificado todos los anclajes. |
| 6 | Aulas muestreadas, techo/luz interior, zona de encuentro, estudio extremo sur, circulación y directorio. | No se repiten todos los rincones de todas las aulas de 5.0. Falta recorrido completo con cámara controlada por jugador. |
| 7 | Aulas muestreadas, zona de encuentro, estudio extremo sur, circulación y directorio. | Mismo límite; accesos restringidos y puertas requieren comprobación durante una partida real. |
| 8 | Aulas muestreadas, estudio, circulación, Director y computador de misión `CampusCampaign/pc8`, con captura cercana adicional. | No se altera el Director. Falta revisar la presentación durante una misión real y todas las condiciones de acceso. |
| Exterior | Celosía cerca/media/lejos, cinco posiciones laterales y barrido continuo; patio y acceso posterior, fachadas este/oeste, ingreso principal. | Patio parcialmente diagnóstico; faltan todos los bordes desde una ruta caminada. Fachadas y celosía requieren comparación con fotos de detalle antes de simplificar geometría. |

## Iluminación, vidrio y geometría pendientes

Se inspeccionan las luminarias visibles de los sectores anteriores, conservando los ajustes 5.0. Las capturas no demuestran un nuevo defecto localizado que justifique cambiar alcance, energía, sombras o centenares de luces. Esto no certifica ausencia de filtraciones en caras ocultas ni parpadeos en sectores sin muestreo temporal. No se aplican modificaciones de iluminación en bloque.

| Elemento / ubicación | Hallazgo y decisión | Gravedad / automatización / referencia / riesgo |
|---|---|---|
| `Piso4/SalasCentralesPiso4/{418,417,415}` | Aperturas superiores visibles desde interior y pasillo. Se conservaron; los datos geométricos están en `before_central_geometry.json` y `after_central_geometry.json`. No hay prueba de que deban cerrarse. | Media, pendiente de confirmar. No cerrar automáticamente. Necesita foto de pared–techo y atrio de cada sala. Cambiar arquitectura/colisión podría afectar accesos y luz. |
| `Piso4/FilaFrontalPiso4/CoworkDocente` | Reflejo visible pero permite reconocer el interior en la toma de retorno. Se conserva el acabado 5.0; no se demuestra brillo que obligue a otro ajuste. | Baja. No requiere corrección automática ahora. Foto solo para mayor fidelidad. Sin cambios de gameplay. |
| `Exterior/EntradaReferenciaDuoc/CelosiaMetalica/VarillasCelosia` | Patrón fino susceptible a aliasing a distancia. Se ensaya movimiento continuo de 3.5 s y FXAA temporal. La prueba no demuestra una solución visual suficiente para asumir el costo global; AA original restaurado y geometría intacta. | Media, pendiente de evaluación humana en movimiento/resolución objetivo. Foto de trama real antes de definir LOD o sustitución a distancia. Riesgo visual y de rendimiento, no de lógica. |
| Transiciones de luz y muebles detrás de obstáculos, según tabla de cobertura | No hay evidencia suficiente para mover objetos, eliminar equipos ni cambiar luces. Mantener como cobertura pendiente, no como defecto confirmado. | Gravedad indeterminada hasta inspección. Recorrido manual; fotos solo si se cuestiona la construcción real. Un eventual movimiento interactivo exige preservar world_id, señales y persistencia. |

No se descargaron assets ni se alteraron UV, texturas, vidrio, paredes, techos o materiales de suelos en 5.1. Se conservaron las referencias existentes; la evidencia decisiva de estas correcciones son las capturas actuales y la geometría de Main. Las fotografías existentes no resuelven las aperturas específicas de las tres salas. No se inventa señalización institucional.

## Rendimiento antes/después

[Datos completos](reports/visual_5_1/performance_comparison.json). Doce cámaras y objetivos idénticos, misma resolución/FOV/editor en escena de inspección, semilla y congelación de actores; calentamiento de 1.5 s y 90 intervalos reales `frame_post_draw` por vista. No se compara con 5.0, que usaba otro FOV. Los valores siguientes resumen las medianas por vista; no son un benchmark de campaña caminada ni una medición GPU independiente.

| Muestra | Antes: ms / FPS motor / draw calls / primitivas | Después: ms / FPS motor / draw calls / primitivas |
|---|---|---|
| Resumen de 12 vistas | 39.779 / 24 / 15697.5 / 827159 | 38.084 / 25 / 15690.5 / 826844 |
| Piso 2, biblioteca | 45.692 / 20 / 15579 / 1069720 | 40.915 / 22.5 / 15572 / 1069304 |
| Piso 2, estudio 1 | 33.865 / 29 / 11260 / 800398 | 32.451 / 28 / 11256 / 800206 |
| Piso 3, laboratorio | 15.771 / 65 / 5112 / 305882 | 13.401 / 67 / 5108 / 305690 |
| Exterior lejano | 79.462 / 12 / 31128 / 1962336 | 77.190 / 12 / 31120 / 1961438 |

Hay 502 nodos de luz habilitados antes y después; **no significa 502 luces aplicadas por la GPU en cada imagen**. No se instrumentó la lista efectiva por cámara. “Primitivas” es el contador nativo, no una captura independiente de triángulos GPU. Se conservan LOD, SLEEP y optimizaciones existentes. Algunas vistas mejoran y otras empeoran; cachés, temporizadores y carga del sistema impiden atribuir el cambio de FPS a los carteles. No se afirma una mejora general.

La prueba temporal de FXAA en la misma vista lejana pasó de 79.462 ms/12 FPS a 87.973 ms/11 FPS, con 31128 draw calls y 1962336 primitivas en ambos casos. Se rechazó como cambio global; `screen_space_aa=0` antes y después. El exterior sigue siendo el sector más costoso de estas muestras y merece optimización medida en un trabajo separado.

## Pruebas y límites de aprobación

Resultados automáticos de la ejecución final: **26/26 suites PASS AUTOMÁTICO, cero FAIL**, en [regressions.json](reports/visual_5_1/regressions.json), con logs individuales. La ejecución se realiza sobre instancias aisladas; no utiliza cuentas reales ni sobrescribe guardados personales.

| Pruebas ejecutadas | Resultado y alcance |
|---|---|
| `gameplay_regression`, `inventory_regression`, `campaign_regression` | PASS AUTOMÁTICO; fixtures existentes de juego, inventario y campaña. |
| `organizacion_pisos`, `placement_visual_check`, `library_layout_check`, `resource_reference_check` | PASS AUTOMÁTICO; nueve niveles/596 rutas de organización, 92 elementos de colocación, seis salas/21 rutas de biblioteca y 43 escenas referenciadas. |
| `piso8_recorridos` en pisos 6, 7 y 8 | PASS AUTOMÁTICO; 27 recorridos por piso. |
| `salidas_emergencia` | PASS AUTOMÁTICO; nueve pisos, 18 recorridos, cero fallos. El marcador antiguo no contiene RESULT: el primer clasificador no lo reconoció. Se corrigió el clasificador y se validó el JSON explícito del mismo log, código de salida y ausencia de errores; no se cambió el test ni el juego. |
| `BasementAccessCheck`, `ElevatorBasementCheck`, `LibraryAccessCheck`, `AuditorioAccessCheck` | PASS AUTOMÁTICO; 20 rutas de subterráneo, tres de ascensor y accesos físicos de biblioteca/auditorio. |
| `guardado_lectura`, `cloud_save_check`, `persistent_queue_v4`, `remember_login_check` | PASS AUTOMÁTICO; lectura local, 21 checks de cloud fixture, 22 de cola y 15 de recordar sesión. Base remota y cuentas reales no probadas. |
| `education_integration`, `UserRolesCheck`, `AcademicBossesCheck`, `director_informatica_boss`, `nexo_final` | PASS AUTOMÁTICO; 18 checks educativos, 63 de roles en memoria/SQL estático, 320 de bosses académicos, fixture del Director y 111 de NEXO. RLS remoto no probado. |
| `placement_stairs_visual_check`, `rendered_gameplay_check` | PASS AUTOMÁTICO con renderizado; tres estados de cámara/escalera y 14 checks de juego/interfaz, con capturas. Sin guardados personales. |

Los dos scripts visuales modificados pasan `script_check` mediante Godot MCP, sin diagnósticos. Main se carga en la inspección renderizada y en las regresiones de acceso/organización; no se sustituye la experiencia de inicio de sesión real por esta carga de prueba.

**PASS VISUAL:** dos entradas activas legibles desde fuera, reversos sin texto espejado; dos rótulos redundantes ocultos; siete directorios con piso/destino; cuatro directorios visibles desde el pasillo; placas y soporte del piso 5 apoyados visualmente. Se revisaron las hojas de contacto posteriores y las capturas cercanas citadas. Esto no aprueba automáticamente todas las habitaciones del campus.

**PASS AUTOMÁTICO:** las 26 suites anteriores, comprobación de scripts y auditoría final de fuentes, identificadores y ausencia de cambios de colisiones/actores.

**FAIL:** ninguno en la evaluación final. El falso negativo del marcador de salidas se conserva explicado en `validation_note` del resultado.

**PENDIENTE MANUAL:** caminar todos los sectores y ángulos indicados; iluminación temporal fuera del barrido de celosía; legibilidad en otras resoluciones/configuraciones; interacción humana de puertas, ascensores y escaleras en partida completa; campaña y recogibles con un guardado real; sesión real Supabase/login/roles/sincronización; presentación del Director, bosses y NEXO durante juego real. Las pruebas offline de estos sistemas validan sus fixtures, no una conexión real ni toda la experiencia interactiva.

**Riesgos restantes:** cobertura parcial, moiré dependiente de resolución/movimiento, arquitectura de atrio sin referencia concluyente y alto costo del exterior. Ninguna apertura se cerró y ningún interactivo se reubicó para ocultar estos límites.
