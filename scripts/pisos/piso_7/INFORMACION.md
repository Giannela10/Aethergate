# Piso 7

Nodo de la escena: `Main/Piso7`. Altura: 71.9422.

## Contenido

- `BarandasPasillos` (Node3D).
- `AcabadosEscaleraCentral` (Node3D).
- `VestibuloAscensores` (Node3D).
- `Iluminacion` (Node3D).
- `EscaleraEmergencia` (Node3D).
- `LosasYAccesos` (Node3D).
- `MurosAccesoEmergencia` (Node3D).
- `PuertasAscensores` (Node3D).
- `Losas` (Node3D).
- `Estructura` (Node3D).
- `Escaleras` (Node3D).
- `BarandasEscalerasPrincipales` (Node3D).
- `PasilloReferencia`: instancia compartida de la distribución aprobada del piso 8, con pasillo sur de 15,3 m, seis salas, dos baños, espacios de estudio, ventanales y cielo de 11,16 m.

La distribución es la misma en los pisos 6, 7 y 8. En este nivel queda sobre la losa de cota 71,9422; las salas se identifican como 705–710 durante el juego. La geometría, los materiales y el mobiliario proceden de `scripts/pisos/piso_8/PasilloReferencia.tscn`, para mantener los tres niveles iguales. Los accesos de ascensores y escaleras se conservan.

Comprobación de recorridos: `godot --headless --path . --fixed-fps 60 --script res://tests/piso8_recorridos.gd -- --floor=7`.

Los scripts exclusivos del nivel están en esta carpeta. Los mecanismos que conectan varios pisos están en `scripts/compartidos`. El generador del −1 y la emergencia está en `scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd`.

La propiedad `altura` informa la cota del piso; las piezas conservan las coordenadas originales del campus.
