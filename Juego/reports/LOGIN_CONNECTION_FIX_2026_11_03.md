# Revisión de conexión de inicio de sesión — 03-11-2026

La configuración real estaba en `../config/auth_config.json`, fuera de la raíz
de Godot (`Juego`). No existía `Juego/config/auth_config.json`. Se copió la
configuración existente a la ubicación esperada, ignorada por Git.

El cargador mantiene la prioridad de variable de entorno, user:// y res://.
En desarrollo también busca la configuración de la raíz del repositorio.
En una exportación puede leer `config/auth_config.json` junto al ejecutable;
el filtro de exportación existente excluye la configuración del paquete.
No se omiten configuraciones explícitas inválidas para evitar conectar con un
proyecto diferente de forma silenciosa.

La comprobación HTTPS real no alcanzó Auth: el dominio del proyecto configurado
no se resuelve. Resolve-DnsName devolvió DNS_ERROR_RCODE_NAME_ERROR para
`uykzkseqyskydbbozhqj.supabase.co`; `supabase.com` sí resolvió en el mismo equipo.
Esto no demuestra si el proyecto fue pausado, eliminado o tiene otra URL.
Se necesita comprobar el estado y Project URL en el panel de Supabase.
No se crearon usuarios, no se enviaron contraseñas y no se modificó la base remota.

El mensaje de login distingue DNS, timeout y TLS; se agregaron comprobaciones a
SupabaseAuthCheck. No se pudo ejecutar esa suite: no se encontró un ejecutable
Godot ni una instancia del editor accesible por MCP en esta sesión.
