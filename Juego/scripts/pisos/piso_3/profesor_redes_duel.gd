class_name ProfesorRedesDuel
extends "res://scripts/campaign/boss_duel_controller.gd"
## Solo adapta el texto y los ganchos del duelo del Piso 3.
func interact(candidate: CharacterBody3D) -> void:
	if not actor.get_parent().placement_valid:
		return
	super.interact(candidate)
	if state == DuelState.DIALOGUE:
		campaign.ui.dialog("PROFESOR DE REDES Y TELECOMUNICACIONES",intro_text,["Iniciar desafío","Ahora no"],[accept,decline])

func interaction_text(_player: Node) -> String:
	return "[E] Hablar con Profesor de Redes" if state == DuelState.NEUTRAL else ""

func accept() -> void:
	await super.accept()
	if state == DuelState.COMBAT:
		actor.begin_network()

func reset_duel() -> void:
	super.reset_duel()
	if not defeated:
		actor.reset_network()

func _finish() -> void:
	if defeated:
		return
	actor.clear_network_effects()
	super._finish()
	campaign.event("story","nexo_redes")
	campaign.save_game()
	call_deferred("_show_nexo_hint")

func _show_nexo_hint() -> void:
	if is_instance_valid(campaign) and not campaign.player.dead:
		campaign.player.body.set_expression("WORRIED")
		campaign.player.set_meta("important_scene",true)
		campaign.ui.begin_character_dialogue(actor,true)
		campaign.ui.dialog("Profesor de Redes","Esto no es un fallo normal...\nhay tráfico extraño viniendo de otros pisos.\n\nHas obtenido RouterPortatil.",["Continuar"],[campaign.ui.close_modal],true)
