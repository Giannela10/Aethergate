# Piso 3

Temática: **Informática y Telecomunicaciones**. Incluye el encuentro opcional
con el Profesor de Redes y Telecomunicaciones, personaje ficticio, en el ala oriental
del pasillo. Ver [PROFESOR_REDES.md](PROFESOR_REDES.md) para ubicación, routers,
fases, recompensa y pruebas. El encuentro no altera misiones ni otros pisos.

El negocio de la fotografía `WhatsApp Image 2026-10-13 at 12.17.40.jpeg` se encuentra en `LocalComidaReferencia`, frente a la antigua pared `Front_Left piso 3 sur9`. Incluye comedor, sillones, jardineras, celosía de madera, galería de vidrio, tuberías, mostrador y productos. La escena se guarda con `tests/generar_local_piso3.gd`; la entrada mira hacia el este, con el mostrador junto a la pared marcada `sur9`. Los muros originales `sur8` y `sur9` se conservan para mantener cerrada la sala del lado contrario. Los recorridos se comprueban con `tests/local_piso3_recorridos.gd`.

Nodo de la escena: `Main/Piso3`. Altura: 23.9677.

## Contenido

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
