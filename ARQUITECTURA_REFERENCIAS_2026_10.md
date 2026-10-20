# Arquitectura según fotografías — 19 de octubre de 2026

Actualización vigente: por corrección expresa del usuario, el negocio del piso 5 se trasladó al lado de la escalera de emergencia. Se abrió el tabique necesario y se adaptó el lateral. Pasaron 22 comprobaciones físicas, incluidas apertura de puerta y circulación hacia la escalera. Detalles y captura en [reports/TIENDA_PISO5_REFERENCIA.md](reports/TIENDA_PISO5_REFERENCIA.md).

Aplicado al proyecto DuocGames mediante godot-mcp-toolkit. Es una adaptación 3D estilizada de las referencias, no una reconstrucción fotogramétrica ni una copia exacta de cada detalle.

## Cambios guardados

| Sector | Cambio |
|---|---|
| Pisos 2–8 | Acabado compartido de baldosas carbón con juntas y vetas finas: 687 paños de MeshInstance3D y CSGBox3D. La cara inferior de las losas conserva acabado de hormigón. |
| Pisos 1 y −1 | Se conserva el pavimento existente. |
| Aulas | 35 puertas adaptadas: madera clara, marco negro, manilla y placa metálica, rejilla inferior, ficha blanca. Apertura por bisagra, conservando bloqueo de campaña y rutas originales. |
| Frentes de aulas | Mamparas, franja esmerilada, placa SALA verde/blanca, número, INFORMACIÓN y horario con cabecera naranja. Se ocultan las placas antiguas duplicadas conservando sus nodos. |
| Interiores | Mesas claras y sillas oscuras existentes; bandejas de cableado, soportes y luminarias lineales suspendidas, con altura adaptada al cielo existente. Se respeta el equipamiento temático de Salud y de formación general. |
| Laboratorio 303, piso 3 | 30 puestos visuales con monitor, soporte, teclado y mouse sobre las mesas existentes. Estos monitores decorativos no agregan nuevas actividades ni IDs de computadores. |
| Escaleras | 204 peldaños con bordes amarillos, laterales grises; siete carteles blancos/amarillos y puntos visuales de DEA, gabinete de incendio y reciclaje. |
| Café del piso 3 | Rótulo paradiso Café rojo con borde claro, conservación de menús y vitrina, detalles de pastelería, tazas, cafetera y cabecera naranja del refrigerador. |
| Entrada | Estatua blanca estilizada de figura mariana, túnica con pliegues y velo, pedestal, seto, sendero y jardín lateral. Mástiles y bandera chilena, mesas de picnic, reciclaje morado, bienvenida amarilla. Pendón de San José y relieve simplificado en columna. |
| Explanada | Material gris modular para plaza central, andén, vereda y 16 senderos existentes; se conserva su geometría y circulación. |

Las aulas convertidas son la 303, 16 aulas numeradas del piso 4 y seis aulas por piso en 6, 7 y 8. El piso 5 conserva su terraza y contenido transversal; no se inventaron aulas. Biblioteca, baños, oficinas, casino, ascensores y salidas de emergencia conservan sus tipos de puertas.

## Referencias revisadas

- Serie WhatsApp 09.15.11: laboratorio, mesas, computadores, sillas, luz y techo industrial.
- Serie 09.15.13, imágenes sin sufijo y (1)–(8): mamparas y puertas de aulas, carteles SALA/horario, pasillo, baño como referencia diferenciada, escaleras y café.
- Series 09.24.09 y 09.24.10: pórtico, vidrio, bienvenida, pendón, jardín, estatua, bandera, senderos, mobiliario y reciclaje.
- Los costados de 08.46.14 mantienen la intervención anterior documentada en reports/COSTADOS_REFERENCIA.md.

No se reprodujeron personas, textos ilegibles ni marcas/menús que no se pudieran leer. La estatua y el relieve son modelos geométricos propios simplificados. El reflejo del pavimento depende del renderer Compatibility; no se agregaron reflejos en tiempo real ni luces con nuevas sombras.

## Compatibilidad y rendimiento

