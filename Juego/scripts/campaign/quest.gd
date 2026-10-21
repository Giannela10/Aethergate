extends Resource
enum State { NOT_STARTED, ACTIVE, COMPLETED, FAILED }
@export var quest_id := ""
@export var title := ""
@export_multiline var description := ""
@export var main_quest := false
@export var prerequisite := ""
@export var requirements: Array[Dictionary] = []
@export var reward: Dictionary = {}
