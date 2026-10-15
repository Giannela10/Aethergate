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
	description = "Recompensa única del Profesor de Redes. Efecto tecnológico reservado para una futura integración; todavía no se consume ni otorga resistencia."
