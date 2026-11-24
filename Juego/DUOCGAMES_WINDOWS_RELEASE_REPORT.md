# DuocGames 8.0 para Windows

24 de noviembre de 2026 · Proyecto `Juego/project.godot` · Base Git `fb0a8b0`

## Archivos de entrega

| Archivo desde la raíz del repositorio | Bytes |
| --- | ---: |
| `Instalar DuocGames/DuocGames_Setup.exe` | 125 525 663 |
| `dist/windows/DuocGames.exe` | 109 268 480 |
| `dist/windows/DuocGames.pck` | 105 367 956 |
| `dist/DuocGames_Windows_x64_Portable.zip` | 135 836 942 |
| `Juego/DuocGames.iss` | Script de compilación |

SHA-256 del instalador: `F7D637D4E162D7A0DB84227783DD9ABE22E0C470413C262FD0543AAD79761261`.

Entrega únicamente `DuocGames_Setup.exe` a los profesores. El asistente en español permite elegir carpeta e instalar para el usuario actual o para todos los usuarios. La segunda opción requiere elevación y permite instalar en Program Files. Crea los accesos del escritorio y del menú Inicio, incluye el desinstalador y ofrece ejecutar al finalizar. El instalador está sin firma digital. Para usar el ZIP, extrae ambos archivos a la misma carpeta y abre el EXE. Se requiere Windows x64 y una GPU con controlador compatible con OpenGL 3.3. El juego incluye el runtime de Godot. El inicio de sesión y las funciones remotas requieren Internet.

## Exportación y recuperación

