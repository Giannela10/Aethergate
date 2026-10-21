# Piso 4

Nodo de la escena: `Main/Piso4`. Altura: 35.6744.

## Contenido

- `CostadosReferencia` (Node3D).
- `DistribucionPlanoPiso4` (Node3D).
- `SectorDocentesPiso4` (Node3D).
- `FilaFrontalPiso4` (Node3D).
- `SalasCentralesPiso4` (Node3D).
- `CorreccionSectorCentral` (Node3D).
- `VacioFranjaMorada` (Node3D).
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
