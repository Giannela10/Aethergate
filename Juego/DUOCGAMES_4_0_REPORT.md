# DUOCGAMES 4.0 — Informe de implementación

Actualizado: 2026-11-02T18:19:41.877Z

**Entrega parcial funcional; no es una versión final ni una demo Windows validada.**

## 1. Qué existía antes

Campus de nueve niveles; movimiento en tercera persona; 15 jefes/desafíos; 20 misiones; inventario, combate, ascensores y NEXO; paneles de roles y banco de selección múltiple; guardado Supabase con reintentos solo en memoria. La auditoría leyó RESUMEN_JUEGO.md, AGENTS.md, documentos de estado, código y migraciones.

## 2. Protección y modificaciones

Se creó un punto de recuperación de 788 archivos fuente/escenas/documentos, verificado con SHA-256: VÁLIDO. No contiene configuración privada, sesiones ni partidas; no es una copia de assets binarios. Se preservaron los assets originales. Las migraciones 001–007 siguen idénticas al respaldo: true. No se hicieron reset, checkout, commits, cambios de cuentas ni escrituras administrativas remotas. Los cambios previos del usuario se conservaron.

## 3. Qué se agregó

Capa aditiva DuocGames4 sobre CampusCampaign; cola de disco; servicios, vistas y panel de actividades; mentores y entidades digitales; TeachingLab.tscn; misiones educativas, Bugs y escolta; civiles con rutinas; historia; progreso, credenciales, accesibilidad, audio y pruebas. La geometría original de Main.tscn no se reconstruye: las ampliaciones se instancian al iniciar.

## 4. Funcionalidades completas y límites

Las partes locales con evidencia automática se detallan abajo. NO se declara completada toda la especificación 4.0 ni una plataforma lista para producción. SQL preparado no equivale a servidor validado; datos de entrenamiento simulados no equivalen a una evaluación real. La rúbrica de la sección 29 explicita qué sigue parcial.

## 5. Sistema educativo

Se conserva el banco anterior. El nuevo banco admite selección múltiple, verdadero/falso, ordenar, identificar, zona física, secuencia, relacionar, práctica basada en secuencia y reflexión. Soluciones y contenido están separados. Orden/relaciones/prácticas usan permutaciones validadas en servidor. Las zonas 3D se colocan en puntos de arena transitables: el movimiento elige una alternativa y el RPC determina la corrección. Hay botones accesibles y cancelación; se conserva la práctica física anterior de Inglés. Una reflexión no se marca como incorrecta ni bloquea acceso. Falta validar todo el ciclo con un servidor y profesores reales.

## 6. Profesores

Los docentes conservan IDs, victorias, misiones y recompensas. El mentor visible es un civil fuera del grupo enemy; el actor técnico del duelo representa una entidad digital. La ropa usa perfiles procedurales de profesor, salud o director. Cuando existe una actividad publicada para un mentor, el flujo solicita su evaluación antes de iniciar la simulación. Se evita imponer una pregunta inexistente a campañas anteriores. Falta validar ese ciclo con docentes y sesiones reales.

## 7. Simulaciones

Se reutilizan controladores, fases, proyectiles, objetivos, esquiva y reinicio. Se muestran INICIAR SIMULACIÓN y AHORA NO; Redes conserva su especialización y opcionalidad. Los cuerpos de combate muestran robots digitales, y las victorias se presentan como simulaciones completadas. NEXO mantiene su combate final. El Chef mantiene 350 HP; no se alteraron indiscriminadamente HP ni daño de armas.

## 8. Salas del piso 3

301 Programación: nueva huella sur. 302 Bases de Datos: norte oeste. 303 Redes: sala existente conservada. 304-B Ciberseguridad: nueva, para respetar el 304 ya señalizado. 305 Hardware y Soporte; 306 Laboratorio General; TÉCNICA Servidores: nuevas huellas norte. Se midieron primero 27 candidatos sur y 168 norte. Los nuevos recintos incluyen muros con puerta, mesas, computadores, monitores, teclados, sillas, pizarra, proyector y señalización; los temas técnicos añaden racks, servidores, switch, cableado y placas de práctica. Cada laboratorio tiene interacción educativa. Las puertas nuevas se recorrieron con cápsula física. Falta recorrer todas las conexiones desde los pasillos con un usuario humano.

