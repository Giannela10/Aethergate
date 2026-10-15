# Revisión de DuocGames — 8 de octubre de 2026

> Registro histórico. Consulta [GUIA.md](GUIA.md) para las correcciones y pendientes de la revisión actual, y [CAMPANA.md](CAMPANA.md) para la campaña, pausa y guardado incorporados después de este documento.

## Estado observado

El proyecto inicia en Godot 4.7.2 y permite explorar un campus de ocho pisos. Hay un duelo de preguntas en la biblioteca, un enemigo con combate y lanzamientos en Punto Estudiantil, artículos de papelería con apuntes persistentes, puertas, guardias y ascensores. La geometría combina escenas guardadas y scripts de construcción.

Se conservaron los cambios del usuario que ya estaban presentes en Main.tscn, materiales y archivos de importación. La revisión no reconstruye el campus ni cambia los huecos arquitectónicos intencionales.

## Correcciones implementadas

| Problema | Cambio |
| --- | --- |
| Otro clic después de ordenar el último archivo accedía fuera del arreglo | El minijuego termina una sola vez y deja de aceptar respuestas |
| Un temporizador de éxito anterior podía cerrar otro minijuego | Cada apertura tiene un identificador de sesión |
| Identificadores de minijuego inválidos causaban acceso fuera de rango | Se valida el identificador antes de abrir |
| Los reinicios agregaban controles repetidos | Las acciones solo reciben eventos que aún no contienen |
| Soltar armas siempre las colocaba a altura cero | Se busca el suelo debajo del punto de caída conservando el piso |
| Golpes y asistencia de puntería atravesaban paredes o alcanzaban otros pisos | Se verifica altura y línea de visión |
| Enemigos genéricos detectaban y golpeaban entre pisos | Se limita la diferencia de altura y se comprueba la obstrucción del golpe |
| Un golpe pendiente podía conectar después de morir o abrir una ventana | Se cancela si el jugador está muerto u ocupado |
| La cámara podía atravesar paredes | Se acorta la distancia cuando hay una superficie entre la cámara y el personaje |
| Los clics fuera de las ventanas podían capturar el ratón mientras el jugador estaba ocupado | La cámara ignora la entrada durante interacciones y después de morir |
| R podía reiniciar mientras se escribían apuntes | El gestor ignora controles de reinicio durante ventanas abiertas |
| El ascensor recibía controles con inventario o papelería abiertos | No acepta interacción del jugador ocupado |
| La muerte podía dejar inventario o papelería abiertos | Se cierran y se muestra el mensaje de reinicio con ratón visible |
| Mensajes antiguos podían ocultar un mensaje reciente | Se comprueba qué mensaje corresponde al temporizador |
| El HUD anunciaba tres computadores inexistentes en el modo actual | Cuenta los computadores reales y muestra orientación de exploración cuando no hay ninguno |
| El enemigo de Punto Estudiantil no actualizaba el contador | Emite su derrota y el gestor conecta la señal |
| El HUD decía puños aunque había un artículo de papelería equipado | Muestra el nombre del artículo y la tecla para usarlo |
| Valores inválidos en cantidades guardadas podían fallar al convertirse | Se validan tipos y se limitan cantidades al cargar |
| Una caída fuera del escenario no finalizaba | Por debajo de −25 m el jugador muere y puede reiniciar |
| El jugador podía levantarse debajo de un techo bajo | Se comprueba el volumen de la cápsula antes de dejar de agacharse |
| Character.tscn usaba una ruta con mayúsculas incorrectas | Referencia character.gd con el nombre real |
| El minijuego de contraseña solo tenía botones en pantalla | Acepta números, teclado numérico, borrar y Enter |
| Interfaz recortada al reducir la ventana | Se define resolución base de 1152×648 y escalado de interfaz |
| Barra de vida demasiado ancha por el texto de ayuda | Mantiene su ancho de 280 píxeles |
| Pruebas de suelo incluían superficies ocultas retiradas intencionalmente | Comprueban solo los parches visibles |
| Las pruebas del auditorio recorrían posiciones de rampas antiguas | Siguen el centro de los pasillos actuales |

La ventana se identifica como DuocGames y conserva la carpeta anterior de inventario y apuntes.

## Verificación

