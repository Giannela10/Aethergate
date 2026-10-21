class_name ContextualPose
extends RefCounted
## Capa visual, aplicada después de la locomoción. No altera combate ni colisión.
const ACTIONS := ["pickup","door","computer","button","elevator","sit","stand","inspect","talk","vending","workbench","read"]
var action := ""
var remaining := 0.0
var duration := 0.5
var seated := false
var seat_height := 0.55

func play(kind: String) -> bool:
	if not kind in ACTIONS:
		return false
	action = kind
	duration = 0.65 if kind in ["read","computer","talk","workbench"] else 0.42
	remaining = duration
	return true

func apply(model: Node3D, delta: float, velocity: Vector3) -> void:
	remaining = maxf(0,remaining-delta)
	if model.dead or model.hurt_t > 0 or model.is_punching():
		remaining = 0
		return
	if seated:
		model.hips.position.y = seat_height
		model.hip_l.rotation.x = PI*0.5
		model.hip_r.rotation.x = PI*0.5
		model.knee_l.rotation.x = -PI*0.5
		model.knee_r.rotation.x = -PI*0.5
		model.ankle_l.rotation.x = 0
		model.ankle_r.rotation.x = 0
	if remaining <= 0 or velocity.length() > 2.8:
		return
	var weight := sin(PI*(1.0-remaining/duration))
	var shoulder: Node3D = model.shoulder_l if model.armed else model.shoulder_r
	var elbow: Node3D = model.elbow_l if model.armed else model.elbow_r
	match action:
		"pickup":
			model.spine.rotation.x -= 0.28*weight
			shoulder.rotation.x = lerpf(shoulder.rotation.x,0.7,weight)
		"door","button","elevator","vending":
			shoulder.rotation.x = lerpf(shoulder.rotation.x,1.1,weight)
			elbow.rotation.x = lerpf(elbow.rotation.x,0.3,weight)
		"computer","workbench":
			model.shoulder_l.rotation.x = lerpf(model.shoulder_l.rotation.x,0.8,weight)
			model.elbow_l.rotation.x = lerpf(model.elbow_l.rotation.x,1.0,weight)
			if not model.armed:
				model.shoulder_r.rotation.x = lerpf(model.shoulder_r.rotation.x,0.8,weight)
				model.elbow_r.rotation.x = lerpf(model.elbow_r.rotation.x,1.0,weight)
		"inspect","read":
			shoulder.rotation.x = lerpf(shoulder.rotation.x,0.65,weight)
			elbow.rotation.x = lerpf(elbow.rotation.x,1.5,weight)
			model.head_pivot.rotation.x -= 0.15*weight
		"talk":
			shoulder.rotation.x = lerpf(shoulder.rotation.x,0.35,weight)
			elbow.rotation.x = lerpf(elbow.rotation.x,0.8,weight)
			model.head_pivot.rotation.x += 0.05*weight
		"sit","stand":
			model.spine.rotation.x -= 0.12*weight