## 9. Nuevas misiones

Se agregan seis secundarias sin modificar las diez principales: Estudiante encerrado (306), Laboratorio sin conexión, Programa infectado, Emergencia simulada, Presentación interrumpida (auditorio) y Taller descontrolado (−1). El rescate tiene puerta, conversación/panel, actividad remota, apertura, salida de seguridad, escolta física y recompensa única. Programa infectado incluye tres Bugs golpeables y etapa académica. Las otras misiones usan inspección y actividades por piso, con puesta en escena todavía básica. El recurso editable resources/education/incidents_v4.tres contiene pasos y solicitudes: objetos perdidos, PCs dañados, puertas bloqueadas, ayuda estudiantil, revisión de equipos y encargos docentes. El tablero junto a Punto Estudiantil rota su orden con el horario ficticio y reutiliza IDs/recompensas existentes; no duplica premios ni modifica la cadena principal.

## 10. Progreso académico

El celular incorpora Mi progreso: asignaturas, respuestas, correctas/incorrectas, prácticas locales, respuestas validadas, reflexiones, actividades completadas, misiones, credenciales y accesos pendientes, con barra gráfica. Los campos se conservan en el snapshot de la misma cuenta. Son métricas del juego, no calificaciones oficiales.

## 11. Supabase y preguntas

008 prepara tablas con RLS, soluciones privadas, tickets por usuario/contexto, selección por piso/mentor y menor repetición, corrección del servidor y acceso/XP educativo únicos por usuario y piso. Los pases antiguos del piso 3 se recuperan de intentos correctos del servidor, no del JSON del cliente. Imágenes: bucket privado de 5 MiB, PNG/JPEG/WebP, subida bajo UUID propio e inmutabilidad; se cargan con sesión autorizada. No se aplicaron las migraciones. La comprobación real de conexión falló por DNS del host configurado, por lo que no se certifica login, SMTP, OAuth, RLS ni el banco remoto nuevo.

## 12. Panel docente

Se agregaron actividades con selector de tipo/mentor, unidad, dificultad, alternativas y órdenes editables sin código, explicación, publicación, imágenes, búsqueda y vista previa. El servidor vuelve a validar asignación y propiedad. 009 agrega estadísticas por pregunta/asignatura, actividad diaria de los últimos 30 días y publicaciones/cambios, sin identidades de estudiantes. Modo jugar admite prácticas de profesores en sus asignaturas autorizadas y de administradores; el servidor distingue esas prácticas y las excluye de las estadísticas estudiantiles. Faltan despliegue, validación RLS real y pruebas con docentes. Los docentes configuran espera e intentos diarios; los desafíos de acceso obligatorios exigen intentos ilimitados en el servidor para evitar bloqueos por agotamiento.

## 13. Panel administrador

Se mantienen administración por UUID, protección del último administrador, asignaciones y RPC existentes. Se agregan acceso directo a estudiantes, auditoría de los últimos 100 cambios, creación/edición de asignaturas, actividades publicadas y estadísticas. 009 registra cambios de actividad/asignatura; no permite trasladar asignaturas con contenido a otro piso. Ningún usuario real fue modificado.

## 14. Personajes

Se reutilizaron ropa modular y adaptador GLB; los mentores usan vestimenta según rol y las simulaciones modelos digitales propios. No se importó un humano real nuevo: no hay GLB riggeado autorizado disponible para validar Skeleton3D, Skin y todos los clips solicitados. Continúa el fallback procedural; no se afirma realismo fotográfico ni nuevas animaciones humanas inexistentes.

## 15. NPC

