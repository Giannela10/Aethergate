# DUOCGAMES EDUCATIVO 1.0

Diagnóstico vigente de registro: config real reconocida, Auth 200, Email/signup
habilitados y tablas protegidas con 401 anónimo. El estado 404 descrito en la
primera integración más abajo es histórico. Se agregó diagnóstico de transporte
y errores HTTP sanitizado solo para debug; no se modificó diseño ni gameplay.
El formulario conserva las contraseñas ante fallos para permitir reintentar.
No se crearon usuarios: el POST de control con JSON malformado respondió 400.
El resultado de un registro válido solo se obtendrá cuando el usuario reintente.

Primera integración: inicio, autenticación, roles, panel de preguntas y acceso
educativo al Piso 3. No convierte todavía profesores ni construye laboratorios.
Consulta AUTH_ARCHITECTURE.md, GOOGLE_SUPABASE_SETUP.md y FLOOR3_EDUCATION_PLAN.md.

El Login permite Google, registro con nombre/correo/contraseña y acceso con correo.
El fondo conserva la captura del campus. Las cuentas nuevas son pending (tras aplicar 004) y se
gestionan en Supabase Auth; no hay base de contraseñas dentro del juego. El envío
de confirmación requiere habilitar Email/SMTP y Site URL en Supabase.

Conexión real: la clave pública existente ya se carga desde
`config/auth_config.json`, ignorado por Git. Se admiten `supabase_publishable_key`
y el alias antiguo `supabase_anon_key`, en ese orden, únicamente con valores
publishable. La plantilla se dejó sin valores reales. El GET de configuración
Auth respondió 200; las tablas educativas todavía respondieron 404. El SQL se
preparó localmente y debe aplicarse en SQL Editor; no se usó la clave pública
para DDL ni se crearon usuarios remotos de prueba.

Signup envía email/password y metadata display_name. Login y refresh consultan
profiles con el ID autenticado; roles desconocidos o perfiles ausentes no dan
permisos. El trigger actualizado en 004 fija pending, con compatibilidad para full_name de Google.
La sesión local persiste solo URL y refresh token, nunca contraseña. El panel
debug muestra estado, rol e ID abreviado sin tokens ni clave pública completa.

El panel docente usa REST/RPC autenticado y RLS; el PATCH exige una fila devuelta
para confirmar el cambio y no reporta éxito cuando RLS filtra la operación.
La verificación CRUD real requiere primero aplicar SQL y asignar una cuenta
docente a sus asignaturas por administración segura.

## Componentes

Escenas nuevas: `scenes/education/Login.tscn`, `StudentMainMenu.tscn`,
`TeacherDashboard.tscn`, `AdminDashboard.tscn`. Inicio en Login; la renovación
de sesión actúa como bootstrap sin instanciar Main anticipadamente.

Scripts nuevos:

- `scripts/auth/auth_manager.gd`: identidad, sesión, OAuth, refresh y logout.
- `scripts/auth/supabase_client.gd`: peticiones HTTPS/JSON con tiempo y tamaño limitados.
- `scripts/auth/oauth_loopback.gd`: callback temporal localhost.
- `scripts/education/question_service.gd`: preguntas, respuestas y CRUD docente.
- `scripts/education/academic_progress.gd`: migración y métricas locales.
- `scripts/education/academic_floor_gate.gd`: primera integración de juego.
- `scripts/education/education_shell.gd`: Login y paneles por rol.
- `scripts/education/question_view.gd`: componente idéntico para pregunta estudiantil y preview docente.
- `addons/education_export_guard/`: filtro de configuración y datos debug.

Autoloads: AuthManager y QuestionService. Recursos demo:
`resources/education/demo_questions.json`, exclusivamente debug con claves.

## Roles y paneles

STUDENT ve saludo, avatar opcional, Continuar, Nueva partida, Progreso, Ajustes
y Cerrar sesión. Un fallo del avatar no bloquea el menú. Ajustes iniciales
permiten alternar pantalla completa; las opciones completas siguen en campaña.

TEACHER lista preguntas de asignaturas asignadas, crea, edita preguntas propias,
activa/desactiva y abre vista previa sin registrar intentos. El formulario toma
el piso de la asignatura; pide cuatro alternativas, dificultad, clave y
explicación. La lista puede incluir preguntas de otros docentes de la misma
asignatura; sus cambios serán rechazados por RLS. No existe borrado definitivo.
Las ediciones de texto y clave se guardan en una transacción mediante save_question.
Las estadísticas docentes son un placeholder expresamente identificado.

