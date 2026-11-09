extends Node3D
## Bounded, original digital sparks. No blood; no gameplay timing changes.
var platform: Node
var particles: Array[CPUParticles3D] = []
var cursor := 0
func _ready() -> void:
	var material := StandardMaterial3D.new(); material.albedo_color=Color("55ccf0"); material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := SphereMesh.new(); mesh.radius=0.035; mesh.height=0.07; mesh.material=material
	for index in 2:
		var burst := CPUParticles3D.new(); burst.mesh=mesh; burst.amount=12; burst.lifetime=0.3; burst.one_shot=true
		burst.explosiveness=1.0; burst.direction=Vector3.UP; burst.spread=90; burst.initial_velocity_min=1; burst.initial_velocity_max=3
		burst.gravity=Vector3(0,-3,0); burst.emitting=false; add_child(burst); particles.append(burst)
	platform.campaign.player.hit_received.connect(hit)
func hit() -> void:
	if not platform.campaign.live.settings.QUALITIES[platform.campaign.live.settings.data.quality].effects: return
	var burst := particles[cursor]; cursor=(cursor+1)%particles.size()
	burst.global_position=platform.campaign.player.global_position+Vector3.UP*1.4
	burst.restart(); burst.emitting=true
