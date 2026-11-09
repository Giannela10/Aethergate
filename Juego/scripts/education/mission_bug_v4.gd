extends CharacterBody3D
var missions: Node
var bug_id := ""
var health := 20.0
var dead := false
var body: Node3D
var label: Label3D
var active := false
func _ready() -> void:
	collision_layer=0; collision_mask=1
	var collision := CollisionShape3D.new(); var shape := SphereShape3D.new(); shape.radius=0.4; collision.shape=shape; collision.position.y=0.8; add_child(collision)
	body=preload("res://scripts/campaign/simulation_visual_v4.gd").digital_model(); body.scale=Vector3.ONE*0.45; body.position.y=0.3; add_child(body)
	label=Label3D.new(); label.position.y=1.8; label.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(label)
	dead=missions.state.bug_hits.get(bug_id,false)
	_refresh()
func _refresh() -> void:
	active=not dead and missions.platform.campaign.quests.state("v4_bugs")==1 and int(missions.state.mission_steps.get("v4_bugs",0))==0
	visible=active; collision_layer=2 if active else 0
	if active: add_to_group("enemy")
	else: remove_from_group("enemy")
	label.text="BUG DIGITAL · "+str(int(health))+" HP" if label!=null else ""
func _process(_delta: float) -> void: _refresh()
func take_hit(_direction: Vector3,damage: float) -> void:
	if not active or dead: return
	health=maxf(0,health-maxf(0,damage))
	if health>0: return
	dead=true; missions.state.bug_hits[bug_id]=true; _refresh()
	if missions.state.bug_hits.size()>=3: missions.advance(missions.definition("v4_bugs"),0)
	missions.platform.campaign.save_game()
