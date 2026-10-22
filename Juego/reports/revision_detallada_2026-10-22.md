# Revisión detallada — 22 de octubre de 2026

Esta revisión amplía la primera comprobación y parte del error de ejecución mostrado en la captura del usuario. Los resultados actuales por suite están en [detailed_validation.json](detailed_validation.json), con registros `detail_<suite>.log`. Las capturas `detail_*.png` corresponden a renderizado real con Compatibility/OpenGL en la GTX 1050 del equipo.

## Correcciones del juego

1. **Error Nil → float en campus_polish.gd.** Los objetivos académicos destructibles también pertenecen al grupo `enemy`, pero no tienen `health`. El indicador de daño asumía que todos los miembros tenían salud y detenía la ejecución. Ahora verifica que el nodo sea espacial y su salud sea numérica antes de procesarlo. También elimina registros de actores que ya no pertenecen al grupo. La regresión usa un objetivo académico real y comprueba números de daño, ausencia de duplicados y limpieza del registro: seis comprobaciones.
2. **Errores JSON secundarios en solicitudes HTTP.** Una respuesta vacía o no JSON producía un error adicional de análisis, ocultando el diagnóstico de transporte. El cliente ahora acepta cuerpo vacío o inválido sin generar ese error y conserva el resultado HTTP/transporte. Se probaron ocho casos de respuesta y clasificación.
3. **Textos encima del inventario.** La captura con renderizado mostró objetivos y avisos de campaña superpuestos a la mochila. Ahora el HUD de campaña se oculta durante ventanas modales, introducciones y estados ocupados del jugador. Se comprueba visualmente que desaparezca al abrir inventario/pausa y regrese al continuar.

No se modificó la geometría de Main.tscn ni se redistribuyeron muebles, NPC o bosses.

## Configuración y conexión Supabase

El juego cargó automáticamente `res://config/auth_config.json`. La prueba GET ejecutada con el cliente real de Godot devolvió **HTTP 200** para `/auth/v1/settings`; el proveedor de correo está habilitado. Las siete consultas anónimas de tablas devolvieron **HTTP 401**, con errores de permisos. Esto no equivale a haber verificado acceso con un usuario autenticado.

No se crearon cuentas ni se modificaron datos remotos. Quedan pendientes login real, confirmación de correo, renovación de sesión, RPC y políticas RLS con cuentas de alumno, docente y administrador. Las pruebas de roles y registro incluidas usan fixtures.

La prueba HTTP usa tiempo real: ejecutar redes con `--fixed-fps` acelera el reloj simulado y puede hacer vencer el timeout antes de recibir la respuesta. El ejecutor nuevo evita esa combinación.

## Cobertura automatizada

Se ejecutaron 41 suites de carga, lógica e integración, más dos comprobaciones gráficas. Consultar el JSON para el resultado final individual; una prueba omitida no se marca como aprobada. Se revisan errores de ejecución y fallos reportados, además del código de salida.

| Área | Cobertura |
| --- | --- |
| Recursos | 261 scripts/recursos propios y 43 escenas cargadas |
| Campaña | Primera misión, progresión, guardado/lectura, nueva partida, inventario y combate |
| Educación | Integración con el campus: 18 comprobaciones; horario: 27; roles y formularios con fixtures |
| Bosses | Director, Chef, nexo, expansión académica: 320 comprobaciones y pisos superiores: 122 |
| Campus | Teléfono, personalización, interacciones contextuales, organización y balance |
| Subterráneo | 20 recorridos, abertura al nivel inferior y nueve puertas de emergencia |
| Ascensores | Tres recorridos de ascensores incluyendo subida y descenso al −1 |
| Piso 8 | 27 recorridos |
| Biblioteca | 21 barridos de cápsula y 231 muestras de suelo; seis entradas a salas y acceso principal con movimiento físico; 15 comprobaciones de parches de suelo |
| Coordinación | 11 recorridos y 121 muestras de suelo; sala de reuniones: 13 recorridos y 143 muestras |
| Auditorio | Tres recorridos físicos |
| Capilla | Diez recorridos y 77 muestras de suelo |
| Emergencia | 18 recorridos en nueve niveles |

## Pruebas que necesitaron actualización

- Biblioteca tenía expectativas antiguas de 19 computadores. La escena actual conserva 13: Puesto01–03 y Puesto10–19. Se comprobaron sus identidades, ratones y orientación por estación, sin depender del índice de un arreglo tras eliminar estaciones. La ruta antigua atravesaba una estantería; mediciones con cápsula verificaron el pasillo actual en x=−78,5.
- Coordinación tenía rutas que atravesaban centros de sillas y la mampara de la sala de reuniones añadida posteriormente. Se comprueban pasillos entre escritorios y se conserva la prueba separada de la entrada automática y circulación interior de reuniones.
- Pisos superiores esperaba nueve duelos globales, cifra anterior a la expansión académica. Ahora comprueba todos los bosses configurados y que las identidades de los duelos sean únicas.
- Las fixtures antiguas de biblioteca y auditorio eliminaban el jugador sin retirar la campaña que lo usaba en su arranque diferido. Se aislaron igual que las pruebas existentes de subterráneo y ascensores.
- La integración educativa antes se omitía si encontraba una sesión personal. Ahora ejecuta la lógica de producción con almacenamiento de sesión en memoria, sin restaurar ni borrar la sesión del usuario.

## Verificación gráfica

Se capturaron y revisaron login, registro, registro a 800×600, panel docente, panel administrador, biblioteca y coordinación. Los paneles largos tienen desplazamiento vertical. Las imágenes generales de interiores usan una cámara de diagnóstico con pisos/techos superiores ocultos solo en memoria.

La segunda comprobación carga el campus real con persistencia desactivada y verifica movimiento mediante entrada y física reales, supervivencia, apertura/cierre de mochila, pausa/continuar, mapa y teléfono. Incluye comprobación del HUD al abrir/cerrar ventanas. Las capturas están en `detail_gameplay_*.png`.

## Límites y pendientes

- Esta cobertura no certifica cada metro de cada habitación, una campaña completa jugada manualmente, balance subjetivo, audio percibido ni rendimiento estable en todos los equipos.
- El techo de coordinación sigue a altura inferior de aproximadamente 4,94 m, mientras el pasillo está a 11,56 m. La prueba identifica una restricción previa con la estructura del auditorio y la registra como pendiente; no se presentó como corregida.
- No se validaron Google OAuth, SMTP/correo real ni una exportación final. No existe `export_presets.cfg` en el proyecto revisado.
- La captura del usuario muestra `campus_polish.gd(*)` con una edición sin guardar que contiene `DS`. Ese error de sintaxis no está en el archivo del disco. Detener la ejecución y recargar los scripts externos desde disco antes de volver a ejecutar; guardar el buffer antiguo encima de estos cambios puede reintroducir el problema.

## Repetir las comprobaciones

Desde `Juego/`, pasando la ruta del ejecutable de Godot:

```powershell
node tests/detailed_validation.cjs "C:\ruta\Godot_v4.7.2-stable_win64.exe"
node tests/detailed_validation.cjs "C:\ruta\Godot_v4.7.2-stable_win64.exe" "visual_detail_check,rendered_gameplay_check"
```

La primera orden ejecuta las 41 suites sin interfaz gráfica. La segunda ejecuta las dos comprobaciones con renderizado y actualiza sus entradas en el mismo informe.
