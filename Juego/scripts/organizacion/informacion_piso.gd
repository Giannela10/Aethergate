@tool
extends Node3D
## Etiqueta del nivel. Los elementos de este nodo pertenecen a este piso.
@export_category("Información del piso")
@export var numero_piso: int = 1
@export var etiqueta: String = "Piso 1"
@export var altura: float = 0.0
@export_multiline var descripcion: String = ""
