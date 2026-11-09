# Guardado de partidas en Supabase

## Actualización 4.0 — 2 de noviembre de 2026

CloudSave incorpora un journal local persistente por proyecto y cuenta en `user://pending_campaign_v4`. Conserva operación, revisión y snapshot mediante temporal verificado, SHA-256 y respaldo `.bak`; reintenta el mismo ID tras reiniciar, evita mezclar cuentas y conserva conflictos para resolución explícita. Las operaciones confirmadas se sustituyen por un estado sin pendientes; no se borra una cola ajena.

Las pruebas `persistent_queue_v4`, `cloud_save_check` y `cloud_campaign_check` usan transporte simulado. La recuperación exige autenticar la misma cuenta y conectar; no es login offline. El último diagnóstico del servidor real falló por DNS. No se certifica sincronización real en dos equipos. Ver el informe 4.0 para evidencia y limitaciones.

## Activación remota verificada — 26 de octubre de 2026

El código del juego usa CloudSave para las partidas de cuentas reales que entran desde Login (F5). La migración 007 se aplicó mediante la conexión administrativa de Supabase al mismo proyecto configurado en el juego. Se verificaron la tabla campaign_saves, RLS y su política de lectura propia, las dos funciones propiedad de postgres con search_path vacío, ejecución autenticada sin acceso anónimo y bloqueo de INSERT/UPDATE directos. No hay usuarios sin perfil. Se conservaron las cuentas y los roles existentes.

Los pasos 1–3 ya se completaron; quedan las pruebas del juego de los pasos 4–5.

1. En el proyecto Supabase que usa `config/auth_config.json`, abrir **SQL Editor → New query**.
2. Ejecutar el archivo completo `supabase/migrations/007_cloud_campaign.sql` como postgres. Requiere las migraciones educativas 001–006 existentes; no repetir migraciones antiguas que cambian el trigger de roles.
3. Ejecutar `supabase/verify_cloud_campaign.sql` y comprobar los resultados esperados descritos al final del archivo.
4. Iniciar el juego con F5, entrar con una cuenta registrada y crear o importar una partida. Volver al menú espera la confirmación remota. Salir y volver a entrar debe recuperar la misma partida.
5. Entrar con otra cuenta: no debe aparecer el inventario ni el progreso de la primera. En otro computador, la primera cuenta debe recuperar su partida al usar el mismo proyecto Supabase.

Hasta aplicar 007, el menú informa el fallo de carga y bloquea Continuar/Nueva partida; no presenta una partida local como si estuviera sincronizada.

## Cuentas existentes

Se conserva Supabase Auth: UUID, correos, contraseñas y sesiones siguen en el sistema de autenticación existente. No hay una segunda lista de cuentas ni se requiere volver a registrarse. La migración inserta únicamente los perfiles faltantes para usuarios existentes con rol pending; conserva todos los perfiles y roles actuales. El administrador asigna los roles de las cuentas pendientes mediante el panel existente. No se convierte a todos los usuarios en estudiantes ni administradores.

## Datos de partida

`public.campaign_saves` contiene una fila por `auth.users.id`. El JSON completo incluye inventario y equipamiento, apuntes, posición, vida, checkpoints, misiones, jefes, recogibles, secretos, tarjetas, accesos, créditos, XP, mejoras, estadísticas, logros, computadores, apariencia, cosméticos, celular, horario/asistencia, progreso académico local, eventos del campus y ajustes del campus.

Los perfiles, asignaturas, preguntas e intentos evaluados conservan sus servicios/tablas existentes. El JSON de campaña no concede roles ni reemplaza los resultados académicos calculados por el servidor. Tokens y contraseñas no forman parte del JSON de partida. Configuración de conexión, la preferencia opcional de sesión y diagnósticos de desarrollo no son progreso jugable y conservan sus mecanismos separados.

RLS permite leer solo la fila propia. Las escrituras pasan por `save_campaign`, que obtiene el dueño de auth.uid(), verifica el rol y compara la revisión. El cliente no puede guardar a nombre de otro UUID. La concurrencia entre dispositivos se resuelve rechazando la escritura desactualizada, no sobrescribiendo automáticamente la otra partida.

## Carga, fallos y cierre

CloudSave permanece activo entre escenas. Las solicitudes de guardado se serializan y agrupan; el estado confirmado solo cambia cuando Supabase acusa recibo. Los reintentos conservan un ID de operación para no duplicar una escritura si se perdió su respuesta. Un error de red mantiene los cambios pendientes en memoria y los reintenta; debe mantenerse el juego abierto hasta sincronizar.

Volver al menú, cerrar sesión, reiniciar con R y cerrar la ventana esperan los cambios pendientes. El reinicio con R pausa la simulación hasta recibir confirmación; si falla, conserva la escena y ofrece opciones de recuperación. Si hay un conflicto, se puede cargar explícitamente la partida de la nube descartando los cambios pendientes. Nueva partida confirma el guardado antes de recargar y conserva la partida anterior en `previous_payload`; los autoguardados posteriores no reemplazan ese respaldo. Los ajustes se conservan al reiniciar la campaña.

La limitación histórica de ausencia de cola fue sustituida por el journal 4.0 descrito al inicio. Un cierre inesperado puede recuperar la última operación escrita, aunque una pérdida física del disco o la corrupción de ambas generaciones todavía puede causar pérdida. El guardado conserva el comportamiento de reanudar fuera de un duelo, no a mitad de un combate.

## Transición desde partidas locales

Una cuenta sin partida remota ve **IMPORTAR MI PARTIDA LOCAL ANTERIOR** si existe el archivo antiguo. La importación pide confirmar que la partida compartida de ese computador pertenece al usuario actual. Se valida/migra el JSON y se envía a la cuenta autenticada; no se elimina el original y no se importa automáticamente en cada cuenta.

Durante una partida real se desactiva el guardado independiente de inventario/papelería y credencial del Director para evitar mezclar cuentas. La ejecución directa de desarrollo sin el menú educativo, las sesiones DEV y las pruebas con rutas aisladas mantienen su comportamiento de prueba/local.

## Validación local

- `tests/cloud_save_check.gd`: 21 comprobaciones sobre aislamiento entre cuentas, snapshots, errores de red, reintentos idempotentes, concurrencia, renovación y respuestas tardías.
- `tests/cloud_campaign_check.gd`: 20 comprobaciones del campus usando la rama real de guardado cloud y transporte simulado: carga, inventario, apuntes, ajustes, nueva partida y respaldo.
- Carga de 263 scripts/recursos propios, regresiones de campaña, inventario, nueva partida y 32 comprobaciones educativas sin fallos en las ejecuciones indicadas en `reports/cloud_*.log`.

Estas pruebas usan un servidor simulado. El SQL y los permisos estructurales ya se verificaron remotamente. Quedan pendientes las pruebas de login, guardado y recuperación con cuentas reales y en dos dispositivos.

Referencias de diseño: [RLS en Supabase](https://supabase.com/docs/guides/database/postgres/row-level-security) y [funciones de PostgreSQL en Supabase](https://supabase.com/docs/guides/database/functions).

