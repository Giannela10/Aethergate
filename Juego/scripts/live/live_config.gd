extends Resource
@export var enabled := true
@export_range(30,600) var minimum_gap := 90.0
@export_range(60,900) var maximum_gap := 240.0
@export_range(5,120) var combat_grace := 25.0
@export_range(1,3) var maximum_events := 1
@export_range(0,1) var rare_probability := 0.025
@export_range(0,100) var reward_budget := 24
@export var telemetry_enabled := false
@export_range(20,200) var journal_limit := 80
@export var event_resources: Array[Resource] = []
