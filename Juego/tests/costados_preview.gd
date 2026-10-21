class_name CostadosPreview
extends Node3D
var campus: Node3D
var campaign: Node
var validation := {}
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	campus = load("res://Main.tscn").instantiate()
	campaign = campus.get_node("CampusCampaign")
	campaign.persist = false
	campus.get_node("Piso8/EncuentroDirectorInformatica/CredencialDirector").persist = false
	add_child(campus)
	while not campaign.ready_for_play: await get_tree().process_frame
	campaign.ui.close_modal()
	campaign.player.set_physics_process(false)
	campaign.manager.set_process(false)
	campaign.live.director.enabled = false
	for node in campus.find_children("*","CanvasLayer",true,false): node.visible = false
	var facade = campus.get_node("Exterior/CostadosReferenciaFotos")
	validation = {"sides":facade.get_child_count(),"meshes":facade.find_children("*","MeshInstance3D",true,false).size(),"collisions":facade.find_children("*","CollisionObject3D",true,false).size(),"campaign_ready":campaign.ready_for_play}
	print("COSTADOS_REFERENCE ",JSON.stringify(validation))
	show_side(1)
func show_side(side: int = 1) -> void:
	campaign.manager.cam.global_position = Vector3(side*190,30,-191)
	campaign.manager.cam.look_at(Vector3(side*85.8,44,-121))
func close_up(side: int = 1) -> void:
	campaign.manager.cam.global_position = Vector3(side*120,16,-157)
	campaign.manager.cam.look_at(Vector3(side*85.8,24,-140))
