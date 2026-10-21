# Organización por piso

Abre `Main.tscn`. Los pisos están ordenados como `PisoMenos1`, `Piso1`, `Piso2`, `Piso3`, `Piso4`, `Piso5`, `Piso6`, `Piso7` y `Piso8`.

Cada nodo tiene en el Inspector **numero_piso**, **etiqueta**, **altura** y **descripcion**. La altura es informativa: no vuelvas a desplazar el nodo por esa cantidad. La geometría conserva las coordenadas del campus.

| Nivel | Carpeta y contenido |
| --- | --- |
| −1 | [piso_menos_1/INFORMACION.md](piso_menos_1/INFORMACION.md) |
| 1 | [piso_1/INFORMACION.md](piso_1/INFORMACION.md) |
| 2 | [piso_2/INFORMACION.md](piso_2/INFORMACION.md) |
| 3 | [piso_3/INFORMACION.md](piso_3/INFORMACION.md) |
| 4 | [piso_4/INFORMACION.md](piso_4/INFORMACION.md) |
| 5 | [piso_5/INFORMACION.md](piso_5/INFORMACION.md) |
| 6 | [piso_6/INFORMACION.md](piso_6/INFORMACION.md) |
| 7 | [piso_7/INFORMACION.md](piso_7/INFORMACION.md) |
| 8 | [piso_8/INFORMACION.md](piso_8/INFORMACION.md) |

Las losas originales están en **Losas**; paredes y pilares, en **Estructura**; escaleras originales, en **Escaleras**. **EscaleraEmergencia** incluye la puerta, el descanso y los tramos hacia el siguiente nivel. **PuertasAscensores** guarda las tres puertas fijas de cada piso; las cabinas móviles permanecen en `Main/SistemasCompartidos/AscensoresEstudiantiles` y las enlazan mediante `gate_paths`.

Para agregar algo, créalo dentro del piso correspondiente. Guarda aquí los scripts que sean exclusivos del nivel. Los comportamientos reutilizables van en `scripts/compartidos`; las herramientas que trabajan en varios niveles están en `scripts/compartidos/edicion`.

Las utilidades antiguas de construcción usan `scripts/organizacion/nodos_campus.gd` para resolver las rutas trasladadas. Para código nuevo, usa las rutas actuales de la escena. Las fichas se actualizan seleccionando `Main/HerramientasEdicion/InformacionPisos` y pulsando **Actualizar fichas de pisos**. Guarda después la escena para conservar las descripciones.

En el mismo nodo, **Mostrar campus completo** activa la visibilidad de todos los elementos del campus. Las piezas antiguas retiradas para crear huecos y accesos tienen la marca `geometria_retirada` y permanecen ocultas.

Validación del orden:

```powershell
godot --headless --path . --script res://tests/organizacion_pisos.gd
```
