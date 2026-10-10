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

Los scripts exclusivos del nivel están en esta carpeta. Los mecanismos que conectan varios pisos están en `scripts/compartidos`. El generador del −1 y la emergencia está en `scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd`.

La propiedad `altura` informa la cota del piso; las piezas conservan las coordenadas originales del campus.
