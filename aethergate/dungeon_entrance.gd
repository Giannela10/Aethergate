extends Area3D

@export var player_path: NodePath
@export var dungeon_spawn_path: NodePath

@onready var player: Node3D = get_node_or_null(player_path)
@onready var dungeon_spawn: Node3D = get_node_or_null(dungeon_spawn_path)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if player == null or dungeon_spawn == null:
		return

	if body == player:
		player.global_position = dungeon_spawn.global_position