- Se tomó inventario de 41.811 nodos y 6.342 CollisionShape3D antes de intervenir. Comparación posterior en editor: cero nodos originales ausentes.
- De las colisiones existentes, únicamente cambian las 70 hojas antiguas de las 35 puertas: se deshabilitan y se agrega una hoja física por puerta. Los marcos/muros conservan su posición física.
- Se conservan los nodos HojaIzquierda/HojaDerecha y los componentes CampaignAccess. `photo_hinged` habilita la nueva rama del script compartido; las otras puertas siguen usando la rama anterior.
- Los detalles nuevos quedan serializados en Main.tscn; el constructor @tool no tiene procesamiento de juego ni reconstruye al iniciar.
- Se combinaron 2.320 nodos visuales nuevos en mallas por material. Los 204 bordes de peldaños pertenecen a sus pisos y siguen su visibilidad. No se alteraron los sistemas LOD/SLEEP ni el HUD.
- No se cambiaron IDs de misiones, bosses, recompensas, computadores, inventario ni formato de guardado.

## Archivos

- Main.tscn: materiales, detalles de aulas, café, escaleras y jardín.
- scripts/compartidos/puerta_vidrio_salas.gd: rama de apertura por bisagra.
- scripts/exterior/arquitectura_fotos_octubre.gd: herramientas manuales de construcción y auditoría.
- materials/entrance/piso_fotos.gdshader: piso común, acabado superior e inferior diferenciados.
- materials/entrance/madera_salas_fotos.gdshader: madera clara.
- materials/entrance/pavimento_exterior_fotos.gdshader: pavimento modular exterior.
- tests/ArquitecturaFotosPreview.tscn y tests/arquitectura_fotos_preview.gd: revisión visual, colisiones de puertas y regresiones sin guardar progreso del jugador.
- tests/campaign_regression.gd: espera del inicio real del duelo en vez de una pausa fija de 0,7 segundos.

## Validación

- Scripts nuevos/modificados: validación GDScript por MCP.
- 35/35 puertas: bloqueo cierra, colisión cerrada presente, apertura por proximidad y cápsula de paso libre. Resultado: reports/arquitectura_validacion.json.
- Auditoría de conservación: reports/arquitectura_editor_validacion.json; inventario previo: reports/arquitectura_antes.json.
- Regresiones y medición de carga: reports/arquitectura_regresiones.json. La medición headless no equivale a FPS gráficos.
- Resultado final de regresiones: campaña PASS, inventario PASS, distribución de pisos PASS (596 rutas). Carga headless completada sin errores de script: 3.259 ms de carga de recurso, 3.548 ms hasta instanciación y 5.714 ms hasta finalizar la medición; memoria estática aproximada 406,8 MiB. Son valores de esta ejecución, no una garantía de rendimiento en otros equipos.
- La regresión detectó que el editor había perdido el valor QUIZ del controlador de la Bibliotecaria al serializar la escena. Se restauró explícitamente `duel_type = 1` y se comprobó que al cargar vuelve a iniciar las preguntas y pausar el juego. La prueba también espera ahora la transición real de la intro. No se rediseñó este boss.
- Capturas del juego en reports/fotos_*.png. La revisión visual mediante capturas no equivale a un recorrido humano.

## Recorrido humano pendiente

- [ ] Caminar por pisos 2–8 y comparar acabado y escala con las referencias.
- [ ] Abrir/cerrar aulas, acercarse desde ambos lados y pasar llevando objetos.
- [ ] Probar TarjetaAcceso en su puerta de campaña y cargar una partida antigua.
- [ ] Subir y bajar escaleras; revisar carteles desde la cámara del jugador.
- [ ] Revisar café de cerca: vitrina, rótulo, cafetera, productos y circulación.
- [ ] Revisar laboratorio 303 y aulas del piso 4, 6, 7 y 8.
- [ ] Recorrer entrada y jardín: estatua, pedestal, bandera y senderos.
- [ ] Medir FPS en el equipo del usuario y ajustar fidelidad/escala visual si hace falta.

La revisión humana y la fidelidad fotográfica exacta siguen pendientes; no se declaran aprobadas automáticamente.
