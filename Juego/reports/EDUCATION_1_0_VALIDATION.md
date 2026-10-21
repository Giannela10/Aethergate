# Validación · Educativo 1.0 · 20-10-2026

Godot 4.7.2 instalado, Windows. Se usó godot-mcp-toolkit para inspeccionar
Main, registrar autoloads, configurar el inicio, compilar scripts, abrir Login,
inspeccionar rutas de UI, ejecutar acciones de roles y capturar la pantalla.
Las regresiones de lógica y geometría se ejecutaron headless con el ejecutable
principal, procesos ocultos y fixtures aisladas. El lanzador console.exe local
falló con error 193; no se confundió ese fallo con un fallo del juego.

## Resultados

| Comprobación | Evidencia | Resultado |
|---|---|---|
| PKCE S256, parser callback, roles DEV, DTO sin clave, respuestas, CRUD demo, migración, save/load | education_1_0_tests.json | 32 checks, 0 fallos |
| Guardia real del campus, rutas de llegada, botones compartidos, respuestas sin penalización, escritura de campaña, persistencia, cierre de modal | education_integration_tests.json | 18 checks, 0 fallos |
| Campaña | tests/edu1_campaign_regression.log | PASS, exit 0 |
| Inventario | tests/edu1_inventory_regression.log | PASS, exit 0 |
| Jugabilidad | tests/edu1_gameplay_regression.log | PASS, exit 0 |
| Lectura de guardados inválidos | tests/edu1_guardado_lectura.log | PASS, exit 0; avisos esperados por fixtures corruptas |
| Nueva partida y reinicio | tests/edu1_nueva_partida.log | PASS, exit 0 |
| Celular | tests/edu1_student_phone.log | 31 checks, 0 fallos |
| Horario académico | tests/edu1_academic_schedule.log | 27 checks, 0 fallos |
| Campus vivo/estado | tests/edu1_campus_vivo.log | 52 checks, 0 fallos |
| Director | tests/edu1_director_informatica_boss.log | 0 fallos, exit 0 |
| NEXO | tests/edu1_nexo_final.log | 111 checks, 0 fallos |
| Organización de pisos | tests/edu1_organizacion_pisos.log | 596 rutas válidas, exit 0 |
| Chef | tests/edu1_chef.log | PASS, exit 0 |
| Escaleras/acceso subterráneo | tests/edu1_basement.log | 20 rutas, 9 puertas, sin fallos |
| Ascensores | tests/edu1_elevators.log | 3 ascensores, sin fallos |
| Bosses académicos | tests/edu1_academic_bosses.log | 320 assertions, 0 fallos; la escena no termina por sí sola y se detuvo al límite de 120 s después de emitir resultado |

La fixture de integración coloca al jugador en las tres zonas de llegada; no
equivale a conducir manualmente el ascensor con un mando hasta cada entrada.
Las fixtures físicas existentes sí recorren escaleras y cabinas con cápsulas.
Las pruebas de saves anteriores verifican compatibilidad de datos y Nueva
partida con archivos aislados; no se sobrescribió deliberadamente una partida
personal para probar Continue.

## No verificado externamente

- Google real, consentimiento, redirect allowlist y code exchange contra Supabase.
- Refresh token real entre reinicios, revocación remota y cambios de rol reales.
- Ejecución de migración SQL, RLS/RPC en PostgreSQL y tres cuentas reales.
- Exportación Release final y contenido del PCK; filtro de export compilado.
- Mando físico, avatar real y recorrido humano completo del Piso 3.
- Sincronización offline: no implementada; los intentos offline quedan locales.

No hay PASS de OAuth ni de RLS desplegado. Las nuevas funciones SQL deben
validarse en un proyecto Supabase de desarrollo antes de producción.
