extends Node
enum Phase { NORMAL, ANOMALY_LOW, ANOMALY_MEDIUM, ANOMALY_HIGH, RESTORED }
signal changed(previous: int, current: int)
var hub: Node
var phase := Phase.NORMAL
var tick := 0.0
static func derive(data: Dictionary) -> int:
	if data.get("bosses",{}).get("nexo",false) == true or data.get("campaign_completed",false) == true:
		return Phase.RESTORED
	var flags: Dictionary = data.get("decision_flags",{}) if data.get("decision_flags",{}) is Dictionary else {}
	if data.get("bosses",{}).get("director",false) == true: return Phase.ANOMALY_HIGH
	var explicit := clampi(int(flags.get("nexo_stage",0)),0,3)
	if explicit > 0: return explicit
	if data.get("computers",{}).get("pc6",false) == true or data.get("bosses",{}).get("profesor_lenguaje",false) == true: return Phase.ANOMALY_MEDIUM
	if int(data.get("events",{}).get("story:nexo_redes",0)) > 0 or data.get("computers",{}).get("pc3",false) == true:
		return Phase.ANOMALY_LOW
	return Phase.NORMAL
func refresh() -> void:
	var next := derive(hub.campaign.data)
	if next != phase:
		var old := phase
		phase = next
		changed.emit(old,phase)
func _process(delta: float) -> void:
	tick += delta
	if tick >= 2:
		tick = 0
		refresh()
func context() -> Dictionary:
	var data: Dictionary = hub.campaign.data
	return {"phase":phase,"time":hub.campaign.academics.current_time(),"floor":hub.floor_id(),"bosses":data.bosses,"decisions":data.get("decision_flags",{}),"reputation":data.get("reputation",data.get("reputacion",{})),"weather":data.get("weather","clear")}
func ambient_line() -> String:
	var ctx := context()
	if str(ctx.weather).to_lower() in ["rain","rainy","lluvia"]: return "Está lloviendo; podemos reunirnos dentro para estudiar."
	if ctx.reputation is Dictionary and float(ctx.reputation.get("campus",0)) < -20: return "Se comenta lo ocurrido en el campus. Mejor conversar con calma."
	if ctx.decisions is Dictionary and ctx.decisions.get("helped_technician",false): return "El técnico agradeció la ayuda con los equipos."
	if phase == Phase.RESTORED: return "Las pantallas funcionan otra vez. Se siente más tranquilo."
	if hub.campaign.data.bosses.get("director",false): return "Encontraron algo extraño en el subterráneo."
	if phase >= Phase.ANOMALY_MEDIUM: return "Arriba siguen revisando los sistemas. Mejor guardar el trabajo."
	if phase == Phase.ANOMALY_LOW: return "¿También viste ese pequeño fallo en la pantalla?"
	if int(hub.campaign.academics.current_time().minute) in range(720,840): return "Podemos conversar después de almorzar."
	if hub.campaign.data.bosses.get("chef",false): return "El casino está retomando su ritmo habitual."
	if hub.floor_id() == "3" and hub.campaign.quests.state("infectado") == 1: return "El técnico está revisando el computador que falló."
	return "Nos vemos después de la próxima clase."
