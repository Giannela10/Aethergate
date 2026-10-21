extends Resource
## Definición reutilizable; los datos de cada arma se guardan por instancia.
enum Category { CONSUMIBLE, ARMA, CLAVE, ESPECIAL, PAPELERIA }
@export var id := ""
@export var display_name := ""
@export var category: Category = Category.CONSUMIBLE
@export var icon: Texture2D
@export var stackable := true
@export var max_stack := 999
@export var heal_amount := 0.0
@export var full_heal := false
@export var speed_multiplier := 1.0
@export var duration := 0.0
@export var weapon_kind := ""
@export var weapon_sport := ""
@export var special_damage := 0.0
@export var effect_range := 7.0
@export var description := ""
@export_enum("COMÚN","POCO COMÚN","RARA","ESPECIAL") var rarity := 0
@export var weapon_data: Dictionary = {}
@export var unique := false

func category_name() -> String:
	return ["Consumibles","Armas","Objetos clave","Objetos especiales","Papelería"][category]
