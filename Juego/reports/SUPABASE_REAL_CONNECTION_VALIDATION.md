# Conexión real de Supabase · validación

No contiene URLs privadas, API keys, tokens, contraseñas ni datos de cuentas.

## Configuración y auditoría

La configuración real estaba en `config/auth_config.example.json`, bajo
`supabase_url` y el alias `supabase_anon_key`, con un valor publishable.
Se copió al archivo real ausente `config/auth_config.json` antes de limpiar el
ejemplo. Los valores se conservaron. El archivo real está ignorado por Git.
La plantilla usa exclusivamente placeholders y `supabase_publishable_key`.
No se detectaron variables administrativas de entorno ni credenciales
peligrosas en los archivos de texto auditados del árbol de trabajo. No se
auditó historial Git ni se decodificaron assets binarios/cachés del editor.

El cliente soporta primero supabase_publishable_key y después supabase_anon_key.
Ambas propiedades aceptan solo la clase de clave pública sb_publishable.
No se aceptan claves secretas ni JWT administrativos. No se imprimen claves.

## Prueba real no destructiva

Lanzada mediante godot-mcp-toolkit en SupabaseConnectionCheck:

- Configuración efectiva: res://config/auth_config.json.
- GET /auth/v1/settings: HTTP 200; Email activo, nuevos registros permitidos.
- GET con limit=0 de profiles, subjects, teacher_subjects, questions,
  question_keys, question_attempts y academic_progress: HTTP 404 y tabla
  ausente/no disponible en la caché del esquema.
- Cero usuarios creados. Cero peticiones de autenticación con cuentas ficticias.
- Cero escrituras remotas. No se usó una API key para ejecutar DDL.

No se puede certificar que 001 esté aplicado remotamente. Ejecutar
`supabase/migrations/001_education_auth.sql` mediante Supabase SQL Editor;
después `supabase/seeds/001_subjects.sql`. `verify_education_auth.sql` permite
comprobar esquema, trigger, RLS y grants desde SQL Editor sin crear usuarios.

## Pruebas locales actuales

- SupabaseAuthCheck: 43 checks sin fallos. Prioridad de configuración, alias,
  rechazo de claves no públicas, headers, roles válidos, perfil ausente/discordante,
  rotación de refresh, renovación fallida, logout, mensajes y almacenamiento
  sin contraseña. Almacén aislado en memoria, sin tocar sesiones personales.
- EmailRegistrationCheck: 21 checks sin fallos, con respuestas simuladas.
- SupabaseRegressionRunner: 12 suites satisfactorias; campaña, inventario,
  jugabilidad, lectura de saves, Nueva partida, celular, campus vivo, Director,
  NEXO, organización de pisos y pruebas educativas. AcademicBossesCheck terminó
  sus 320 checks sin fallos y el runner cerró la escena después del resultado.

Evidencias: supabase_auth_tests.json, email_registration_tests.json,
supabase_regressions.json y supabase_connection_check.json.

## Pendientes que requieren operación manual

Aplicar SQL, confirmar SMTP/Site URL y registrar la primera cuenta real desde
el juego. Probar confirmación de correo, login, reinicio/refresh y logout reales.
Asignar teacher/admin y asignaturas desde un canal administrativo seguro;
comprobar CRUD/RLS con cuentas reales de cada rol, denegación de claves a student
y submit_answer con un intento autenticado. Ninguno de estos casos está marcado
PASS por las simulaciones locales. Google sigue preparado, desactivado en config.

El refresh token local sigue en el archivo de usuario con permisos del sistema;
no se presenta como un almacén cifrado de Windows. La contraseña nunca se guarda.
