extends RefCounted
## Props and work poses only. Activity/routine logic remains with the owner.
const ACTIONS := ["TYPE","WRITE","READ","PHONE","EAT","REPAIR","INSPECT"]
const PROPS := ["NONE","PHONE","BOOK","COFFEE","TABLET","FOLDER","TOOL"]
var action := ""
var prop_kind := "NONE"
var prop: Node3D
var body: Node3D
var clock := 0.0
var weight := 0.0

func _init(visual: Node3D) -> void:
	body = visual

func set_activity(kind: String, object_kind: String = "NONE") -> void:
	action = kind if kind in ACTIONS else ""
	if object_kind == prop_kind:
		return
	if is_instance_valid(prop):
		prop.queue_free()
	prop = null
	prop_kind = object_kind if object_kind in PROPS else "NONE"
	if prop_kind == "NONE":
		return
	prop = Node3D.new()
	prop.name = "ActivityProp"
	body.hand_l.add_child(prop)
	match prop_kind:
		"PHONE","TABLET":
			var size := Vector3(0.075,0.012,0.14) if prop_kind == "PHONE" else Vector3(0.18,0.014,0.25)
			body._box(prop,size,Vector3(0,0,-0.06),Color("243746"))
			body._box(prop,size*Vector3(0.85,1.05,0.85),Vector3(0,0.002,-0.06),Color("6aa8b7"))
		"BOOK","FOLDER":
			body._box(prop,Vector3(0.17,0.035,0.23),Vector3(0,0,-0.08),Color("6d594c"))
			body._box(prop,Vector3(0.15,0.025,0.21),Vector3(0,0,-0.09),Color("e9e2cf"))
		"COFFEE":
			body._cyl(prop,0.035,0.025,0.085,Vector3(0,0.03,-0.02),Color("cbb99a"))
		"TOOL":
			body._box(prop,Vector3(0.03,0.025,0.20),Vector3(0,0,-0.04),Color("6f7981"))

func apply(delta: float, compatible: bool = true) -> void:
	clock += delta
	var active: bool = compatible and not action.is_empty() and not body.dead and not body.is_punching() and body.hurt_t <= 0
	weight = move_toward(weight,1.0 if active else 0.0,delta*8.0)
	if is_instance_valid(prop):
		prop.visible = active and body.secondary_animation_enabled
	if weight <= 0:
		return
	var pose := Vector2(0.65,1.4)
	if action == "PHONE": pose = Vector2(0.9,1.85)
	elif action == "TYPE": pose = Vector2(0.85+0.025*sin(clock*9),0.9)
	elif action == "REPAIR": pose = Vector2(0.9+0.08*sin(clock*3),0.7)
	elif action == "EAT": pose = Vector2(0.9,1.8)
	body.shoulder_l.rotation.x = lerpf(body.shoulder_l.rotation.x,pose.x,weight)
	body.elbow_l.rotation.x = lerpf(body.elbow_l.rotation.x,pose.y,weight)
	if action in ["TYPE","WRITE","REPAIR"] and not body.armed:
		body.shoulder_r.rotation.x = lerpf(body.shoulder_r.rotation.x,pose.x,weight)
		body.elbow_r.rotation.x = lerpf(body.elbow_r.rotation.x,pose.y+0.035*sin(clock*7),weight)
