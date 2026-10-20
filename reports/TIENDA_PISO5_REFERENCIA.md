# Negocio del piso 5 — foto 09.55.43 del 19-10-2026

## Ubicación vigente: junto a escalera de emergencia

Carteles elevados a pedido del usuario: identificación CAFETERÍA +1,30 m, letrero circular y carta +1,33 m efectivos, cartel suspendido del piso 5 +2 m. Se conserva la ubicación del negocio y no se alteran colisiones ni accesos. El gabinete DEA permanece en su lugar.

Corrección de colocación posterior: identificación, carta y marca circular se alinean en una franja frontal a Y=54,05, sobre el cierre de madera. La carta mira hacia el pasillo y la marca circular conserva proporción redonda, separada del lateral que la ocultaba. Se ajustó también la profundidad de la carta para que su marco no tape la imagen.

Ampliación aprobada por el usuario: se conserva el emplazamiento junto a emergencia y se aumenta el ancho un 35%, el fondo un 18% y la altura de los muebles aproximadamente un 12%. La superficie del montaje aumenta aproximadamente un 59%. Crece hacia la izquierda y delante, anclando el borde junto a la salida. Centro actualizado: `(-28.751, 47.975, -144.517)`; escala `(1.35, 0.95, 1.18)`.

Se cerraron el fondo, el lateral izquierdo, el lateral derecho y la franja superior hasta el techo, manteniendo abierto el frente de atención. Los cierres tienen colisión. Las bandejas y tuberías se recortaron al ancho interior. Datos en `tienda_piso5_ampliacion.json`; captura de esta ampliación: `tienda_piso5_ampliado.png`.

Validación posterior a la ampliación: **26 comprobaciones físicas sin fallos**, incluidas cuatro pruebas de cierre de paredes, acceso al mostrador, apertura de la puerta de emergencia y paso hacia la escalera. Resultado actualizado en `tienda_piso5_emergencia_pruebas.json`.

La ubicación anterior junto a la escalera central fue rechazada por el usuario. Se trasladó el mismo negocio a `(-27.4, 47.975, -145.3)`, mirando hacia +Z. Queda inmediatamente al oeste del acceso `Piso5/EscaleraEmergencia/PuertaPiso5`; la puerta verde se ve a su derecha al aproximarse desde el pasillo. Se abrió la parte del tabique del antiguo nicho que interfería y se creó un lateral ajustado al negocio. Se conserva la puerta, sus marcos, la apertura y el recorrido de escalera de emergencia.

Pasaron **22 comprobaciones físicas**, incluidas apertura de esa puerta y cuatro posiciones con cápsula a través de su acceso y descanso. Resultado vigente: `tienda_piso5_emergencia_pruebas.json`. Captura vigente: [tienda_piso5_emergencia.png](tienda_piso5_emergencia.png). La ruta de la tienda y sus equipos se conservan. Falta recorrido humano.

## Historial: primera ubicación, sustituida

Se ajustó el negocio existente `Piso5/TiendaEsquinaPiso5` según la nueva fotografía. Se conserva su ruta y el nicho existente; no se creó otro negocio.

- Posición final: `(-28.2, 47.975, -135.3)`. Se desplazó 1,3 m hacia el pasillo para alinear el lateral con la pared.
- Giro: 90° alrededor de Y. El mostrador mira hacia +X, al jugador que se aproxima por el pasillo longitudinal. La pared queda al lado −Z y la escalera al lado +Z.
- Escala final: `(1.0, 0.85, 1.0)`, para reducir el volumen del montaje anterior.
- Mostrador frontal negro más corto, retorno lateral y colisiones ajustadas a sus dimensiones. Se conservan ambas vitrinas y sus productos.
- Cubierta transparente de perfiles negros, mampara posterior con esmerilado y revestimiento lateral claro.
- Refrigerador azul trasladado al lado derecho; una cafetera negra visible, congelador blanco y cartelería del mismo negocio ya importada en el proyecto.
- Carta y letrero circular, gabinete DEA, plano del piso y cara posterior legible del cartel 5.
- Se conserva el pavimento común oscuro. No se cambiaron computadores, actividades, misiones ni guardado.

Herramienta de edición manual: `scripts/pisos/piso_5/ajuste_tienda_foto_octubre.gd`. La geometría queda guardada en Main.tscn; no se reconstruye al jugar.

## Validación ejecutada

Mediante godot-mcp-toolkit se cargó Main y se ejecutaron **16 comprobaciones**, sin fallos: acceso frontal, suelo delante del local, colisión del mostrador y cápsulas de paso entre el negocio y la escalera. Resultado en `tienda_piso5_acceso_foto.json`. El test existente `tests/tienda_piso5_acceso.gd` se actualizó a la nueva posición, orientación y anchura del mostrador.

Se revisó la captura [tienda_piso5_095543.png](tienda_piso5_095543.png). Es una adaptación estilizada de la foto; falta recorrido humano para evaluar escala y circulación desde la cámara habitual.
