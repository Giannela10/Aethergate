# Sistema definitivo de roles

Inicio actual: portada y acceso manual por defecto. La restauración al arrancar
requiere «Mantener sesión iniciada» marcado en el login anterior. El rol siempre
se vuelve a consultar en profiles; no se guarda como permiso local. Logout borra
identidad, perfil y la preferencia. Ver AUTH_ARCHITECTURE.md y
PROJECT_CLEANUP_AUDIT.md para la validación y la auditoría actual.

REGISTRARSE → PENDING → ADMIN DECIDE → STUDENT / TEACHER / ADMIN.

Hay un único formulario: nombre, correo, contraseña y confirmación. No envía
role en el body ni en metadata. Tras aplicar 004, el default y el trigger de
PostgreSQL crean perfiles pending, también para Google. La migración no convierte
cuentas existentes ni modifica partidas. El rol siempre procede de profiles,
identificado por el UUID de auth.users; nunca del nombre o de metadata editable.

| Rol | Acceso |
| --- | --- |
| pending | Su perfil, Actualizar estado y Cerrar sesión. No entra al juego ni a herramientas docentes. |
| student | Juego, misiones, preguntas y progreso. Sin escritura de preguntas/roles ni lectura de claves privadas. |
| teacher | Materias asignadas, preguntas autorizadas, edición de sus propias preguntas y juego. |
| admin | Usuarios, roles, asignaciones, todas las preguntas/asignaturas, panel docente y juego. Estadísticas siguen preparadas. |

`AuthManager.route_authenticated_user(requested_view)` centraliza la navegación:
PendingAccountScreen, StudentMainMenu, TeacherDashboard o AdminDashboard.
Teacher y Admin pueden solicitar StudentMainMenu sin cambiar su role; Admin
también puede solicitar TeacherDashboard. Pending y Student no pueden solicitar
un panel de personal. Actualizar estado consulta su propio profile de nuevo y
emite el cambio de sesión para navegar al menú habilitado. No hay realtime.

## Despliegue manual

1. Con 001 ya aplicada, ejecutar `supabase/migrations/004_user_roles_admin.sql`
   en Supabase SQL Editor. Ejecutar las migraciones en orden; no reaplicar las
   antiguas 002/003 después de 004, porque contienen el trigger histórico student.
2. Abrir `supabase/bootstrap/SET_FIRST_ADMIN.sql`. Reemplazar CORREO_DEL_ADMIN
   por el correo verificado de la cuenta de Nicolás. Verificar primero que se
   encuentra exactamente la cuenta deseada. Ejecutar el UPDATE y el SELECT final.
   Si no hay profile, detenerse y revisar el registro/trigger antes del bootstrap.
3. Cerrar sesión y entrar con esa cuenta. Si está en Cuenta pendiente, pulsar
   Actualizar estado. Los siguientes cambios se hacen desde Admin → Usuarios.

El bootstrap es una excepción manual y privilegiada para crear el primer admin;
no utiliza display_name ni se ejecuta desde Godot. No contiene correos reales.
No se ejecutó 004 ni el bootstrap remotamente desde este trabajo.

## Seguridad en PostgreSQL

`admin_set_user_role(target_user_id UUID, new_role TEXT)` es SECURITY DEFINER con
search_path vacío. Comprueba auth.uid() y el rol actual en la base de datos;
rechaza roles distintos de pending/student/teacher/admin y cuentas inexistentes.
Los clientes no tienen permisos de escritura directa sobre profiles.

Un advisory transaction lock serializa cambios de rol y asignaciones; además se
bloquean las filas del actor y del destino. No permite degradar al último admin,
incluso con peticiones concurrentes entre administradores. El cliente traduce
LAST_ADMIN a «No puedes quitar el último administrador».

Cada cambio efectivo inserta admin_audit_log en la misma transacción: admin_id,
target_user_id, action, old_role, new_role y fecha. Las asignaciones también se
auditan con subject_ids en details. Solo Admin puede leer la auditoría; el cliente
no puede insertar/modificar sus registros. Guardar el mismo rol no genera un
cambio ficticio. Las asignaciones previas se conservan al cambiar de rol y quedan
inactivas por las verificaciones de role; un admin debe revisarlas al reactivar
un docente.

teacher_subjects conserva RLS: Admin escribe, Teacher lee sus propias materias.
`admin_set_teacher_subjects` vuelve a comprobar Admin, valida UUIDs/asignaturas y
el rol teacher del destino y reemplaza la selección atómicamente. Un docente no
puede autoasignarse. save_question y RLS siguen exigiendo materia asignada y
propiedad de la pregunta, excepto Admin. question_keys sigue privada para Student
y Pending. Las RPC de juego aceptan Student/Teacher/Admin, nunca Pending.

## Validación

`tests/UserRolesCheck.tscn` se ejecuta con Godot MCP y usa almacenamiento en memoria,
un modelo de políticas y los callbacks reales de formularios/servicios. Incluye
registro pending, routing, búsqueda, cambio por UUID con nombres repetidos,
autoelevación rechazada por el modelo, último admin, auditoría, asignación y
preguntas autorizadas. También revisa declaraciones SQL estáticamente.
Esto NO demuestra la ejecución de RLS en PostgreSQL remoto: aplicar 004 y validar
con sesiones reales de cada rol. No se crearon ni modificaron cuentas reales.
