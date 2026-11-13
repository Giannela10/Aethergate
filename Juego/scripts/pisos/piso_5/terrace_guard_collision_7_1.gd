extends Node3D
## Explicit pane collision: the front CSG panes did not answer physics queries
## in the audited scene. Preserve their geometry, IDs, materials and handrail.
func _ready() -> void:
	for panel in get_children():
		if not panel is CSGBox3D or not str(panel.name).begins_with("Panel"): continue
		if panel.has_node("GuardCollision71"): continue
		var body=StaticBody3D.new()
		body.name="GuardCollision71"
		var shape=BoxShape3D.new();shape.size=panel.size
		var collision=CollisionShape3D.new();collision.shape=shape
		body.add_child(collision);panel.add_child(body)
