# DuocGames 7.1 — Verificación para otro PC

Verificado el 13-11-2026 con Godot 4.7.2. Las correcciones, escenas, modelos, materiales, scripts, banco local, informes y capturas están versionados. La configuración privada de conexión, las sesiones y los guardados personales se mantienen fuera de Git. Por eso descargar el repositorio reproduce el proyecto, pero no toda la configuración y los datos personales de este equipo.

## Prueba realizada

Se confirmó directamente en GitHub el commit `66600ba62b15ab044d724dd114e3040202b746c6`. Se extrajo su contenido a una carpeta temporal independiente, sin copiar `.godot` del proyecto habitual ni `config/auth_config.json`. Se importó con Godot 4.7.2 y se ejecutó Main mediante una fixture con guardado personal y nube desactivados.

La importación detectó un defecto anterior: `materials/entrance/MAT_Piedra_Posterior.tres` tenía una marca UTF-8 BOM delante de `[gd_resource]`, que Godot rechazaba con `Parse Error: Expected '['`. Se retiró únicamente esa marca del material y de su shader asociado `piedra_estacionamiento.gdshader`, sin cambiar propiedades ni código del shader. Se aplicó la misma corrección a la copia temporal y se repitió la importación: salida 0, sin errores de scripts ni recursos. Estos dos cambios acompañan este informe en un commit posterior al anterior.

Se compararon 1.213 archivos versionados de assets, materiales, recursos, escenas, scripts y addons entre el proyecto y la copia importada. No hubo diferencias de contenido; 105 archivos sólo diferían en saltos de línea CRLF/LF. Los modelos y demás archivos binarios coincidieron por SHA-256. Se excluyeron de esa comparación los `.import` regenerables. No aparecieron fuentes, escenas o assets locales sin versionar en esas carpetas.

La prueba aislada produjo **10 PASS y 1 BLOCKED**, sin FAIL:

| Comprobación | Resultado |
|---|---|
| Material de entrada y shader cargan | PASS |
| Escena Login carga | PASS |
| Banco local con 150 preguntas | PASS |
| Main inicializa | PASS |
| Guardados personales y nube desactivados en la prueba | PASS |
| 24 bases de monitores presentes | PASS |
| 22 cuerpos de colisión de terraza presentes | PASS |
| Textos de computadores opcionales conservados | PASS |
| Autoload AuthManager resuelto desde su UID | PASS |
| Login remoto en el otro equipo | BLOCKED: requiere configuración y sesión autorizada |

El script reproducible es [portability_smoke_7_1.gd](tests/portability_smoke_7_1.gd). Es una comprobación de carga y estructura, no una nueva aprobación visual, de rendimiento o de campaña completa en otro hardware.

## Cómo abrirlo en otro equipo

1. Instalar **Godot 4.7.2**, la misma versión usada aquí.
2. Clonar el repositorio en una ruta corta, por ejemplo `C:\Proyectos\DuocGames`:

   ```powershell
   git clone https://github.com/Giannela10/Aethergate.git C:\Proyectos\DuocGames
   ```

3. Importar **`Juego/project.godot`**, no la carpeta superior. Esperar a que termine la primera importación de modelos, audio y texturas. La carpeta `.godot` se genera automáticamente; no necesita subirse a Git.
4. Para usar el mismo backend, transferir por un medio privado **`Juego/config/auth_config.json`** de este PC a la misma ubicación del nuevo proyecto. Alternativamente, completar `config/auth_config.example.json` como configuración externa siguiendo [AUTH_ARCHITECTURE.md](AUTH_ARCHITECTURE.md). No se incluyó ese archivo privado en el repositorio ni se alteraron sus valores.
5. Abrir el juego e iniciar sesión con una cuenta autorizada. Las sesiones no se transportan mediante Git. Las partidas locales tampoco; la recuperación por cuenta depende del guardado remoto y del servidor.

La extracción con Expand-Archive falló dentro de la ruta extensa de OneDrive de este equipo. La extracción a una carpeta temporal más corta sí funcionó. Se recomienda clonar en una ruta corta y evitar anidar varias carpetas del ZIP.

## Diferencias locales que no afectan al proyecto del juego

Después del commit 7.1 quedaban fuera un salto de línea en `DUOCGAMES_4_0_REPORT.md`, la eliminación local del UID de una prueba antigua cuyo script ya no estaba versionado, y ocho `.import` de capturas del informe. Se conservaron sin mezclar con esta corrección. Los `.import` de esas capturas se regeneran; no son modelos ni recursos del personaje.

Las copias de recuperación y resultados temporales permanecen locales. No se publicó configuración privada, sesiones ni partidas personales. La migración de datos personales no forma parte de descargar el código.

## Límites que permanecen

- Los recursos educativos V4 remotos devolvían `404/PGRST205` en la auditoría 7.1; descargar el repositorio no despliega migraciones ni resuelve ese bloqueo del servidor.
- La campaña completa hasta NEXO y los viajes autorizados de ascensor siguen con el alcance pendiente del [informe 7.1](FLOORS_3_TO_8_FINAL_REPORT.md).
- Un PC diferente puede dar otro rendimiento y presentación según GPU, drivers y resolución. No se certifica igualdad de FPS ni se probó físicamente otro equipo.
- Descargar el código no incluye el editor Godot ni un ejecutable exportado. Para ejecutar desde el editor basta importar el proyecto; para exportar hacen falta las plantillas de la misma versión.

## Evidencias

[Carga aislada](reports/final_7_1/portability_20261113/smoke_checks.json) · [Comparación de archivos](reports/final_7_1/portability_20261113/snapshot_hashes_normalized.json) · [Auditoría de recursos](reports/final_7_1/portability_20261113/resource_audit.json) · [Importación corregida](reports/final_7_1/portability_20261113/import_fixed.log) · [Log de Main](reports/final_7_1/portability_20261113/smoke.log).

`snapshot_hashes.json` conserva la comparación binaria inicial; las diferencias de texto allí listadas se explican y resuelven en `snapshot_hashes_normalized.json` como saltos de línea. No son archivos faltantes.
