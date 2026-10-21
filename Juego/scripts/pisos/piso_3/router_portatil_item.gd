class_name RouterPortatilItem
extends "res://scripts/inventory/inventory_item.gd"
## Registro local del Piso 3: no modifica el catálogo ni el uso general de objetos.
func _init() -> void:
	id = "RouterPortatil"
	display_name = "Router portátil"
	category = Category.ESPECIAL
	stackable = false
	max_stack = 1
	unique = true
	rarity = 3
	description = "En el duelo con NEXO reduce la protección por enlace de 18% a 12%. Ayuda pasiva al llevarlo en la mochila; no se consume. Los tres enlaces deben desactivarse igualmente."
