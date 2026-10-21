# Pavimento negro compartido

Se asignó la misma instancia de material de `Piso3/AcabadosPasillos/PasilloEste` a los pavimentos planos de los pisos 3–8 y a pasillos, vestíbulos y losas de circulación del piso 2. No se cambió el suelo de 1 ni −1, los muebles ni las marcas amarillas de las escaleras.

Se revisaron 434 paños: piso 2: 45; piso 3: 44; piso 4: 54; piso 5: 57; pisos 6, 7 y 8: 78 cada uno. Las superficies ya tratadas mantienen su acabado; se unificaron las referencias del material que estaban duplicadas. La auditoría final de estos paños no detectó acabados distintos del shader negro de referencia. No se modificaron colisiones ni geometría.

Herramienta manual: `scripts/compartidos/edicion/unificar_piso_negro.gd`. Resultado: `pisos_negros_unificados.json`. Todo queda serializado en Main.tscn, sin reconstrucción al iniciar el juego.
