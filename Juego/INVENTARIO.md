# Personaje e inventario

El jugador de Main se crea en tiempo de ejecución por `gameplay_manager.gd`. Ahora se llama `Player`; no se usa `Character.tscn` para ese recorrido. El movimiento, cápsula de pie/agachado, cámara, golpes, daño, computadores y minijuegos conservan sus mecanismos anteriores. `humanoid.gd`, `weapon.gd`, `enemy.gd` y `gameplay_manager.gd` no se modificaron.

## Controles y objetos de muestra

- `E`: recoge el objeto más cercano, respetando alcance y paredes. Las armas del sistema anterior se recogen y equipan; el arma anterior se guarda en la mochila.
- `I`: abre/cierra la mochila. Contiene nombre, cantidad, categoría, icono opcional, durabilidad y filtros.
- `Usar`: consume un objeto o aplica un efecto especial. `Equipar`: equipa un arma o artículo de papelería.
- `Guardar equipado`: guarda el arma sin perder durabilidad.
- `Asignar a 1–4`: asigna el objeto seleccionado a un espacio rápido; las teclas 1–4 lo usan o equipan. Las primeras pilas utilizables recibidas ocupan automáticamente los espacios libres.
- `G`: suelta el arma al suelo del piso actual y la retira del inventario. `Q`: conserva el lanzamiento de implementos deportivos y los retira de la mochila al lanzar.
- `F`: abre los apuntes del artículo de papelería equipado. La mochila conserva la edición y guardado de notas.

El inventario no pausa el mundo: recibir daño lo cierra. Los accesos rápidos no interfieren con computadores, tiendas ni el duelo de la bibliotecaria. Los objetos clave no se consumen.

`Main/ObjetosRecogibles` contiene muestras cerca del inicio, en Z=-3: Botiquin (X=-4), Comida (-2), BebidaEnergetica (0), USBInfectado (2) y PaletaPingPong (4). Solo son nuevos objetos; no se reconstruyó ninguna zona del mapa. Estas muestras reaparecen al reiniciar la escena.

## Efectos

| Objeto | Efecto |
|---|---|
| Bebida | +10 de vida |
| Comida | +30 de vida |
| Botiquin | +50 de vida |
| ColacionEspecial | Vida completa |
| BebidaEnergetica | Velocidad ×1.35 durante 12 s; renovar no acumula potencia |
| USBInfectado | Daño especial base 40 a un objetivo compatible a menos de 7 m y sin paredes intermedias |

Un curativo no se gasta si la vida está completa. El USB no se gasta si no hay objetivo compatible, está fuera de alcance, hay una pared o tiene inmunidad. El Director tiene debilidad ×2: recibe 80 de daño, queda paralizado 3 s y cancela un Pantallazo Azul pendiente.

## Estructura del jugador

```text
Player (player.gd)
  CollisionShape3D                 # misma cápsula y dimensiones
  Visual (student_visual.gd, hereda humanoid.gd)
    Model                         # articulaciones y mallas procedurales existentes
      Torso / Head / brazos / piernas
      ... mano derecha
        WeaponSocket
        ItemSocket
      ... torso
        BackpackSocket / Mochila
      ImportedModel / Skeleton3D  # reserva oculta, sin huesos ni modelo importado
    AnimationPlayer
    AnimationTree                 # inactivo; no sustituye la animación procedural
  CameraPivot                     # referencia preparada; la cámara actual sigue en GameplayManager
  InteractionArea                 # alcance preparado, sin colisiones adicionales
  Inventory / StoredWeapons
  InventoryUI
  LegacyStationeryUI              # conservado, oculto y sin capturar I
```

`student_visual.gd` mejora solo al estudiante: cabeza, rostro, pelo, torso, ropa, zapatillas, credencial, reloj y mochila. Reutiliza el rig procedural que ya anima caminar, correr, golpear, daño y muerte. Los clips Idle, Walk, Run, Attack, Hurt y Death son reservas **sin pistas**: para incorporar animaciones de un archivo GLB/FBX se debe importar el modelo riggeado bajo ImportedModel, enlazar sus huesos/sockets, reemplazar los clips y activar/configurar el AnimationTree. No hay animaciones importadas nuevas.

