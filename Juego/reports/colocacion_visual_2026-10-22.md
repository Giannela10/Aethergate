# Colocación visual y cámara — 22 de octubre de 2026

Se revisó la captura de las 17:24 y se corrigieron dos causas comprobables: recogibles colocados con una altura/rotación fija y cámara que solo comprobaba una línea contra las paredes y barandas.

## Cambios

- Los recogibles de campaña se apoyan según los límites reales de sus mallas. La separación del extremo inferior respecto al suelo es de 1,5 cm, evitando la altura fija anterior.
- Se comprueba el apoyo del centro y las cuatro esquinas de la huella de cada recogible, además de una caja con el tamaño real del modelo contra la arquitectura. Esto evita recolocar un objeto largo sobre el borde de una escalera o dentro de una pared aunque su origen estuviera en un lugar libre.
- Las sillas recogibles conservan orientación vertical. Los objetos alargados descansan de lado.
- La cámara reserva una esfera de 22 cm alrededor de su posición al acercarse a obstáculos. Se conserva también la comprobación central como respaldo. Una arista de baranda que no corta el rayo central ahora puede detectarse por su volumen.
- Cuando el obstáculo obliga a acercar la cámara a menos de 1,2 m del pivote del jugador, se oculta temporalmente el modelo del personaje para que su espalda no llene la pantalla. Se vuelve a mostrar al recuperar espacio.

No se cambiaron IDs, recompensas o reglas de recogida, ni se modificó Main.tscn. No se movieron NPC, bosses ni la estructura del edificio.

## Verificación

`placement_visual_check.gd` comprobó **92 recogibles de campaña** en la escena completa, sin fallos de apoyo, altura o intersección con arquitectura. El detalle por ID está en [placement_visual_check.json](placement_visual_check.json).

`camera_obstruction_check.gd` pasó cinco comprobaciones: pared frontal, una arista que el rayo central no detecta pero la esfera sí, recuperación de distancia en espacio abierto y consulta sin desplazamiento.

Se capturó el descanso de emergencia del piso 1 desde tres ángulos, usando la física normal del jugador. La comprobación también fuerza temporalmente distancia corta para verificar ocultación y recuperación del modelo. Resultados en [placement_stairs_visual_check.json](placement_stairs_visual_check.json).

Capturas:

- [Objeto alargado apoyado](placement_grounded_stick.png)
- [Silla recogible de pie](placement_grounded_chair.png)
- [Escalera, ángulo 1](placement_stairs_view_0.png)
- [Escalera, ángulo 2](placement_stairs_view_1.png)
- [Escalera, ángulo 3](placement_stairs_view_2.png)

También se repitieron las suites afectadas de carga de scripts, campaña, inventario, gameplay, primera misión, guardado/lectura, nueva partida, organización de pisos, integración educativa, nexo, bosses académicos, pisos superiores y gameplay con renderizado. Los resultados individuales están en `detailed_validation.json` y los registros `detail_*.log`.

## Alcance pendiente

Esta corrección cubre recogibles generados por la campaña y colisión/encuadre de cámara. No certifica cada pieza del mobiliario estático, todas las uniones de barandas, ni una revisión estética completa del edificio. Las pruebas previas de recorridos demostraban transitabilidad, pero no bastaban para afirmar que todos los elementos estaban bien colocados visualmente.

Para ver los cambios, detener la ejecución actual y ejecutar de nuevo el proyecto desde sus archivos actualizados.