- Godot estándar `4.7.2.stable.official.ed1daf0bf`. Plantillas oficiales de la misma versión, `windows_release_x86_64.exe` y plantilla de depuración x64 instalada para que Godot valide el preset. El TPZ se verificó contra el SHA-256 oficial `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`. [Plantillas oficiales de Godot 4.7.2](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable)
- Preset de producción `DuocGames Windows`, Windows Desktop x86_64, PCK separado, escena `res://scenes/education/Login.tscn`, renderizador GL Compatibility y configuración gráfica existente. El icono usa un monograma DG con el azul y amarillo del menú. Se generó un ICO de seis tamaños para el instalador y el juego.
- Se añadió al PCK la configuración pública de autenticación, el banco de 150 preguntas de práctica y el JSON de configuración de personajes. Se excluyeron el banco con soluciones de depuración, los bancos de autoría, archivos privados locales, pruebas, informes, migraciones y complementos de desarrollo. La inspección del PCK comprobó la ausencia del archivo privado histórico y del autoload del MCP.
- La primera carga nativa del campus reveló errores de compilación en ocho scripts que referenciaban `EditorInterface` desde funciones de previsualización. Esas funciones obtienen ahora la cámara solo cuando existe el editor. La segunda carga nativa completó `Main.tscn` sin los errores de scripts anteriores. El ajuste se limita a las herramientas de previsualización.
- Instalador compilado con Inno Setup 7.1.1 a partir de `Juego/DuocGames.iss`. Contiene el EXE y el PCK, con compresión LZMA2. [Inno Setup](https://jrsoftware.org/inno-setup)
- Git estaba limpio al inicio. La recuperación local `recovery/duocgames-windows-fb0a8b0.zip` contiene los archivos versionados del juego y el archivo de exclusiones de ese commit. Ese respaldo es de uso interno. Git excluye los binarios de entrega, `dist/` y `recovery/`.

## Resultados de pruebas

| Prueba | Resultado y alcance |
| --- | --- |
| Arranque portable fuera del editor | Ventana DuocGames y pantalla de inicio visibles. El log confirma carga de la imagen, el tema y la música del menú. OpenGL 3.3 y salida WASAPI se inicializaron con la GTX 1050 del equipo. |
| Campus en el EXE nativo | Se probó una copia de los binarios definitivos con `override.cfg` apuntando a `Main.tscn`. Cargó el campus en dos arranques headless y mostró gráficamente su menú local con el protagonista humano, fondo y opciones de juego. El modo local de escena generó un guardado válido en `user://`. El instalador y el ZIP usan el arranque normal en Login. |
| Movimiento, cámara y guardado local | Un arnés de Godot 4.7.2 montó el PCK final y verificó que el campus quedó listo, que el protagonista se desplazó al simular movimiento, que había cámara 3D y que la campaña restauró y volvió a escribir una partida local de prueba. |
| Práctica y paneles | En el mismo arnés se cargaron las escenas de menú estudiante, panel docente y panel administrador, y se respondió una pregunta del banco de 150. El resultado quedó marcado como práctica local sin verificación remota. |
| Instalación y desinstalación | El instalador definitivo completó dos instalaciones y dos desinstalaciones por usuario en una carpeta aislada del mismo Windows. Se verificaron los SHA-256 del EXE y PCK instalados y los destinos de ambos accesos directos. El EXE instalado abrió Login antes y después de reinstalar. La partida local de prueba y un archivo de control conservaron sus SHA-256. |
| Pendiente de recorrido manual | Doble clic desde el escritorio, nueva partida y continuar desde el menú autenticado, personalización, animación en movimiento, carrera, salto, nueve pisos, ascensores, escaleras, interacción con docentes, combate, recogida, inventario, misión completa, campaña NEXO, sonido audible y ajustes gráficos. Faltan también Program Files y un Windows limpio. |

El proyecto fuente en `Juego` también cargó Login desde el binario de desarrollo después de los cambios. Godot MCP Toolkit se inicializó durante la exportación, registrando la ruta `Juego`. La llamada MCP de la sesión estaba asociada a la carpeta raíz `Aethergate` y devolvió `AUTH_FAILED`. Las comprobaciones fuera del editor se hicieron con procesos separados. Las ejecuciones headless bajo sandbox informaron que no podían leer el almacén de certificados del sistema. El arranque gráfico autorizado sí lo cargó. El arnés de desarrollo avisó que el banco exclusivo de depuración no estaba en el PCK de producción, tal como indica el preset.

Las ejecuciones gráficas posteriores reutilizando el perfil de prueba registraron tres errores genéricos en la inicialización de shaders GLES3. El EXE instalado abrió Login y salió con código 0 en ambos ciclos. La prueba adicional de entrada Windows dirigida al menú local del campus no logró salir de ese menú y agotó el plazo de cierre del arnés. El desplazamiento horizontal solo quedó confirmado en la prueba del PCK con entrada simulada por Godot. Queda pendiente el recorrido interactivo y el renderizado del juego en otro equipo y controlador.

## Supabase y sesiones

El PCK contiene una URL HTTPS de Supabase y una clave `sb_publishable_` del cliente. La inspección confirmó que el JSON público contiene únicamente esos dos campos. La clave pública está diseñada para distribuirse en clientes. Los permisos dependen de RLS, roles y funciones del servidor. Su aplicación efectiva requiere pruebas con cuentas autorizadas. [Claves de API de Supabase](https://supabase.com/docs/guides/getting-started/api-keys)

Las consultas del 24 de noviembre de 2026 usaron únicamente GET con la clave pública y `limit=0` en tablas:

| Recurso | Resultado |
| --- | --- |
| Auth settings por HTTPS | `200`, correo habilitado, Google deshabilitado |
| `profiles` | `401 / 42501` sin sesión |
| `learning_activities` | `404 / PGRST205` |
| `learning_attempts` | `404 / PGRST205` |
| `learning_access` | `404 / PGRST205` |

Los tres recursos V4 siguen sin aparecer en la caché de esquema de la API consultada. El campus de producción mantiene sus llamadas remotas y la práctica local existente. El alcance de Capstone que depende de publicación, evaluación o progreso V4 sigue bloqueado hasta que el responsable de Supabase confirme la migración 008, los recursos expuestos y la caché de PostgREST. No se aplicó SQL ni se modificaron datos remotos.

No se proporcionó una cuenta autorizada de prueba. Quedan pendientes el flujo completo de ingreso y salida, roles y RLS, preguntas remotas, paneles autenticados, guardado remoto y renovación. El cliente conserva el retorno OAuth existente al localhost de la aplicación. El flujo y la lista de redirecciones del servidor quedan por probar cuando se habilite el proveedor.

## Guardado y revalidación

Se conservó la ruta personalizada `%APPDATA%\Piso y Personaje Basico` para que el juego siga encontrando el perfil existente. Los datos modificables, las opciones y las sesiones recordadas usan `user://`. La campaña normal autenticada usa Supabase por cuenta y mantiene un diario local para escrituras pendientes. La prueba local de escena no certifica ese flujo remoto. El instalador actualiza y desinstala sus archivos de aplicación y accesos directos. No incluye instrucciones para borrar el perfil de usuario.

Para recompilar desde la raíz con las plantillas exactas instaladas:

```powershell
New-Item -ItemType Directory -Force dist/windows
$output = Join-Path (Resolve-Path dist/windows).Path 'DuocGames.exe'
& $godotConsole --headless --path Juego --export-release 'DuocGames Windows' $output
& $innoISCC Juego/DuocGames.iss
```

`$godotConsole` y `$innoISCC` son las rutas a los ejecutables de Godot consola e Inno Setup. Antes de presentar la campaña como validada de extremo a extremo, repetir el recorrido manual desde el acceso directo en un Windows x64 limpio y verificar los flujos remotos con cuentas de prueba autorizadas para estudiante, docente y administrador. Para el ciclo de guardado, usar una partida de prueba, cambiar posición o inventario, cerrar, continuar y comparar el estado después de reinstalar.
