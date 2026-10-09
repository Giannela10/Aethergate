extends "res://scripts/juego/weapon.gd"
## Configura objetos recogibles de la sala usando el combate existente.
@export_enum("palo", "silla") var tipo: String = "palo"
func _ready() -> void:
	kind = tipo
	super._ready()
