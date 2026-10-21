extends "res://scripts/campaign/boss_duel_controller.gd"
func _process(delta: float) -> void:
	super._process(delta)
	if initialized:
		identity_label.text = "NEXO\nSISTEMAS RESTAURADOS" if defeated else "NEXO\n[E] Interactuar" if actor.area.authorized() else "NEXO\nACCESO BLOQUEADO"
func interaction_text(_player: Node) -> String:
	if defeated: return "[E] Revisar núcleo restaurado"
	if not actor.area.authorized(): return ""
	return "[E] Interactuar con NEXO" if state == DuelState.NEUTRAL else ""
func interact(candidate: CharacterBody3D) -> void:
	if defeated:
		if not candidate.busy: actor.area.show_results()
		return
	if not actor.area.authorized(): return
	super.interact(candidate)
	if state == DuelState.DIALOGUE:
		campaign.ui.dialog("NEXO","Conexión no autorizada detectada.\n\nEl sistema no puede permitir la interrupción del protocolo.\n\nPuedes retirarte y prepararte. Cerrar durante el duelo conserva el estado previo.",["Desactivar NEXO","Retirarse"],[accept,decline],true)
func accept() -> void:
	if state != DuelState.DIALOGUE: return
	actor.prepare_core()
	actor.area.set_lighting(true)
	actor.area.start_intro_camera.call_deferred()
	await super.accept()
	if is_instance_valid(campaign.ui.dialogue_camera): campaign.ui.dialogue_camera.finish()
	if state == DuelState.COMBAT: actor.begin_core()
func decline() -> void:
	super.decline()
	actor.area.set_lighting(false)
func reset_duel() -> void:
	super.reset_duel()
	if not defeated: actor.reset_core()
func _finish() -> void:
	if defeated: return
	actor.shutdown()
	campaign.data["campaign_completed"] = true
	super._finish()
	actor.area.finish_campaign.call_deferred()
