# Demo Windows 4.0 — preparación

Estado: preset preparado; no equivale a un ejecutable probado ni a autorización institucional.

1. Instalar las plantillas de exportación de la misma versión que el editor (4.7.2 en este proyecto).
2. Aplicar manualmente 008 y 009 después de revisar SQL y respaldar la base; no repetir 001–007.
3. Un administrador existente crea/asigna las asignaturas de cada piso. Un profesor autorizado publica actividades de acceso y de misión. No se crean ni modifican cuentas automáticamente.
4. Configurar la conexión en el computador de demo mediante `DUOCGAMES_AUTH_CONFIG` o `user://auth_config.json`, según AUTH_ARCHITECTURE.md. Usar exclusivamente URL y clave pública. Nunca incluir sesiones ni credenciales personales en la distribución.
5. Exportar en modo release con el preset `DuocGames Windows Demo`. Distribuir EXE y PCK juntos, más las licencias de los recursos utilizados. El filtro excluye configuración, fixtures, SQL y reportes.
6. Probar en otro PC: login, rol estudiante, Piso 3, pregunta publicada por docente, acceso, misión, simulación aceptada, recompensa única, cierre y continuación; mostrar panel docente y roles usando cuentas autorizadas.
7. Probar desconexión y cierre inesperado después de un guardado, reconectar con la misma cuenta, luego con otra, y comprobar conflictos entre dos dispositivos. Las pruebas automatizadas de red usan fixtures, no certifican RLS remoto.

Se incorporaron 301, 302, 304-B, 305, 306 y sala técnica de servidores, conservando 303 y la señalización 304 existente. Las puertas nuevas y la escolta del rescate tienen pruebas físicas. Varias misiones aún necesitan una puesta en escena más rica y un recorrido humano completo. Los personajes conservan el fallback procedural; falta un GLB humano autorizado con rig y animaciones.

El último diagnóstico de conexión falló por DNS del host configurado. Resolverlo y volver a verificar la sesión real antes de la demostración. No cambiar claves ni URL a ciegas para ocultar el fallo.

No distribuir como versión final hasta completar pruebas humanas, permisos de uso de recursos, privacidad y autorización institucional.
