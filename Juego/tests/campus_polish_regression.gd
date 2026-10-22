extends SceneTree

class CampaignFixture extends Node3D:
	var ready_for_play := true
	var data := {"tutorial":true}
	var audio: Node

class EnemyFixture extends Node3D:
	var health := 100.0

var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var campaign := CampaignFixture.new()
	root.add_child(campaign)
	var polish = load("res://scripts/campaign/campus_polish.gd").new()
	polish.campaign = campaign
	campaign.add_child(polish)
	polish.set_process(false)
	var objective = load("res://scripts/campaign/academic_objective.gd").new()
	objective.mode = "destroy"
	campaign.add_child(objective)
	objective.set_physics_process(false)
	var enemy := EnemyFixture.new()
	campaign.add_child(enemy)
	enemy.add_to_group("enemy")
	polish._process(0.11)
	check(polish.healths.size() == 1,"Ignore actual academic objective without health")
	check(polish.healths.get(enemy.get_instance_id()) == 100.0,"Track enemy health")
	enemy.health = 75.0
	polish._process(0.11)
	var labels := campaign.find_children("*","Label3D",false,false)
	check(labels.size() == 1,"Create one damage number")
	if labels.size() == 1: check(labels[0].text.ends_with("25"),"Display actual damage")
	polish._process(0.11)
	check(campaign.find_children("*","Label3D",false,false).size() == 1,"Do not repeat damage without health change")
	enemy.remove_from_group("enemy")
	polish._process(0.11)
	check(polish.healths.is_empty(),"Remove stale tracked actors")
	print("CAMPUS_POLISH_RESULT ",JSON.stringify({"checks":6,"failures":failures}))
	campaign.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
