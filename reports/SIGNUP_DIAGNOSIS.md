# Diagnóstico de registro real desde Godot/MCP

Estado: transporte real verificado e instrumentación lista. No se envió un
registro válido ni se crearon usuarios. El fallo original necesita un reintento
manual para capturar su resultado exacto; no se inventa su causa.

## Evidencia de runtime

- Fuente efectiva: `res://config/auth_config.json`.
- URL HTTPS de Supabase configurada; clave publishable configurada.
- Endpoint final: el campo signup_endpoint de signup_runtime_diagnostics.json.
- Headers: apikey de la clave pública y Content-Type application/json; no se usa
  una API key como Bearer. No se imprimen valores de headers.
- GET Auth settings: 200, Email habilitado, nuevos registros permitidos.
- Confirmación de correo: la configuración pública indica que no es obligatoria.
- Seis tablas: 401 para consultas anónimas, ninguna 404. Esto no comprueba por sí
  solo el funcionamiento del trigger ni las políticas de un usuario autenticado.
- POST de control al signup: HTTP 400, error_code bad_json, resultado de
  transporte Godot 0 (RESULT_SUCCESS), aproximadamente 0.7 s.
- Mensaje del control: `Could not parse request body as JSON: unexpected end of JSON input`.

El JSON del control fue deliberadamente malformado, sin parámetros de cuenta,
para que Auth lo rechace antes de ejecutar cualquier alta, incluida la anónima.
No es el body construido por Registrarse ni el error del intento original.

## Hallazgos y correcciones

Antes, status 0 producía el mensaje de conexión sin conservar el resultado de
HTTPRequest. No se puede determinar retroactivamente si fue timeout, TLS, DNS,
inicio de solicitud u otra falta de respuesta HTTP. Los errores HTTP ya tenían
status, pero el mapper necesitaba más precisión. Además, el code numérico de
algunas respuestas GoTrue podía ocultar el error_code de máquina.

Ahora se distingue HTTP de transporte y se registran en debug únicamente URL
sin claves, status, resultado de transporte, error de inicio, duración, código y
mensaje sanitizado. La contraseña se representa solo como presencia/longitud;
email y nombre, solo como presencia. Claves, tokens y correos se redactan.
El último diagnóstico de signup se conserva por separado en memoria para que
una consulta posterior de profiles no lo sobrescriba. Release no imprime esto.

Validación local: nombre 2–80 caracteres, correo razonable, contraseña de al
menos 8 caracteres y confirmación coincidente; un fallo no envía requests.
Los campos secretos ya no se borran antes del envío. Se conservan ante fallos
y se limpian al tener éxito o abandonar el formulario. El diseño no cambió.

Mensajes separados para email inválido, contraseña débil, duplicado explícito,
signup deshabilitado, 401, 403, 400/422, límites 429 y errores 500+. Un error de
base de datos al guardar cuenta remite al trigger/logs; uno de envío remite a
SMTP. Ninguno se etiqueta automáticamente como falta de Internet.

## Pruebas

- signup_diagnostics_unit.json: 47 comprobaciones, cero fallos. Incluye
  clasificación de transporte/HTTP, redacción, body, prevención de requests
  inválidos y controlador real del formulario con Auth aislado para comprobar
  reintento y conservación de contraseña.
- supabase_auth_tests.json: 43 comprobaciones sin fallos.
- email_registration_tests.json: 21 comprobaciones sin fallos.
- signup_runtime_diagnostics.json: respuestas reales del servidor sin crear cuentas.

## Reintento manual

F5 → Registrarse → completar los cuatro campos → Crear cuenta. No hace falta
volver a pegar claves ni ejecutar de nuevo 001. Si falla, mantener el juego
abierto y revisar `[AUTH_CONFIG]`, `[AUTH_SIGNUP_REQUEST]` y `[AUTH_HTTP]` en Output.
Compartir únicamente ese diagnóstico sanitizado, nunca contraseña ni tokens.

Si aparece status 0: failure_kind identifica timeout/DNS/TLS/etc.; el timeout
actual es 15 segundos. Si aparece 400/422/429: revisar el código correspondiente.
Si aparece 500 con mensaje de base de datos: revisar Auth Logs/Postgres Logs y
education_profile. No se afirma que el trigger falle sin ese resultado. Revisar
SMTP solo si el error apunta a envío de correo o se activa confirmación.

Referencias oficiales:
https://docs.godotengine.org/en/latest/classes/class_httprequest.html
https://supabase.com/docs/guides/auth/debugging/error-codes
https://supabase.com/docs/guides/troubleshooting/database-error-saving-new-user-RU_EwB