Se añadieron 7 civiles en rutas comprobadas, con caminar, teléfono, conversación, descanso y pistas. Un civil entra físicamente al laboratorio 302, llega a una silla, usa la pose sentada y alterna computador/teléfono/conversación/clase/salida según horario ficticio. El planificador mantiene como máximo seis civiles próximos activos y reutiliza LOD/SLEEP. No se usa navegación global para todos ni se desplazan NPC de misiones previas. La distribución visual y la convivencia con otros recorridos aún requieren revisión humana.

## 16. Historia

Se agrega DUOCGAMES: EL INCIDENTE NEXO: introducción, seis capítulos/epílogo, transiciones por progreso, consulta desde el celular y créditos/estadísticas. Se conserva el final existente de NEXO, su introducción, cierre, créditos y postgame. Los textos nuevos no borran victorias anteriores ni reabren misiones completadas. Falta una pasada narrativa/cinemática y una campaña humana completa.

## 17. Combate

Se conservan ataques, carga, armas, inventario, telegráficos, barras, fases, checkpoints y reintentos. Se añaden chispas digitales acotadas, sonidos de impacto y etiquetas de simulación. El modo aprendizaje limita daño y evita muerte sin alterar estadísticas de armas/jefes; se ofrece tiempo adicional. El inventario muestra vista previa y barra de durabilidad. Se retiraron del HUD de campaña las instrucciones y contadores duplicados del prototipo, conservando vida, arma y objetivo. Balance humano pendiente.

## 18. Guardado sin conexión

CloudSave escribe un journal por hash de proyecto y cuenta: snapshot confirmado, pendiente, operación y revisión. Escribe temporal, hace flush, verifica JSON/hash/campos, conserva generación .bak y promociona por renombrado. Antes de enviar persiste el ID único; al reiniciar reintenta ese mismo ID. Solo una confirmación exacta limpia la operación. Cambiar de cuenta no reclama la cola ajena; conflictos conservan cambios y exigen elección explícita. Un tombstone impide resucitar descartes. Se prueban reinicio, respuesta perdida, corrupción y otro dispositivo simulado. La recuperación requiere autenticar la misma cuenta y conectar; no es un modo de inicio de sesión offline. No se promete supervivencia ante pérdida física del disco o corrupción de ambas generaciones. La prueba de fallo de disco confirma que ningún reintento puede enviar una operación que no esté protegida; al recuperar el disco se persiste y sincroniza la misma operación.

## 19. Seguridad

Se corrigió la pérdida de operaciones pendientes al cerrar el proceso y la aceptación insegura de versiones de guardado con tipos o fracciones inválidos. Los servicios nuevos rechazan respuestas de otra sesión, separan claves y contenido y no permiten al cliente escribir accesos/intentos. Los RPC SQL tienen search_path vacío y validan roles/asignaciones; no hay secretos de servidor en el código nuevo. Son controles implementados/preparados, no una certificación de vulnerabilidades remotas corregidas: la auditoría RLS real queda pendiente.

## 20. Rendimiento

Medición gráfica en la misma escena, posición, OpenGL y resolución (1152, 648): CPU de proceso 24.78 → 22.30 ms; draw calls 6421 → 6360; memoria interna 2322.35 → 2322.36 MiB. Se agrupan 127 mallas fijas y se comparten recursos de laboratorios. Las muestras de CPU variaron entre ejecuciones, incluyendo una regresión; MultiMesh sigue desactivado por defecto y disponible para comparación. La reducción de llamadas es repetible, pero no prueba una mejora estable de FPS. La prueba de ocultar iluminación se retiró por falta de beneficio. LOD/SLEEP y recursos compartidos permanecen. No se afirma 60 FPS ni se compara con todo el proyecto anterior a 4.0. Ver reports/v4_performance.json.

## 21. Audio real incorporado

13 WAV originales sintetizados y cargables: menú, hall, biblioteca, casino, laboratorio, taller, ascensor, interacción, impacto, recompensa, victoria, derrota e inicio de simulación. Se integra música en Login y menús del campus, buses Music/Ambient/Effects, volúmenes independientes y subtítulos visuales de señales relevantes. Son tonos y ambientes sintéticos propios CC0, no grabaciones del instituto ni voces profesionales. La mezcla requiere escucha y revisión humanas.

