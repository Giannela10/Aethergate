# Piso 2

Nodo de la escena: `Main/Piso2`. Altura: 12.0584.

## Contenido

- `RellenoFrenteEscalera` (CSGBox3D).
- `Biblioteca` (Node3D).
- `AuditorioPiso2e` (Node3D).
- `AcabadosZonaAscensores` (Node3D).
- `SalaImpresiones` (Node3D).
- `CostadosReferencia` (Node3D).
- `BarandasPasillos` (Node3D).
- `AcabadosEscaleraCentral` (Node3D).
- `VestibuloAscensores` (Node3D).
- `Iluminacion` (Node3D).
- `EscaleraEmergencia` (Node3D).
- `LosasYAccesos` (Node3D).
- `MurosAccesoEmergencia` (Node3D).
- `AcabadosPasillos` (Node3D).
- `PuertasAscensores` (Node3D).
- `Losas` (Node3D).
- `Estructura` (Node3D).
- `Escaleras` (Node3D).
- `BarandasEscalerasPrincipales` (Node3D).

Los scripts exclusivos del nivel están en esta carpeta. Los mecanismos que conectan varios pisos están en `scripts/compartidos`. El generador del −1 y la emergencia está en `scripts/compartidos/edicion/piso_menos_uno_y_emergencia.gd`.

La propiedad `altura` informa la cota del piso; las piezas conservan las coordenadas originales del campus.
