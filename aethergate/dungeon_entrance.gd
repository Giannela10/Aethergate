extends Area3D

@export var player_path: NodePath
@export var dungeon_spawn_path: NodePath

var player_inside: bool = false

@onready var player: Node3D = get_node_or_null(player_path)
@onready var dungeon_spawn: Node3D = get_node_or_null(dungeon_spawn_path)

func _ready() -> void:
	print("SCRIPT DEL PORTAL ACTIVO")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		enter_dungeon()

func _on_body_entered(body: Node3D) -> void:
	print("ENTRÓ AL ÁREA: ", body.name)

	if body == player:
		player_inside = true
		print("PLAYER DETECTADO")

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player_inside = false
		print("PLAYER SALIÓ DEL PORTAL")

func enter_dungeon() -> void:
	if player == null or dungeon_spawn == null:
		print("ERROR: Player o DungeonSpawn no están asignados")
		return

	print("Entrando al calabozo...")
	player.global_position = dungeon_spawn.global_position