## 22. Recursos y partes pendientes

Faltan humano GLB autorizado con rig/skins/clips y piloto artístico; contenido educativo aprobado/publicado; plantillas Windows 4.7.2; validación real de sesiones, RLS y sincronización; revisión humana e institucional. Varias misiones conservan una presentación básica. El puente MCP de la sesión resolvía la carpeta superior. Se probó además el puente oficial ya instalado, con Juego explícito: conectó por MCP, pero el editor devolvió AUTH_FAILED. No se sortearon controles de autenticación ni se imprimieron tokens; hace falta reconexión válida al editor. El código y las pruebas funcionales se comprobaron con el ejecutable real de Godot.

## 23. Migraciones nuevas

008_education_activities_v4.sql: banco, claves privadas, tickets, intentos, accesos, imágenes y RPC. 009_learning_audit_v4.sql: administración de asignaturas, auditoría y estadísticas combinadas. verify_education_v4.sql: consultas de solo lectura para verificar permisos, RLS y funciones. Archivos preparados para revisión y ejecución manual; 001–007 no se editaron.

## 24. Pruebas aprobadas

Últimas ejecuciones del conjunto principal: 50 PASS AUTOMÁTICO de 51 suites; 0 sin resultado. La tabla del final enlaza cada log. Las pruebas de cuentas, roles y sincronización usan principalmente fixtures. Los tests renderizados generan capturas y no usan partidas personales. No hay PASS MANUAL humano.

## 25. Fallos

Fallos abiertos: SupabaseConnectionCheck; exportación Windows por plantillas ausentes; sonda MCP del editor por AUTH_FAILED. Las comprobaciones remotas siguen pendientes y ningún fallo externo se marcó PASS. Se corrigieron y repitieron fallos iniciales de compilación, expectativas antiguas de veinte misiones, lectura de contratos del ejecutor y posiciones físicas de laboratorios, escolta, Bugs y tablero. Los registros finales conservan únicamente el resultado más reciente de cada suite; el informe también explica los fallos abiertos.

## 26. Pruebas humanas pendientes

Campaña completa y dificultad; navegación desde pasillos a todas las salas; legibilidad a distintas resoluciones; remapeo y asistencia; escucha de audio; revisión docente de preguntas, explicación y prácticas de salud; permisos de imágenes; sesión real por rol; dos computadores reales; cierre inesperado y recuperación; duración prolongada y GPU de destino.

## 27. Demo Windows

FAIL en el intento real de exportación: faltan windows_debug_x86_64.exe y windows_release_x86_64.exe de 4.7.2.stable. Hay preset con filtros para excluir configuración, sesiones, fixtures, SQL y reportes. No se generó ni probó un EXE distribuible. No se sustituyó por una copia del editor ni se incluyeron credenciales. Ver reports/v4_export.log y DEMO_WINDOWS_4_0.md.

## 28. Pasos manuales

Restablecer DNS/conectividad y revisar la URL del proyecto Supabase sin publicar claves; revisar/aplicar 008 y 009 en el servidor correcto; ejecutar verify_education_v4.sql; asignar asignaturas por UUID con un administrador existente; publicar contenido autorizado por piso/mentor, incluidos accesos; probar subida de imágenes. Instalar plantillas 4.7.2, exportar release y configurar conexión por una fuente admitida fuera del paquete. Reconectar MCP con GODOT_MCP_PROJECT_PATH apuntando a Juego. Completar el guion de DEMO_WINDOWS_4_0.md con cuentas autorizadas.

## 29. Porcentaje con criterios explícitos

Índice de entrega técnica de este encargo: 64.6%. Se ponderan 24 hitos por igual: COMPLETO=1, PARCIAL=0,5, PENDIENTE=0. La tabla siguiente hace reproducible el cálculo. Es una rúbrica de alcance, no el porcentaje absoluto de todo el videojuego ni una certificación de presentación. Un servidor o EXE sin validar impide declarar la plataforma lista aunque muchas pruebas locales pasen.

