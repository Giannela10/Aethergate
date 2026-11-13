# DuocGames 7.1 — Auditoría final de pisos 3–8

13-11-2026. Se aplicaron tres correcciones reales de alcance acotado y se ejecutó Main en Godot 4.7.2 mediante MCP. La revisión fue secuencial: 3/4, 5/6, 7/8, seguida de regresiones y comprobaciones cruzadas. Estado general: PARCIAL; no se certifica aún la campaña completa hasta NEXO.

## Cambios aplicados

| Piso | Corrección real | Verificación |
|---|---|---|
| 3 | 24 bases y 24 soportes para monitores suspendidos de TeachingLab | Capturas equivalentes antes/después; 24 soportes medidos; escena fresca con 4 pantallas y 4 pares de soportes PASS |
| 4 | Sin remodelación especulativa | Docentes, preguntas, sectores 415/417/418 y Cowork inspeccionados; vanos pendientes de fotos |
| 5 | 22 colisiones de paneles frontales de terraza | Rayos 34/34, controlador real detenido dentro, instalación idempotente y vínculo persistido en Main PASS |
| 6 | Textos opcionales de pc5/pc6/pc7 conforme a su piso real | Sólo texto; IDs, opcionalidad y cantidades conservados |
| 7 | Sin cambios físicos adicionales | Puerta reconoce tarjeta ganada con Documentos; no concede automáticamente piso 8 |
| 8 | Sin cambio de balance ni simulación | Tres tareas del Director completadas por opciones/botones reales; inicio digital y reinicio sin premio PASS |

Producto modificado: Main.tscn, teaching_lab_v4.gd, quest_manager.gd y nuevo terrace_guard_collision_7_1.gd. El resto de archivos nuevos son pruebas, informes o evidencia. No se hizo commit ni push.

## Protección y recuperación

Proyecto confirmado: C:/Users/despacho2-cd/OneDrive - SOCIEDAD COMERCIAL AQUAMUNDO LTDA/Escritorio/Proyecto de titulo/Aethergate/Juego/project.godot. Main actual contiene Piso3…Piso8 y sus sistemas existentes. Git se revisó antes de modificar. El punto de recuperación conserva HEAD, estado, diff, Main y copias de los cambios locales de 7.0 en reports/final_7_1/run_20261113_145917/recovery/. No se descartaron cambios, ni se usó reset/clean/force/merge. Comparación SHA-256 de 33 archivos previos y comparación por bloques de Main: PASS; sólo se añadió el recurso y su propiedad de script en Frente. Ver change_scope_v2.json. Recuperación excluida de Git, conservada en disco.

## Resultados y cobertura

| Piso | PASS | FAIL vigentes | BLOCKED | NOT RUN | Informe |
|---|---:|---:|---:|---:|---|
| 3 | 52 | 0 | 4 | 1 | [Detalle](FLOOR_3_FINAL_AUDIT.md) |
| 4 | 47 | 0 | 2 | 1 | [Detalle](FLOOR_4_FINAL_AUDIT.md) |
| 5 | 15 | 0 | 1 | 0 | [Detalle](FLOOR_5_FINAL_AUDIT.md) |
| 6 | 42 | 0 | 1 | 1 | [Detalle](FLOOR_6_FINAL_AUDIT.md) |
| 7 | 46 | 0 | 1 | 1 | [Detalle](FLOOR_7_FINAL_AUDIT.md) |
| 8 | 39 | 0 | 2 | 2 | [Detalle](FLOOR_8_FINAL_AUDIT.md) |

PASS significa ejecutada y aprobada dentro del alcance escrito en el JSON; no significa aprobación completa del piso. FAIL es ejecutada y fallida; BLOCKED depende de autorización/servidor/herramienta; NOT RUN no fue ejecutada. Los resultados finales toman la última ejecución por identificador. Se conservaron fallos iniciales de diagnóstico, incluso la sonda original de la cerca, antes de corregirlos.

Escaleras 3↔4, 4↔5, 5↔6, 6↔7 y 7↔8: recorridas con entrada de movimiento real y altura de llegada comprobada. Cámara normal activa durante esos recorridos. Ascensores: comprobado rechazo de destinos pendientes; viajes autorizados BLOCKED, no se simularon desbloqueos. Muestreos de cápsula en habitaciones son pruebas de ubicación y no recorridos completos. Sólo el recorrido de pasillo del piso 5 obtuvo inicio seguro; los demás intentos quedan NOT RUN.

Documentos: aceptación, entrega y repetición sin doble recompensa; TarjetaAcceso ganada y usada en controlador de puerta del 7. Coordinación reconoció visitas reales de los docentes requeridos. Director: conexión, configuración y antivirus completados; inicio de simulación con humano mentor y entidad digital separados; reinicio sin dar victoria, credencial ni NEXO. No se completó el combate integrador.

## Educación y bloqueo remoto importante

150 preguntas locales válidas, IDs/enunciados únicos y mazos completos de once perfiles: PASS; explicaciones, rechazo de reenvío de respuesta y verified=false comprobados. Tres preguntas por interfaz real de cada mentor auditado, incluido Director. Práctica local no otorgó mentor_passes. Director local combina las áreas configuradas; ver subjects en education_regression.json.

Consulta de sólo lectura actual: Auth settings 200; learning_activities, learning_attempts y learning_access devuelven 404/PGRST205. Otras tablas protegidas devolvieron 401/42501; esto no demuestra que estén vacías. No había sesión autenticada de estudiante. No se modificaron RLS, credenciales ni datos remotos. Las misiones publicadas y la evaluación integradora verificada quedan BLOCKED. La condición de BossDuelController depende de que el perfil esté en published_mentors; el inicio local sin catálogo publicado no certifica autorización de una evaluación remota. No se inyectó ese catálogo ni una nota válida.

