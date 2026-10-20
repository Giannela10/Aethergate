# Configuración Google + Supabase

## Diagnóstico vigente del registro

El usuario ya aplicó 001. La comprobación actual de Auth devuelve 200, con Email
y signup habilitados, y las tablas devuelven 401 para el cliente anónimo en vez
de 404. No repetir 001 para resolver este problema ni conceder permisos anónimos
a las tablas de perfiles/claves. La sección «Estado de esta conexión» siguiente
describe el diagnóstico histórico anterior a aplicar SQL.

Para repetir el registro: F5 → Registrarse → completar los cuatro campos → Crear
cuenta. Con debug, revisar `[AUTH_CONFIG]`, `[AUTH_SIGNUP_REQUEST]` y `[AUTH_HTTP]`
en Output. No copiar contraseñas ni tokens: el diagnóstico solo conserva flags,
longitud, URL sin claves, HTTP status, resultado de transporte y error sanitizado.
Si falla, los campos permiten corregir y reintentar sin borrarse antes del resultado.

- status 0: revisar failure_kind (timeout/DNS/TLS/inicio de solicitud).
- 400/422: revisar el código de validación; no equivale a falta de Internet.
- 401/403 del signup: revisar clave pública o habilitación/permisos de Auth.
- 429: esperar y revisar límites de envío de email.
- 500 con error de base de datos: revisar Auth Logs/Postgres Logs y trigger
  education_profile; no se demuestra el funcionamiento del trigger con un GET.
- Error enviando confirmación: revisar SMTP y registros del proveedor.

La prueba POST de diagnóstico usó JSON deliberadamente inválido y recibió 400;
no creó usuarios ni reprodujo el contenido del intento válido anterior. La causa
exacta de ese intento requiere el siguiente envío manual con diagnóstico activo.

## Estado de esta conexión

No hace falta volver a copiar credenciales: se conservaron los valores ya
existentes del ejemplo en `config/auth_config.json` y se limpió la plantilla.
El loader reconoce `supabase_publishable_key` primero y `supabase_anon_key`
como alias de compatibilidad; ambos deben contener una clave pública
`sb_publishable_…`. La configuración real no está versionada.

La comprobación GET real a Supabase Auth respondió HTTP 200, con Email habilitado
y nuevos registros permitidos. Las tablas educativas respondieron 404/ausentes
del esquema expuesto. No hay acceso administrativo configurado ni se ejecutó SQL
remoto. **Ahora ejecuta este archivo en Supabase SQL Editor:**
`supabase/migrations/001_education_auth.sql`.
Después ejecuta `supabase/seeds/001_subjects.sql` para las asignaturas iniciales.
No ejecutes seeds de preguntas ni crees usuarios automáticamente para comprobar
la conexión. La primera cuenta debe registrarse manualmente desde el juego.

Si 001 ya estaba aplicado en otra instalación anterior, no lo repitas: el
parche `supabase/migrations/002_profile_display_name.sql` adapta el trigger al
metadata actual conservando el nombre anterior de Google. Se incluye además
`supabase/verify_education_auth.sql`, que verifica el esquema sin crear cuentas.

El formulario envía nombre como `data.display_name`; el trigger de 004 fija pending y
no toma roles del metadata. Un signup sin sesión muestra el mensaje de revisar
correo y vuelve al acceso. Si Supabase devuelve explícitamente un error de
cuenta existente, se muestra su mensaje amigable; cuando el servidor oculta
esa existencia por seguridad, el cliente respeta su respuesta genérica.

## Registro e inicio de sesión con correo

El Login incluye **REGISTRARSE** e **INICIAR SESIÓN CON CORREO**, además de Google.
Las cuentas viven en Supabase Auth, no en una base local ni en una tabla de
contraseñas propia. El juego solo envía la contraseña por HTTPS durante la
solicitud; no la guarda en archivos, profiles, campaña ni registros.

