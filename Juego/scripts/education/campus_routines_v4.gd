extends Node
## Bounded simulation: nine decorative civilians; at most six nearby actors move.
var platform: Node
var actors: Array = []
var tick := 0.0
const Civilian = preload("res://scripts/education/routine_civilian_v4.gd")
func _ready() -> void:
	for floor_number in [-1,1,2,3,4,5,6,7,8]:
		var c: Node = platform.campaign
		var height: float = preload("res://scripts/campaign/campus_content.gd").HEIGHTS[8 if floor_number==-1 else floor_number-1]
		var seats: Node = c.player.get_node("SeatController")
		var start = seats.safe_position(Vector3(12,height+0.12,-143))
		var end = seats.safe_position(Vector3(15,height+0.12,-143))
		if start == null or end == null or absf(start.y-height)>0.5 or absf(end.y-height)>0.5: continue
		var ray := PhysicsRayQueryParameters3D.create(start+Vector3.UP*1.5,end+Vector3.UP*1.5,1)
		if not c.player.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var actor := Civilian.new()
		actor.platform = platform; actor.npc_id = "v4_civilian_"+str(floor_number)
		actor.route = [start,end]; actor.floor_number = floor_number
		add_child(actor); actor.global_position = start
		actors.append(actor)
	# A short, physically bounded classroom route demonstrates entering, sitting,
	# computer use, phone, conversation and leaving without global navigation.
	var classroom: Node3D=platform.laboratories["302"]
	var student := preload("res://scripts/education/lab_routine_civilian_v4.gd").new()
	student.platform=platform; student.npc_id="v4_lab_student"; student.floor_number=3
	student.route=[classroom.to_global(Vector3(0,0.05,-6.5)),classroom.to_global(Vector3(0,0.05,-2.5)),classroom.to_global(Vector3(-2.7,0.05,-2.5)),classroom.to_global(Vector3(-2.7,0.05,-2.35))]
	add_child(student); student.global_position=student.route[0]; actors.append(student)
func _process(delta: float) -> void:
	tick -= delta
	if tick>0: return
	tick = 1.0
	var c: Node = platform.campaign
	var active := 0
	for actor in actors:
		var offset: Vector3 = actor.global_position-c.player.global_position
		actor.sleeping = absf(offset.y)>4 or offset.length()>35 or active>=6 or c.active_duel!=null
		if not actor.sleeping: active+=1
		actor.visual.set_activity_level(3 if actor.sleeping else 1)
		actor.activity = ["WALK","PHONE","TALK","REST","CLASS"][int(c.academics.current_time().minute/12+actor.floor_number)%5]
