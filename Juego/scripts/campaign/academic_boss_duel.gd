extends "res://scripts/campaign/boss_duel_controller.gd"
func interact(candidate: CharacterBody3D) -> void:
	if not actor.placement_valid: return
	if defeated and not candidate.busy and not candidate.dead:
		campaign.ui.begin_character_dialogue(actor,true)
		campaign.ui.dialog(boss_name,"Buen trabajo. Puedes seguir explorando y preparándote.",["Continuar"],[campaign.ui.close_modal],true)
		return
	super.interact(candidate)
	if state == DuelState.DIALOGUE:
		campaign.ui.dialog(boss_name,intro_text,["Iniciar desafío","Ahora no"],[accept,decline])
func interaction_text(player: Node) -> String:
	return "[E] Hablar con "+boss_name if defeated else (super.interaction_text(player) if actor.placement_valid else "")
func accept() -> void:
	if state != DuelState.DIALOGUE: return
	actor.prepare_duel()
	await super.accept()
	if state == DuelState.COMBAT: actor.begin_academic_duel()
func decline() -> void:
	super.decline()
	actor.clear_academic_effects()
func reset_duel() -> void:
	super.reset_duel()
	if not defeated: actor.reset_academic_duel()
func _finish() -> void:
	if defeated: return
	actor.clear_academic_effects()
	super._finish()