ADMIN usa la gestión de preguntas y consulta asignaturas. Profesores y gestión
avanzada de asignaturas quedan preparados en tablas/RLS; su administración
completa en UI pertenece a la siguiente etapa. Los roles solo se asignan en
administración segura de PostgreSQL. Ni el admin cliente tiene permiso de
escritura sobre profiles.

## Base de datos y respuestas privadas

Tablas: profiles, subjects, teacher_subjects, questions, question_keys,
question_attempts y academic_progress. Hay índices por asignatura, creador,
estudiante y pregunta; trigger de perfil inicial y guardia de identidad/piso.
Las claves y explicaciones no forman parte de questions.

RLS habilitado en todas las tablas. Las funciones auxiliares viven en
education_private, fuera del esquema público expuesto por PostgREST. El rol se
consulta desde profiles mediante funciones con search_path vacío. La tabla
privada question_tickets limita cada usuario a una pregunta emitida vigente.

get_random_question requiere una cuenta habilitada (student/teacher/admin), asignatura activa,
pregunta activa y clave existente. Emite un ticket válido por 15 minutos.
submit_answer requiere auth.uid(), opción/contexto válidos y ticket coincidente;
lo bloquea, consume y registra en una transacción. Solo entonces devuelve
correct, explanation, question_id y selected; nunca correct_option. El RPC
actualiza contadores remotos y no acepta student_id ni correct desde el cliente.
SECURITY DEFINER se limita a estas funciones, con objetos completamente
cualificados, search_path vacío y EXECUTE revocado a public/anon. El CRUD usa
SECURITY INVOKER para respetar RLS. Las claves solo las lee/administra el creador
autorizado o un admin. No hay INSERT directo de intentos desde el cliente.

Las funciones no convierten la práctica en una evaluación formal: faltan
políticas institucionales de frecuencia, límites de intentos y métricas docentes.

## Piso 3 y progreso

AcademicFloorGate se instala al final del boot de campaña. Solo actúa en el
flujo educativo y para STUDENT. Vigila la banda de llegada del Piso 3 en física
(altura 23.967668533 ± 2.4 m), con independencia de X/Z: cubre ascensor,
escalera central, emergencia y entrada desde arriba. Antes del acceso devuelve
al último punto fuera de esa banda y abre una pregunta INF_GENERAL. Es un
guardia de llegada conservador, no una puerta que altere la geometría.

Responder bien guarda academic_floor_unlocks["3"]=true. Las respuestas erróneas
solo muestran explicación y permiten otra pregunta; no restan vida ni objetos.
Volver deja al jugador fuera del piso y puede reintentar. Un save antiguo que
ya estaba dentro del piso puede volver a la entrada al enfrentar el piloto por
primera vez. Los desbloqueos argumentales del ascensor continúan independientes.
Quien ya pasó el piloto no necesita conexión para volver a ese piso.

La UI permite ratón y navegación de foco con teclado; usa los ui_* de Godot
para control. El funcionamiento con mando físico queda pendiente de prueba.

Guardado local: campaña anterior intacta, academic_floor_unlocks,
academic_progress (answered/correct/incorrect/subjects y hasta 200 registros
offline_attempts). Los intentos locales se conservan para futura sincronización,
pero **no se suben ni se mezclan con intentos remotos verificados**.
Supabase guarda identidades, perfiles, roles, asignaturas, preguntas/claves,
asignaciones, intentos autenticados y contadores por asignatura. No guarda el
save completo, inventario ni ubicación del jugador.

## Política offline

Debug/editor: preguntas locales aleatorias sin repetir la anterior cuando hay
alternativas; la clave queda dentro del servicio, no en el DTO estudiantil.
El profesor DEV trabaja con datos temporales en memoria y solo INF_GENERAL.

Release sin conexión durante una sesión válida: práctica guiada explícitamente
offline, con explicación didáctica en el enunciado y comprobación local. No usa
el JSON con claves ni pretende ocultar una respuesta de evaluación remota.
Permite desbloquear el piloto y registra offline_attempt/práctica. Esta decisión
resuelve la tensión entre no distribuir claves de evaluación y no impedir
entrar al piso sin red. En un arranque sin sesión renovable Release vuelve a
Login; no hay bypass de identidad ni roles de desarrollo en Release.

Un error HTTP de autorización o ausencia de preguntas no se disfraza de caída
de red: se informa al usuario. Solo errores de transporte/configuración activan
fallback. Una caída después de recibir una pregunta requiere solicitar otra
pregunta; nunca se inventa la clave de la pregunta remota.

## Límites y próximos pasos

