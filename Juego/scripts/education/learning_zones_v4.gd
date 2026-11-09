extends Node3D
## Movement selects an option. Only the existing server RPC decides correctness.
var campaign: Node
var view: Control
var chosen := false
func begin(c: Node, owner_view: Control, activity: Dictionary) -> bool:
	campaign=c; view=owner_view
	var options: Array=activity.get("content",{}).get("options",[])
	var points: Array=c.academic_expansion.arena_points(c.player.global_position)
	if options.size()>points.size(): return false
	process_mode=Node.PROCESS_MODE_ALWAYS
	for index in options.size():
		var point := Node3D.new(); add_child(point); point.global_position=points[index]
		var mesh := MeshInstance3D.new(); var disc := CylinderMesh.new(); disc.top_radius=0.85; disc.bottom_radius=0.85; disc.height=0.035; mesh.mesh=disc
		var material := StandardMaterial3D.new(); material.albedo_color=[Color("206dae"),Color("8861a2"),Color("aa7433"),Color("278571")][index%4]; mesh.material_override=material; point.add_child(mesh)
		var label := Label3D.new(); label.text=str(index+1)+" · "+str(options[index]); label.position.y=1.6; label.font_size=40; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; point.add_child(label)
		var area := Area3D.new(); area.collision_layer=0; area.collision_mask=c.player.collision_layer
		var collision := CollisionShape3D.new(); var shape := CylinderShape3D.new(); shape.radius=0.85; shape.height=2.7; collision.shape=shape; collision.position.y=1.35; area.add_child(collision); point.add_child(area)
		area.body_entered.connect(func(body):
			if body==campaign.player: pick(index))
	c.ui.close_modal()
	c.ui.notify(str(activity.prompt)+"\nCamina hacia una zona numerada. Esc cancela y abre la pausa.",30)
	return true
func pick(index: int) -> void:
	if chosen or not is_instance_valid(view): return
	chosen=true
	view._send(index)
	queue_free.call_deferred()
func _process(_delta: float) -> void:
	if not is_instance_valid(campaign) or not is_instance_valid(view) or (campaign.ui.modal and not chosen): queue_free()