1. Configura URL y anon/publishable key como se indica abajo y aplica la
   migración inicial para crear profiles y su trigger.
2. En Supabase Authentication → Providers → Email habilita el acceso con correo
   y permite nuevos registros. Mantén **Confirm email** activado para cuentas reales.
3. Configura la política de contraseñas en Supabase. La UI exige al menos 8
   caracteres al registrarse; el servidor puede exigir requisitos adicionales.
4. Configura SMTP para enviar correos a tus usuarios. El servicio de prueba
   incluido tiene restricciones; no equivale a un envío de producción.
5. En URL Configuration configura **Site URL** con una página web controlada
   por ti para la confirmación (por ejemplo, una página que indique «Correo
   confirmado. Vuelve a DuocGames»). El registro usa el enlace de confirmación
   de Supabase y su Site URL; no usa el callback temporal del login Google ni
   inicia sesión automáticamente desde el navegador. Evita dejar el valor
   predeterminado localhost:3000 en un despliegue real. Si usas una URL de
   confirmación con tokens en el fragmento, no los registres ni incluyas scripts
   de terceros en esa página.
6. En el juego selecciona Registrarse, completa nombre, correo, contraseña y
   confirmación. No hay selector de rol: el trigger de 004 siempre asigna pending.
7. Confirma el mensaje recibido y vuelve al juego para entrar con correo y
   contraseña. Una cuenta creada sin confirmación habilitada puede recibir
   sesión inmediata; el cliente también maneja ese caso.

Los mensajes de registro no confirman si un correo ya estaba registrado. Los
errores de conexión y configuración no crean una cuenta local alternativa.
La recuperación/cambio de contraseña desde el juego queda para una etapa posterior.
Registro remoto, SMTP y correo de confirmación requieren prueba con el proyecto
Supabase real; las pruebas locales usan respuestas simuladas, no cuentas reales.

Referencia: https://supabase.com/docs/guides/auth/passwords

La plantilla no incluye credenciales reales. No se ha creado ni modificado
ningún proyecto remoto automáticamente.

1. Crea un proyecto en Supabase para desarrollo y conserva la contraseña de
   PostgreSQL fuera del juego.
2. En la configuración del proyecto copia Project URL (`https://...supabase.co`).
3. Usa la clave **publishable** en `supabase_publishable_key`. El nombre
   `supabase_anon_key` se mantiene como alias para esa misma clase de clave. Nunca uses
   `service_role` ni una clave `sb_secret_...`. El adaptador rechaza estas claves
   conocidas; la seguridad definitiva reside en Auth/RLS.
4. Aplica `supabase/migrations/001_education_auth.sql` desde SQL Editor o tu flujo
   habitual de migraciones, y después `supabase/seeds/001_subjects.sql`.
5. En Authentication → Sign In / Providers → Google activa el proveedor y copia
   la **Callback URL de Supabase** que muestra el panel.
6. En Google Cloud crea/selecciona un proyecto. Configura la pantalla de
   consentimiento Google Auth Platform: audiencia institucional/externa según
   corresponda, nombre de aplicación, contactos y usuarios de prueba si está
   en Testing.
7. Crea un cliente OAuth de tipo **Web application**, usado por Supabase.
   En Authorized redirect URIs pega exactamente la URL del paso 5, normalmente
   `https://TU_PROYECTO.supabase.co/auth/v1/callback`.
   **No pongas el callback local de Godot como redirect de este cliente Google.**
8. Copia Client ID y Client Secret a la configuración del proveedor Google
   **en Supabase**. El Client Secret nunca se copia a Godot ni al repositorio.
9. En Supabase Authentication → URL Configuration → Redirect URLs añade el
   callback de aplicación:
   `http://127.0.0.1:8765/auth/callback` y la variante con query nonce
   `http://127.0.0.1:8765/auth/callback?nonce=*` para desarrollo. Comprueba el
   patrón con tu instancia: Supabase aplica coincidencia de URL/globs. El nonce
   cambia en cada intento; no uses un nonce fijo ni un redirect abierto.
   Si cambias el puerto, actualiza configuración y allowlist. El listener usa
   127.0.0.1, no 0.0.0.0 ni el nombre localhost.
