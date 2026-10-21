# Piso 8

Nodo de la escena: `Main/Piso8`. Altura: 83.9136.

## Contenido

- `BarandasPasillos` (Node3D).
- `VestibuloAscensores` (Node3D).
- `Iluminacion` (Node3D).
- `EscaleraEmergencia` (Node3D).
- `LosasYAccesos` (Node3D).
- `MurosAccesoEmergencia` (Node3D).
- `PuertasAscensores` (Node3D).
- `Losas` (Node3D).
- `Estructura` (Node3D).
- `Cubierta` (Node3D).
- `PasilloReferencia` (instancia de `PasilloReferencia.tscn`): distribución con salas, baños y pasillos. El grupo `LadoSurSalasYVentanales` reproduce el lado sur de la fotografía del 13 de octubre a las 09:16:56.

Hay un único pasillo amplio y recto en el lado sur: X=−84 a −18 y X=18 a 84, entre Z=−137,8 y −122,5, con 15,3 m de ancho. Desde el punto de la escalera en X=19, Z=−134,8 se puede avanzar hasta el extremo oriental sin giros ni paredes intermedias. El resto de la estructura se ocupa con seis salas, dos baños y espacios de estudio, conservando el núcleo de ascensores y escaleras.

En el lado interior, Z=−137,8, están las salas y los baños con paneles beige y puertas. En el lado exterior, Z=−122,58, hay ventanales continuos con perfiles negros, pilares beige y mesas junto al vidrio: **no hay salas en ese lado**. Incluye baldosas oscuras, cielo con instalaciones, luminarias lineales, red húmeda, reciclaje y sillones morados.

El cielo queda a 11,16 m sobre el suelo de diseño, alineado con la cubierta existente del piso 8. Paredes, pilares, vidrios y perfiles alcanzan su cara inferior, a 11,08 m. Se rellena el espacio sobre las puertas manteniendo sus hojas de altura normal. Las instalaciones y luces acompañan al cielo elevado.

Las conexiones junto al atrio, en X=−19 y X=19, enlazan el pasillo exterior con el vestíbulo de ascensores. Se conserva el hueco central y los accesos existentes. Las puertas de salas y baños abren automáticamente por proximidad.

`InicioPasilloJuntoEscalera` marca el comienzo abierto en X=19, Z=−134,8. Está integrado al pasillo ancho completo; se retiraron las paredes de la entrada corta en L.

`AcabadosPasilloCompleto` remata todo el recorrido: paneles beige con juntas hasta el techo, zócalos y perfiles superiores, travesaños de vidrio a lo largo de ambas alas y cierres de extremos. Suelo, cielo e instalaciones cubren todo el pasillo. Los descansos del vestíbulo conservan el mismo acabado y los huecos existentes del atrio y las escaleras.

Las salas 805–806 están en el ala oriental y 807–808 en la occidental, con 23,4 m de profundidad. Las salas 809 y 810 completan los espacios próximos al núcleo con profundidades de 10,6 y 8,2 m respectivamente, terminando antes de los accesos de emergencia y ascensores. Sus interiores contienen mesas, sillas, pizarra y puesto docente. La numeración y distribución interior son una propuesta; las fotos no documentan el plano real. Los baños ocupan los extremos de la misma fila y los espacios de estudio aprovechan las losas laterales.

Los elementos se guardan en `PasilloReferencia.tscn`. `piso_8_completo.gd` contiene la construcción explícita; no genera geometría al jugar. Para reconstruir, ejecutar `godot --headless --path . --script res://tests/generar_piso8.gd`. `baldosas_oscuras.gdshader` define las juntas y vetas del suelo. Los materiales, mallas y formas repetidas se comparten.

Esta misma escena se instancia en los pisos 6 y 7, con su altura y `numero_piso` propios. Durante el juego, las salas y los rótulos se adaptan a 605–610, 705–710 y 805–810 respectivamente. La distribución del piso 8 es el modelo compartido para los tres niveles.

La prueba `tests/piso8_recorridos.gd` verifica las dos alas, las entradas e interiores, los baños y las conexiones con una cápsula de 0,45 m de radio y 2,7 m de altura, igual a la del jugador.

Los scripts exclusivos del nivel están en esta carpeta. Los mecanismos que conectan varios pisos están en `scripts/compartidos`. El generador del −1 y la emergencia está en `scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd`.

La propiedad `altura` informa la cota del piso; las piezas conservan las coordenadas originales del campus.

## Director de Carrera de Informática (personaje ficticio)

`Main/Piso8/EncuentroDirectorInformatica` contiene `DirectorInformaticaBoss` y el registro `CredencialDirector`. El boss aparece en coordenadas globales `(64, 84.06, -131)`, sobre el pasillo sur oriental. Este encuentro solo existe en Main, no en la escena compartida por los pisos 6 y 7.

`director_informatica_boss.gd` hereda de `enemy.gd`: 700 de vida, escala visual 1.4, persecución y ataques limitados al ala oriental del Piso 8. A 420 HP invoca una única pareja de enemigos de `virus_director.gd`, de 50 HP; a 210 HP activa Modo Administrador. `proyectil_error_sistema.gd` resuelve los proyectiles con colisión barrida. Pantallazo Azul anuncia un círculo de 6 m durante 1.2 segundos y después causa 36 de daño, respetando paredes y altura. La muerte cancela el área, los proyectiles y los virus.

La recompensa se guarda en `user://credencial_director.cfg`, separada de la papelería. Una futura puerta puede consultar:

```gdscript
var registry = get_node("/root/Main/Piso8/EncuentroDirectorInformatica/CredencialDirector")
if registry.has_credential("CredencialDirector"):
    # Permitir el acceso especial del Piso 8.
    pass
```

La credencial también se refleja en el metadato `CredencialDirector` del jugador y en un indicador visible al estar en el Piso 8. La entrega es única; no se consume al consultar. No se añade ni se bloquea ninguna puerta existente.

Prueba de fases, impactos, invocaciones, muerte, recompensa y persistencia: `godot --headless --path . --script res://tests/director_informatica_boss.gd`.
