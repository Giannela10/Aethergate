# Revisión de compatibilidad y consumo — 12 de octubre de 2026

## Cambio aplicado

El proyecto usa ahora `gl_compatibility` (OpenGL) en lugar de Forward+.
Forward+ requiere soporte de Vulkan, Direct3D 12 o Metal según la plataforma.
Compatibility permite ejecutar en más equipos con gráficos antiguos o integrados;
en escritorio sigue requiriendo soporte de OpenGL 3.3 y controladores adecuados.
El cambio requiere reiniciar el editor y volver a exportar el juego. Un ejecutable
exportado anteriormente conserva la configuración anterior.

Referencia: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html

## Datos medidos

La escena Main.tscn ocupa aproximadamente 7,81 MiB en texto y contiene:

| Tipo | Cantidad guardada |
| --- | ---: |
| MeshInstance3D | 10.004 |
| CSGBox3D / CSGCylinder3D / CSGTorus3D | 3.675 |
| CollisionShape3D | 4.552 |
| StaticBody3D | 4.343 |
| OmniLight3D | 162 |
| BoxMesh | 9.261 |
| StandardMaterial3D / ShaderMaterial | 1.422 |

Estos conteos incluyen objetos ocultos: no representan objetos dibujados simultáneamente.
El campus se instancia completo al iniciar. La prueba sin GPU encontró 25.177 nodos,
14.322 recursos y aproximadamente 246 MiB de memoria estática interna de Godot.
La carga del recurso tardó 2,13 s; carga más instanciación, 2,35 s.
El tiempo total de esa prueba incluye inicialización del complemento MCP y sus
advertencias de permisos, por lo que no sirve para comparar tiempos de arranque.

La ejecución gráfica con Compatibility abrió en una NVIDIA GTX 1650, con OpenGL 3.3.
Durante el muestreo el proceso del juego ocupó aproximadamente 925 MiB de RAM,
con un máximo observado de 946 MiB. Son valores de este equipo y este recorrido
de arranque, no requisitos mínimos ni mediciones de VRAM. El editor es un proceso
separado y ocupaba aproximadamente 2,78 GiB: no confundirlo con el juego exportado.
No se midieron FPS comparativos ni consumo de GPU en el equipo que falla.

## Qué conviene optimizar después

1. Convertir la geometría CSG terminada a mallas guardadas, conservando colisiones
   y las aberturas de escaleras y ascensores. CSG añade construcción de geometría
   en tiempo de ejecución; no basta con ocultar los objetos para evitar su carga.
2. Compartir mallas y materiales de piezas repetidas; agrupar muebles y barandas
   con MultiMesh cuando proceda, manteniendo las colisiones necesarias.
3. Separar interiores por piso y cargar por proximidad. Es necesario conservar
   la estructura visible desde fuera y los recorridos de ascensores y escaleras.
4. Medir luces y llamadas de dibujo con el perfilador antes de recortar iluminación.
   Hay 162 luces locales guardadas; no implica que todas afecten cada fotograma.

No se cambiaron las colisiones ni se ocultaron pisos durante esta revisión.
El complemento MCP se desactiva automáticamente en las exportaciones según su
script de arranque; sus advertencias al ejecutar desde el editor no prueban un
fallo del ejecutable distribuido.

## Validación y distribución

`tests/performance_startup.gd` mide carga, instanciación y memoria sin GPU:

```powershell
godot --headless --path . --script res://tests/performance_startup.gd --log-file ./tests/performance_startup.log
```

La ejecución gráfica de Main con `--rendering-method gl_compatibility` se registra
en `tests/compatibility_startup.log`. Los registros están excluidos de Git.
No hay export_presets.cfg en el proyecto: no se validó un ejecutable exportado.
Para distribuir en Windows, exportar para la arquitectura del equipo y enviar
el .exe y el .pck juntos si el paquete no está incrustado.
Para confirmar la causa del fallo original se necesita el mensaje de error del
equipo afectado, sus características y saber si se está abriendo una exportación
o el proyecto en Godot.