| Hito | Estado |
| --- | --- |
| Auditoría y recuperación | COMPLETO |
| Cola persistente local | COMPLETO |
| RPC de actividades desplegadas | PARCIAL |
| Banco docente de actividades | PARCIAL |
| Accesos académicos por piso | PARCIAL |
| Mentores y simulaciones | PARCIAL |
| Laboratorios y sala técnica | COMPLETO |
| Rescate físico | COMPLETO |
| Otras cinco misiones educativas | PARCIAL |
| Misiones dinámicas configurables | COMPLETO |
| Rutinas de NPC | COMPLETO |
| Modelo humano real autorizado | PENDIENTE |
| Historia y presentación narrativa | PARCIAL |
| Feedback de combate | COMPLETO |
| Inventario y credenciales | COMPLETO |
| Pantalla de progreso académico | COMPLETO |
| Estadísticas docentes remotas | PARCIAL |
| Panel administrativo ampliado | PARCIAL |
| Seguridad remota comprobada | PARCIAL |
| Optimización en equipos destino | PARCIAL |
| Audio propio integrado | COMPLETO |
| Accesibilidad completa | PARCIAL |
| Demo Windows exportada y probada | PENDIENTE |
| Validación humana e institucional | PENDIENTE |

## 30. Qué falta para presentar a Duoc UC

Resolver conexión y desplegar con autorización; validar el recorrido real docente→publicación→estudiante→actividad→simulación→recompensa→guardado→continuación; completar los apartados parciales de la rúbrica y el piloto humano cuando existan assets autorizados; terminar exportación/pruebas en otro PC; revisar contenido educativo, accesibilidad, rendimiento, privacidad, licencias y autorización institucional. No distribuir como versión final.

## Evidencia automática

