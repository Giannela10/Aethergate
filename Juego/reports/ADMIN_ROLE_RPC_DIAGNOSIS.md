# Diagnóstico real de admin_set_user_role

Sin invocar cambios de rol en pruebas. Se capturó la petición anterior del usuario
desde el log de Godot MCP y los argumentos vinculados al formulario seleccionado.

- POST /rest/v1/rpc/admin_set_user_role: HTTP 404, PGRST202.
- Mensaje: Could not find the function public.admin_set_user_role(new_role, target_user_id) in the schema cache.
- La respuesta original no conservaba details/hint. El nuevo logger los captura
  sanitizados en el próximo intento manual; no se inventan estos valores.
- Sesión real (no DEV) válida, email y JWT presentes, runtime role admin.
- GET /auth/v1/user: 200, ID coincide con AuthManager.
- GET profiles por el ID autenticado: 200, ID y correo coinciden, role admin.
- Cuenta confirmada: nicolashernandezdelarosa@gmail.com.
- Destino seleccionado: 6b7748aa-71a5-46dc-9f4a-c27f1e6ec93e (Matías), role student.
- Selector índice 2 mapeado por el código a teacher; payload usa target_user_id UUID
  y new_role teacher, nunca el nombre del usuario ni la etiqueta PROFESOR.
- GET admin_audit_log?select=id&limit=0: HTTP 404, PGRST205 (tabla no visible en caché).
- OpenAPI GET /rest/v1/: 401. No permite confirmar desde el cliente la existencia
  física de la función ni sus grants. El login y profiles sí funcionaron con 200.

El fallo observado sucede en la resolución de la RPC antes de ejecutar su cuerpo;
no se observó rechazo de RLS ni falta de rol admin. No se puede distinguir solo
con estos HTTP entre migración ausente/incompleta y esquema sin recargar.

## Reparación manual

1. CHECK_ADMIN_ROLE_RPC.sql en supabase/diagnostics permite comprobar función,
   firma, grants, propietario y tabla desde SQL Editor sin modificar cuentas.
2. Si 004 no fue aplicada, ejecutar supabase/migrations/004_user_roles_admin.sql.
3. Ejecutar supabase/migrations/005_fix_admin_roles.sql. Requiere la tabla de
   auditoría de 004; si falta, aborta con un mensaje explícito. Restablece la RPC
   con argumentos target_user_id/new_role, auth.uid(), SECURITY DEFINER,
   search_path vacío, control admin, protección del último admin y auditoría
   transaccional. Restablece EXECUTE authenticated, revoca anon/public y notifica
   a PostgREST que recargue el esquema. No cambia cuentas al ejecutar la migration.
4. Reintentar manualmente Admin → Usuarios → Matías → Profesor → Guardar cambios.
   Compartir [ADMIN_ROLE_RPC] si falla. No se aplicó SQL remotamente en este trabajo.

Nicolás ya es admin en Supabase y Godot. El bootstrap se dejó consistente con el
correo indicado; no se ejecutó y no se añadió ninguna excepción por correo al
cliente. Matías no fue modificado. La UI permanece igual.