Google OAuth, despliegue SQL y RLS real necesitan credenciales e instancia
externa; no están marcados PASS. El almacenamiento seguro de refresh token en
el sistema operativo, administración avanzada y exportación Release validada
son trabajo previo a un despliegue institucional. La vista previa comparte el
componente de pregunta del estudiante y no registra intentos.

Siguiente paso: configurar un Supabase de desarrollo, probar tres identidades
con RLS real y verificar el recorrido físico completo del piloto antes de
convertir al primer docente en mentor y simulación.

## Inicio 2.0

El fondo del campus se conserva. La portada tiene INICIAR SESIÓN, REGISTRARSE,
SALIR y Google solamente si está habilitado/configurado. Formularios separados,
Enter para enviar, contraseñas ocultas, bloqueo temporal de botones y estado
CONECTANDO. Un fallo permite reintentar sin borrar las contraseñas ingresadas.
El panel DEBUG abre un apartado de desarrollo cerrado por defecto; se construye
solamente bajo OS.is_debug_build(). No se ha validado una exportación Release.

Student: Continuar (deshabilitado sin guardado local), Nueva partida, Progreso
académico, Ajustes y Cerrar sesión. Teacher conserva las herramientas de preguntas.
Admin presenta Preguntas, Asignaturas, Profesores y Usuarios; las dos últimas
siguen como secciones preparadas. La autorización continúa en Supabase/RLS.
No se cambió gameplay, campus, campaña, bosses, inventario ni formatos de save.
Validación Login 2.0: 55 checks de sesión/autenticación, 47 de diagnóstico y
formulario, y 21 de registro simulado, sin fallos ni cuentas creadas. Las 12
suites del runner SupabaseRegressionRunner pasaron, incluidas campaña, guardados,
inventario, bosses y NEXO. Ver reports/supabase_auth_tests.json,
reports/signup_diagnostics_unit.json y reports/supabase_regressions.json.

Portada, login y registro sin scrollbar en viewports lógicos 1152x648, 1280x720,
1366x768 y 1920x1080 (reports/login2_ui.json). El editor mantiene la captura nativa
incrustada en 1152x648; los otros tamaños se probaron con content_scale_size.
La exportación Release y sus tamaños nativos quedan pendientes de validación.
Los botones de desarrollo están protegidos por OS.is_debug_build().

En la inspección actual no había archivo de sesión local; la configuración
runtime fue res://config/auth_config.json. No se capturó el payload original del
login fallido ni se verificó el profile de la cuenta real: no se usó contraseña,
no se hizo login email automático y no había una conexión administrativa.
## Flujo definitivo vigente: registro único y aprobación

REGISTRARSE → PENDING → ADMIN DECIDE → STUDENT / TEACHER / ADMIN.
No existe registro docente/admin ni selector o solicitud de rol. La nueva
migration 004_user_roles_admin.sql cambia solo el default y trigger de NUEVAS
cuentas; conserva los roles y guardados existentes. Cuenta pendiente no entra al
juego: permite Actualizar estado (profile propio) o Cerrar sesión.

Admin tiene gestión de usuarios con búsqueda nombre/correo, filtros, actualización,
selección por UUID, cambio mediante RPC y auditoría. Tras elegir teacher permite
asignar materias por RPC atómica. Teacher puede jugar desde StudentMainMenu sin
cambiar de rol; Admin puede abrir ambos paneles. La RPC protege el último admin
con bloqueo transaccional. No se ejecutó SQL remoto ni se alteraron cuentas reales.

Aplicar 004 en SQL Editor; luego bootstrap/SET_FIRST_ADMIN.sql sustituyendo
CORREO_DEL_ADMIN manualmente. Después usar Admin → Usuarios para Maty. Ver
ROLE_SYSTEM.md y ADMIN_PANEL.md. Las notas anteriores sobre student por defecto
y gestión futura de usuarios describen la etapa histórica anterior a 004.
## Resultado de validación de roles definitivos

Godot MCP: 57 checks nuevos de roles/UI y modelo de políticas, más 55 de sesión,
47 de diagnóstico/formulario y 21 de registro: 180 sin fallos. Las 12 suites de
regresión existentes pasaron (campaña, guardados, inventario, bosses y NEXO entre
ellas). Evidencia: reports/user_roles_tests.json, reports/user_roles_ui.json y
reports/supabase_regressions.json. Pending/Teacher/Admin sin scrollbar en 1152x648.

Las comprobaciones de seguridad nuevas usan un modelo en memoria y revisión
estática de SQL, no PostgreSQL remoto. No hay PASS de RLS remoto ni de aplicación
de 004. Las cuentas reales y el bootstrap quedaron sin ejecutar. Tras desplegar,
probar manualmente pending, asignación y denegaciones con sesiones reales.