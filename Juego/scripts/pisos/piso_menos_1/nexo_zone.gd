extends Node3D
## A single telegraphed floor hazard; not a second encounter manager.
var boss: CharacterBody3D
var age := 0.0
var tick := 0.0
var radius := 2.1
var warning := 1.2
func _ready() -> void:
	boss.area.disc(self,radius,Color(0.85,0.25,0.1,0.32))
	boss.area.label(self,"ZONA DE ERROR\nALÉJATE",Vector3(0,0.5,0))
func _physics_process(delta: float) -> void:
	if not is_instance_valid(boss) or not boss.combat_active(): queue_free(); return
	age += delta
	if age > warning+3.0: queue_free(); return
	if age < warning: return
	tick -= delta
	if tick > 0: return
	tick = 1.0
	var player = boss.target
	if boss.valid_target() and absf(player.global_position.y-global_position.y) < 2 and Vector2(player.global_position.x-global_position.x,player.global_position.z-global_position.z).length() < radius and boss.has_clear_line(global_position+Vector3.UP,player.global_position+Vector3.UP):
		player.take_hit(Vector3.ZERO,boss.config.zone_damage)