Por tanto, **la continuidad legítima completa desde piso 3, pasando por Director, credencial y archivo/NEXO no está aprobada**. Debe resolverse/verificarse la disponibilidad remota V4 y ejecutar una partida autorizada completa. No se eliminó ningún requisito para ocultar este bloqueo. El pendiente estructural de la rampa exterior del subterráneo documentado en 7.0 permanece fuera del alcance de 7.1.

## Regresión, rendimiento y herramientas

Cinco procesos de prueba terminaron sin timeout ni SCRIPT ERROR, con marcadores de resultado sin fallos: inventory_regression, gameplay_regression, guardado_lectura, main_character_regression_6 y final_education_regression_7_1 (16 comprobaciones). No se afirma ejecución de otras suites por existir en tests/. Pruebas frescas de soporte de monitor, colisión de cerca y propiedad guardada de Main incluidas. Scripts de producto modificados: script_check válido sin diagnósticos. Guardado de campaña en seis archivos res://reports exclusivos: escritura y lectura semántica PASS; no equivale a recuperar todos los sistemas tras una campaña completa.

Se midieron 20 cuadros por vista, con posiciones y datos crudos; consultar metrics_summary.json y *_views.json. No se afirma mejora de FPS: las muestras son breves, Main entero cargado, NPC congelados fuera de pruebas específicas y algunos procesos de regresión corrieron simultáneamente en la fase final. Los 48 meshes pequeños de soportes son el único aumento visual deliberado. No se añadieron luces, sombras ni huesos. Los rayos y cuerpos de terraza no modifican visuales.

Incidentes de herramienta: el conector nativo apuntaba al directorio padre; se usó un puente del servidor MCP oficial con ámbito Juego. Los procesos de regresión renovaron el registro de runtime; se seleccionó explícitamente el puerto del juego. Un auxiliar buscó Director en el diccionario incorrecto y pausó el depurador; se corrigió, reanudó y repitió con PASS. Otra repetición tuvo texto de botón con codificación incorrecta; la última usa prefijo ASCII y fuente UTF-8. Son incidencias de prueba conservadas, no defectos de campaña corregidos. Lectura de log por MCP produjo LOG_BUSY; se conserva extracto local sanitizado. No se ocultó un error de producto mediante un cambio de balance.

## Pendientes antes de aprobar la demostración completa

- Fotos de vanos superiores 415/417/418; no se cerraron sin referencia.
- Recorrido manual íntegro de cada habitación/puerta y esquinas de terraza; capturas cardinales y sondas no cubren todo.
- Viajes de ascensor autorizados, campaña principal completa, recompensas de cada encuentro y guardado/carga posterior a credencial del Director.
- Todos los NPC de fondo, sus estados de locomoción, accesorios y objetos recogibles individuales; no se sustituyeron modelos humanos.
- Rendimiento sostenido durante combate y accesibilidad con otras resoluciones/teclado.
- Evaluaciones publicadas y progreso remoto con sesión autorizada; ningún resultado local debe contarse como remoto.

## Evidencia

[Galería](reports/final_7_1/run_20261113_145917/index.html) · [Métricas](reports/final_7_1/run_20261113_145917/metrics_summary.json) · [Ámbito de cambios](reports/final_7_1/run_20261113_145917/change_scope_v2.json) · [Regresiones](reports/final_7_1/run_20261113_145917/regressions71.json) · [Educación](reports/final_7_1/run_20261113_145917/education_regression.json) · [Supabase sólo lectura](reports/final_7_1/run_20261113_145917/remote_readonly.json).

Los informes por piso enlazan capturas y resultados individuales. No se sobrescribió evidencia 7.0. Imágenes de diagnóstico inválidas se conservan en bruto y se excluyeron de la galería principal. No se grabó video en 7.1; hay capturas durante recorridos y trazas temporales de posición.

## Verificación final desde disco

Se detuvo la fixture acumulada y se abrió una instancia fresca de Main desde sus archivos actuales, con persistencia personal y nube desactivadas. Seis comprobaciones PASS: Main listo, aislamiento de guardados, 24 bases de monitores, 22 cuerpos de cerca, los tres textos opcionales UTF-8 y campaña sin Director/NEXO completados artificialmente. [Resultados](reports/final_7_1/run_20261113_145917/fresh_Main_checks_v2.json). La primera comprobación contaba por nombre y sólo encontró seis bases porque Godot renombra hermanos repetidos. Se corrigió el test para identificar la geometría de cada base y se repitió desde una nueva apertura; el FAIL inicial se conserva en fresh_Main_checks.json.

Comparación adicional de fuentes con recuperación: eliminando sólo el bloque nuevo de textos, QuestManager es idéntico al anterior; eliminando sólo comentarios y los dos soportes, TeachingLab es idéntico. [Integridad](reports/final_7_1/run_20261113_145917/source_integrity.json).

La primera comparación de recuperación marcó cinco .gd.uid distintos porque Godot reimportó los scripts dentro de la copia y regeneró sus UID. Sus fuentes siguieron idénticas; los cinco UID del proyecto activo se verificaron contra HEAD y no cambiaron. change_scope_v2.json documenta ese método. No usar los UID regenerados de la carpeta de recuperación para restaurar: mantener los UID activos/HEAD. El primer change_scope.json conserva el diagnóstico FAIL inicial, no el resultado final.