| Suite | Resultado | Log |
| --- | --- | --- |
| campus_polish_regression | PASS AUTOMÁTICO | [registro](reports/v4_campus_polish_regression.log) |
| remember_login_check | PASS AUTOMÁTICO | [registro](reports/v4_remember_login_check.log) |
| revision_scripts | PASS AUTOMÁTICO | [registro](reports/v4_revision_scripts.log) |
| resource_reference_check | PASS AUTOMÁTICO | [registro](reports/v4_resource_reference_check.log) |
| campaign_regression | PASS AUTOMÁTICO | [registro](reports/v4_campaign_regression.log) |
| inventory_regression | PASS AUTOMÁTICO | [registro](reports/v4_inventory_regression.log) |
| gameplay_regression | PASS AUTOMÁTICO | [registro](reports/v4_gameplay_regression.log) |
| guardado_lectura | PASS AUTOMÁTICO | [registro](reports/v4_guardado_lectura.log) |
| nueva_partida | PASS AUTOMÁTICO | [registro](reports/v4_nueva_partida.log) |
| student_phone | PASS AUTOMÁTICO | [registro](reports/v4_student_phone.log) |
| campus_vivo | PASS AUTOMÁTICO | [registro](reports/v4_campus_vivo.log) |
| director_informatica_boss | PASS AUTOMÁTICO | [registro](reports/v4_director_informatica_boss.log) |
| nexo_final | PASS AUTOMÁTICO | [registro](reports/v4_nexo_final.log) |
| organizacion_pisos | PASS AUTOMÁTICO | [registro](reports/v4_organizacion_pisos.log) |
| education_1_0 | PASS AUTOMÁTICO | [registro](reports/v4_education_1_0.log) |
| education_integration | PASS AUTOMÁTICO | [registro](reports/v4_education_integration.log) |
| academic_schedule | PASS AUTOMÁTICO | [registro](reports/v4_academic_schedule.log) |
| balance_regression | PASS AUTOMÁTICO | [registro](reports/v4_balance_regression.log) |
| chef_supremo_casino | PASS AUTOMÁTICO | [registro](reports/v4_chef_supremo_casino.log) |
| contextual_interactions | PASS AUTOMÁTICO | [registro](reports/v4_contextual_interactions.log) |
| personalizacion | PASS AUTOMÁTICO | [registro](reports/v4_personalizacion.log) |
| chapel_layout_check | PASS AUTOMÁTICO | [registro](reports/v4_chapel_layout_check.log) |
| library_layout_check | PASS AUTOMÁTICO | [registro](reports/v4_library_layout_check.log) |
| coordinacion_layout_check | PASS AUTOMÁTICO | [registro](reports/v4_coordinacion_layout_check.log) |
| coordinacion_meeting_check | PASS AUTOMÁTICO | [registro](reports/v4_coordinacion_meeting_check.log) |
| salidas_emergencia | PASS AUTOMÁTICO | [registro](reports/v4_salidas_emergencia.log) |
| piso5_escalera_recorrido | PASS AUTOMÁTICO | [registro](reports/v4_piso5_escalera_recorrido.log) |
| piso8_recorridos | PASS AUTOMÁTICO | [registro](reports/v4_piso8_recorridos.log) |
| supabase_response_regression | PASS AUTOMÁTICO | [registro](reports/v4_supabase_response_regression.log) |
| primera_mision | PASS AUTOMÁTICO | [registro](reports/v4_primera_mision.log) |
| placement_visual_check | PASS AUTOMÁTICO | [registro](reports/v4_placement_visual_check.log) |
| camera_obstruction_check | PASS AUTOMÁTICO | [registro](reports/v4_camera_obstruction_check.log) |
| SupabaseAuthCheck | PASS AUTOMÁTICO | [registro](reports/v4_SupabaseAuthCheck.log) |
| EmailRegistrationCheck | PASS AUTOMÁTICO | [registro](reports/v4_EmailRegistrationCheck.log) |
| SignupDiagnosticsUnit | PASS AUTOMÁTICO | [registro](reports/v4_SignupDiagnosticsUnit.log) |
| UserRolesCheck | PASS AUTOMÁTICO | [registro](reports/v4_UserRolesCheck.log) |
| AcademicBossesCheck | PASS AUTOMÁTICO | [registro](reports/v4_AcademicBossesCheck.log) |
| UpperCampusCheck | PASS AUTOMÁTICO | [registro](reports/v4_UpperCampusCheck.log) |
| BasementAccessCheck | PASS AUTOMÁTICO | [registro](reports/v4_BasementAccessCheck.log) |
| ElevatorBasementCheck | PASS AUTOMÁTICO | [registro](reports/v4_ElevatorBasementCheck.log) |
| SupabaseConnectionCheck | FAIL | [registro](reports/v4_SupabaseConnectionCheck.log) |
| LibraryAccessCheck | PASS AUTOMÁTICO | [registro](reports/v4_LibraryAccessCheck.log) |
| AuditorioAccessCheck | PASS AUTOMÁTICO | [registro](reports/v4_AuditorioAccessCheck.log) |
| cloud_save_check | PASS AUTOMÁTICO | [registro](reports/v4_cloud_save_check.log) |
| cloud_campaign_check | PASS AUTOMÁTICO | [registro](reports/v4_cloud_campaign_check.log) |
| visual_detail_check | PASS AUTOMÁTICO | [registro](reports/v4_visual_detail_check.log) |
| rendered_gameplay_check | PASS AUTOMÁTICO | [registro](reports/v4_rendered_gameplay_check.log) |
| placement_stairs_visual_check | PASS AUTOMÁTICO | [registro](reports/v4_placement_stairs_visual_check.log) |
| persistent_queue_v4 | PASS AUTOMÁTICO | [registro](reports/v4_persistent_queue_v4.log) |
| learning_activity_v4 | PASS AUTOMÁTICO | [registro](reports/v4_learning_activity_v4.log) |
| campus_v4 | PASS AUTOMÁTICO | [registro](reports/v4_campus_v4.log) |

Las comprobaciones de diseño físico adicionales están en v4_floor3_layout.json y v4_floor3_north_layout.json. La inspección automática de SQL no sustituye ejecutar RLS con roles reales.