- Carga de todos los scripts de `scripts/` y de Main.tscn y Character.tscn.
- Carga del material de piedra: el error mostrado en la consola anterior no se reproduce con el archivo actual.
- Pruebas de finalización única de archivos, identificadores inválidos, temporizadores entre sesiones y contraseña con teclado y cero inicial.
- Pruebas físicas de golpes delante del jugador, paredes, separación entre pisos y caída/recogida de armas en un piso a 12 m.
- Comprobación de que registrar controles dos veces no aumenta los eventos.
- Siete recorridos de biblioteca y tres de auditorio.
- Revisión visual inicial y ejecución del campus.

Los resultados detallados de las pruebas se escriben en tests/*.log, excluidos de Git. Las pruebas de rutas existentes imprimen resultados; su código de salida por sí solo no indica que todos los recorridos pasaron.

## Qué falta y qué conviene mejorar

| Prioridad | Hallazgo | Mejora concreta |
| --- | --- | --- |
| Alta | No hay una misión global que conecte los lugares y desafíos | Definir inicio, objetivos por zona y condición de victoria; mostrar el objetivo actual y orientar al próximo lugar |
| Alta | R y salir de la aplicación borran progreso de tareas, vida y derrotas; solo se guardan papelería y apuntes | Añadir guardado de partida versionado, continuar/nueva partida y puntos de control seguros |
| Alta | Esc libera el ratón, pero el mundo sigue activo | Añadir menú de pausa con continuar, controles, ajustes y volver al inicio |
| Media | Recorrer ocho pisos carece de mapa y señalización de objetivos en pantalla | Añadir mapa por piso, ubicación actual y señales de biblioteca, papelería y Punto Estudiantil |
| Media | El HUD presenta muchos controles permanentemente | Mostrar una ayuda breve y permitir desplegar la lista completa; unificar estilos de ventanas y avisos |
| Media | Enemigos usan persecución directa y pueden atascarse con mobiliario | Incorporar navegación por zonas y recuperación cuando no avanzan |
| Media | No se encontraron archivos de audio del juego | Añadir pasos, interacción, golpes, ascensor y ambiente con controles de volumen |
| Media | Los pisos ya están agrupados y los scripts separados, pero el campus sigue guardado en una escena grande | Extraer escenas por nivel y medir si conviene cargarlas por sectores |
| Media | No hay medición de rendimiento ni configuración gráfica propia | Perfilar el campus y el combate en equipos objetivo; ajustar luces, geometría y visibilidad según resultados |
| Media | Persistencia solo verifica cantidades y no ofrece recuperación del archivo | Guardado atómico, copia de respaldo y aviso si falla la escritura |
| Media | No hay configuración de exportación guardada | Preparar export_presets.cfg, comprobar ejecución fuera del editor y revisar los complementos incluidos en la distribución |
| Baja | Existen comentarios antiguos con codificación dañada y controladores alternativos | Limpiar comentarios y documentar qué escenas utilizan cada controlador antes de retirar archivos |

Estas tareas requieren decisiones de diseño o verificaciones adicionales; no se presentan como implementadas. No se ha comprobado cada habitación, cada viaje de ascensor, una partida completa del duelo literario ni una exportación final. El ajuste de cámara usa un rayo central: conviene comprobar esquinas y superficies muy próximas para decidir si necesita una comprobación volumétrica.

## Orden por pisos

Se ordenaron los nueve niveles (−1 y 1–8) en `Main.tscn`. Cada piso tiene número, etiqueta, altura y descripción en el Inspector; losas, paredes, escaleras, barandas, luces, vestíbulos y puertas fijas están dentro del nivel al que pertenecen. Las cabinas y estructuras que abarcan todo el edificio se guardan en `SistemasCompartidos`.

Los 55 scripts originales se distribuyeron entre `scripts/pisos`, `scripts/compartidos`, `scripts/exterior`, `scripts/juego` y `tests`, conservando sus UID. Hay una ficha `INFORMACION.md` por piso y un botón de actualización en `HerramientasEdicion/InformacionPisos`. Las herramientas manuales de barandas, losas y acabados ahora guardan sus resultados dentro del piso correspondiente.

La reorganización comprobó 23.024 nodos para conservar su transformación y apariencia. Pasaron las verificaciones de etiquetas y referencias trasladadas, los 20 recorridos de escaleras, los tres ascensores, siete accesos a biblioteca, tres al auditorio y las pruebas de jugabilidad.