## Guardado y compatibilidad

`user://inventario_estudiante.json` guarda cantidades, espacios rápidos, arma equipada y durabilidad individual. Las armas no se apilan: cada una conserva su instancia y sus usos. Las armas guardadas siguen reutilizando `weapon.gd` o `implemento_deportivo.gd`; la paleta es una subclase de weapon.

La papelería y sus notas conservan `user://papeleria_inventario.json`. Sus cantidades se migran a la mochila y las entregas del vendedor se sincronizan. La credencial del Director mantiene su registro anterior `user://credencial_director.cfg` y se sincroniza con el inventario general. Los demás objetos nuevos viven en un único inventario. No se guardan salud, posición ni duración restante de la bebida energética.

## Crear un objeto

1. Agregar una definición en `_build()` de `scripts/inventory/item_catalog.gd`, con ID estable y categoría de `inventory_item.gd`.
2. Para un consumible, por ejemplo: `_add("Snack", "Snack", 0, {"heal_amount": 15.0, "description": "Recupera 15 de vida."})`.
3. Instanciar `scripts/inventory/InventoryPickup.tscn` en la zona deseada. Asignar `item_id = "Snack"` y `quantity = 1` en el inspector.
4. Opcionalmente asignar una Texture2D a `icon` en la definición. No se requiere icono para usar el objeto.

También existe `Catalog.register_item(resource)` para definiciones Resource de `inventory_item.gd`. Para cargar un guardado deben registrarse todas las definiciones personalizadas antes de que Inventory cargue los datos; la opción más simple es incorporarlas al catálogo.

API de entrega: `player.receive_item("Botiquin", 2)`. API de consulta: `player.inventory.has_item("Botiquin", 1)`.

## Llaves y accesos

`player.has_key_item("CredencialDirector")`, `player.has_key_item("LlaveCasino")` y `player.has_key_item("TarjetaAcceso")` permiten comprobar objetos sin consumirlos. La credencial también respeta el metadato del registro anterior.

Para un acceso nuevo, agregar como hijo un nodo con `key_access.gd`, configurar `required_item`, llamar `try_unlock(player)` desde su interacción y conectar `unlocked` con la apertura real. El componente comprueba distancia, pared y posesión de la llave. No se bloquearon ni cambiaron las puertas existentes. La conexión de futuras puertas a la animación/apertura depende de cada puerta.

## Debilidades de bosses

Los bosses existentes tienen un hijo `ItemEffects` con `item_effect_receiver.gd`. No altera su IA hasta aplicar un objeto compatible. Sus propiedades se configuran en el inspector:

```gdscript
weaknesses = {"USBInfectado": 2.0} # multiplicador de daño
resistances = {"OtroObjeto": 0.25} # recibe el 25%; 0 no admite el efecto
immunities = ["ObjetoInmune"]
stun_seconds = 3.0
cancel_methods = ["_cancel_blue_screen"] # métodos opcionales del receptor
```

Los nombres de métodos son configuración del componente, no reglas dentro del objeto. Si no hay debilidad/resistencia explícita para un objeto, este no afecta al receptor. La parálisis detiene temporalmente su física y cancela el golpe pendiente; después recupera su estado de procesamiento. El combate y daño normales no pasan por este componente y permanecen iguales.

El Director está configurado para el USB. Chef y Punto Estudiantil tienen el componente preparado sin debilidades por defecto. La bibliotecaria conserva su duelo: no tiene `take_hit`, así que el componente no permite saltarse las preguntas. Para efectos especiales sobre ese duelo se necesitaría una integración explícita posterior.

## Verificación

```text
godot --headless --path . --script res://tests/inventory_regression.gd
godot --headless --path . --script res://tests/gameplay_regression.gd
godot --headless --path . --script res://tests/chef_supremo_casino.gd
godot --headless --path . --script res://tests/director_informatica_boss.gd
```

Las pruebas del inventario usan guardados temporales dentro de tests y no sustituyen los archivos de la partida.
