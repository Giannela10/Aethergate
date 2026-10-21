# Costados del campus según fotografías — 19-10-2026

Referencias inspeccionadas: las cuatro fotos `WhatsApp Image 2026-10-19 at 08.46.14.jpeg` y variantes `(1)`, `(2)` y `(3)` de Downloads. Se utilizaron como referencia visual, sin convertir la fotografía completa en una textura pegada.

Se añadieron dos revestimientos estáticos bajo `Main/Exterior/CostadosReferenciaFotos`: hormigón gris con juntas horizontales, dos volúmenes por lado, franja acristalada con montantes, ventanas horizontales desfasadas, vierteaguas, zócalo, ventilación y barandas. La fachada principal y su celosía existente permanecen fuera de este constructor.

Las proporciones se adaptan al campus construido: frente bajo de aproximadamente 48 m y bloque posterior de 96 m; la terraza del piso 5 permanece abierta. No es una reconstrucción fotogramétrica exacta. Las ventanas son detalles exteriores; no se perforaron paredes del interior.

Constructor manual: `scripts/exterior/costados_referencia_fotos.gd`. Material: `materials/entrance/hormigon_costados.gdshader`. Los nodos se construyeron y guardaron desde el editor mediante godot-mcp-toolkit; el script no genera geometría durante la partida. Hay 342 meshes nuevos, cero cuerpos de colisión nuevos y dos costados. No se ejecuta _process ni _physics_process en el constructor.

Validación: script compilado, escena guardada, campaña inicializada en fixture sin persistencia y capturas renderizadas de ambos lados y un acercamiento. Se ajustó el shader para evitar aspecto cuadriculado y suavizar juntas a distancia. No se midieron FPS comparativos ni se realizó un recorrido humano completo.

Preview aislado: `tests/CostadosPreview.tscn`, sin leer/escribir progreso de campaña. Capturas: `costado_oeste_referencia.png` y `costado_este_referencia.png`.