10. Copia `config/auth_config.example.json` a uno de estos lugares:
    - preferido: un archivo externo cuya ruta indique `DUOCGAMES_AUTH_CONFIG`;
    - `user://auth_config.json` (Godot → Open User Data Folder);
    - desarrollo: `config/auth_config.json`, excluido por `.gitignore` y por el
      export guard.
    Sustituye URL y anon/publishable key; deja `google_enabled: true` y el puerto
    8765. No hay que poner una contraseña ni Client Secret en ese JSON.
11. Abre F5, pulsa Continuar con Google y entra con tu cuenta de prueba. El primer
    perfil será siempre `pending` (tras 004). Si falla, comprueba provider, allowlist,
    usuarios de prueba de Google, migración y estado del puerto local.
12. Aplicar 004_user_roles_admin.sql y preparar SET_FIRST_ADMIN.sql con el correo verificado. Ejecutar el bootstrap manual solo para el primer admin.
13. Los siguientes roles y asignaciones se cambian desde Admin → Usuarios/Profesores. No usar UPDATE profiles desde Godot. Ver ROLE_SYSTEM.md y ADMIN_PANEL.md.

14. Cierra sesión y vuelve a entrar para cargar el rol actualizado. Crea
    preguntas desde el panel docente, o ejecuta opcionalmente
    `supabase/seeds/002_demo_questions.sql` después de tener un admin. Este seed
    es para una sola ejecución de desarrollo; repetirlo duplica preguntas.
15. Verifica con tres cuentas reales distintas: estudiante, docente asignado y
    docente sin asignación. Comprueba que no pueden consultar claves, modificar
    roles ni editar preguntas ajenas. No basta probar solamente como postgres
    en SQL Editor: ese usuario privilegiado evita RLS.
16. Sin «Mantener sesión iniciada», cerrar y abrir debe mostrar la portada.
    Marcándolo en el login con correo, el siguiente inicio debe renovar sesión
    y consultar el rol. Comprueba refresh inválido, revocación y logout; después
    de logout no debe restaurar. Google no habilita persistencia automáticamente.

Antes de Release, verifica que `Education Export Guard` esté activado. Excluye
el JSON demo con claves y las fixtures de tests en Release, `supabase/` y la configuración local real en
todas las exportaciones. Distribuye configuración pública por archivo externo
controlado por la institución. No hay build Release validada todavía.

Documentación oficial:
https://supabase.com/docs/guides/auth/social-login/auth-google
https://supabase.com/docs/guides/auth/redirect-urls
https://supabase.com/docs/guides/auth/sessions/pkce-flow

## Recuperación de perfil y prueba de Login 2.0

001 ya fue ejecutada por el propietario. No hace falta repetirla para este cambio.
Si Auth funciona pero profiles está ausente, ejecutar manualmente en SQL Editor:
`supabase/migrations/003_recover_missing_profiles.sql`. Los perfiles recuperados
siempre comienzan como student; el cliente no inserta ni eleva roles.

Abrir el juego, pulsar INICIAR SESIÓN, escribir correo/contraseña y pulsar Enter
o INICIAR SESIÓN. Si falla, compartir las líneas AUTH_LOGIN, AUTH_REFRESH,
AUTH_PROFILE y AUTH_ROUTE; nunca compartir contraseña ni archivos de sesión.
Si aparece PASSWORD_AUTH_OK seguido de PROFILE_ERROR, revisar el perfil, RLS y
logs de Postgres, sin cambiar la contraseña. Google permanece oculto cuando
`google_enabled` es false. No se realizó login real automático.

Las instrucciones históricas de recuperación 003 crean student. No reaplicar esa migración después de 004. El flujo vigente de nuevas cuentas es pending y aprobación desde el panel Admin.
