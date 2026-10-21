# Panel de administración

Escena: `res://scenes/education/AdminDashboard.tscn`.
Controlador compartido: `scripts/education/education_shell.gd`.
Adaptador HTTP/RPC: `scripts/education/admin_service.gd` (nodo local del panel,
no añade Autoload). Usa el access token de AuthManager y la configuración existente.

La cabecera muestra Administrador y su nombre, sin UUID completo. Menú: Usuarios,
Profesores, Asignaturas, Preguntas, Estadísticas, Panel docente, Jugar, Cerrar
sesión. Las estadísticas siguen como placeholder. El fondo y el panel oscuro
conservan el estilo del campus. No hay eliminación de cuentas.

## Nicolás y Maty

1. Ejecutar la migración 004 y el bootstrap manual descritos en ROLE_SYSTEM.md.
2. Entrar con la cuenta de Nicolás verificada por correo/UUID, nunca por nombre.
3. Abrir Usuarios. La lista consulta profiles con RLS y pagina todas las filas
   mediante limit/offset. Muestra nombre, correo, rol y fecha. Buscar por nombre
   o correo, filtrar Todos/Pending/Estudiantes/Profesores/Admin y Actualizar.
4. Seleccionar la cuenta de Maty verificando su correo, especialmente si hay
   nombres repetidos. La selección guarda su UUID como identidad de destino.
5. Elegir Pendiente, Estudiante, Profesor o Administrador y Guardar cambios.
   No se hace PATCH/UPDATE profiles: se llama admin_set_user_role.
6. Si se eligió Profesor se abre inmediatamente Asignar asignaturas. Marcar las
   materias y Guardar. Se puede volver después desde Profesores → cuenta →
   Asignar asignaturas. La lista Profesores es el mismo gestor filtrado.
7. Maty pulsa Actualizar estado si estaba pending, o cierra sesión y vuelve a
   entrar. Student abre el menú de juego; Teacher abre Panel docente y también
   tiene Jugar, conservando el rol teacher.

Las cuentas anteriores conservan su rol actual, por lo que Maty puede aparecer
como student si se registró antes de 004. No se lo convierte a pending ni se
modifica automáticamente. Ninguna cuenta fue cambiada desde este trabajo.

## Materias y preguntas

El docente ve solo materias autorizadas mediante RLS. Crear/editar pregunta usa
save_question y sus políticas; un body modificado para otra asignatura es
rechazado por PostgreSQL. Admin puede ver todas las preguntas, su creador y
asignatura, crear/editar/activar/desactivar. Las claves privadas no se entregan
a estudiantes antes de responder. La administración avanzada de metadatos de
asignaturas y estadísticas no se amplía en esta etapa.

## Pruebas manuales tras aplicar SQL

- Registrar manualmente una cuenta: comprobar pending, ausencia de selector de rol
  y pantalla de espera. Si Supabase exige confirmar correo, confirmarlo primero.
- Admin cambia pending a student/teacher y la cuenta pulsa Actualizar estado.
- Teacher abre Jugar y vuelve a su panel manteniendo role teacher.
- Intentar la RPC con tokens Student/Teacher: debe rechazar aunque se cambie la UI.
- Intentar modificar profiles o teacher_subjects directamente como Student/Teacher:
  debe denegarse. Teacher solo lee sus asignaciones y no crea preguntas ajenas.
- Consultar question_keys como Student/Pending: no obtiene claves. Admin revisa
  admin_audit_log después de cambios reales.
- Con un único Admin, intentar degradarlo: debe aparecer la protección. Comprobar
  también dos degradaciones simultáneas si se dispone de dos Admin de prueba.

No compartir tokens ni contraseñas en logs. Godot no contiene claves administrativas.

## Diagnóstico real: RPC de roles no visible

Godot MCP capturó HTTP 404/PGRST202 en admin_set_user_role y 404/PGRST205 en la
consulta de solo lectura de admin_audit_log. Auth y profiles sí responden 200:
la cuenta administradora indicada por el propietario tiene admin en ambos lados.
No se añadió un bypass por correo en Godot ni se cambió Matías desde pruebas.

Ver reports/ADMIN_ROLE_RPC_DIAGNOSIS.md. La UI no cambió. AdminService ahora
registra REQUEST y respuesta con [ADMIN_ROLE_RPC], estado HTTP, code, message,
details, hint, UUID de destino y rol interno, sin tokens ni claves. Para comprobar
existencia física/grants usar supabase/diagnostics/CHECK_ADMIN_ROLE_RPC.sql.
Si falta 004, aplicarla primero; luego ejecutar 005_fix_admin_roles.sql para
restablecer la RPC/grants y recargar caché. Ninguno de esos archivos fue ejecutado
remotamente por el agente. Nicolás ya era admin: no requiere repetir bootstrap.