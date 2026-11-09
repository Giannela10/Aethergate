extends Node
var platform: Node
var samples: Dictionary = {}
var ambient: AudioStreamPlayer
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var tick := 0.0
var last_zone := ""
var impact_cooldown := 0.0
static func load_sample(path: String) -> AudioStreamWAV:
	# ResourceLoader follows export remaps; raw WAV is only the unimported fallback.
	if ResourceLoader.exists(path):
		var imported := load(path) as AudioStreamWAV
		if imported!=null: return imported
	return AudioStreamWAV.load_from_file(path) if FileAccess.file_exists(path) else null
func _ready() -> void:
	for id in ["menu","hall","library","casino","laboratory","workshop","elevator","interact","impact","reward","victory","defeat","simulation"]:
		var path: String = "res://assets/audio/v4/"+str(id)+".wav"
		var sample := load_sample(path)
		if sample!=null: samples[id]=sample
	ambient = _player("Ambient"); music = _player("Music"); effect = _player("Effects")
	music.stream = samples.get("menu")
	if music.stream: music.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; music.stream.loop_end=music.stream.data.size()/2
	platform.campaign.gameplay_event.connect(_event)
	platform.campaign.player.hit_received.connect(impact)
	platform.campaign.player.died.connect(func(): play("defeat"))
func _player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new(); player.bus=bus; add_child(player); return player
func play(id: String) -> void:
	if not samples.has(id): return
	effect.stream=samples[id]; effect.play()
	if platform.accessibility.state().subtitles and id in ["simulation","victory","defeat"]:
		platform.campaign.ui.notify({"simulation":"[SONIDO: inicio de simulación]","victory":"[SONIDO: desafío superado]","defeat":"[SONIDO: reintento disponible]"}[id],2)
func impact() -> void:
	if impact_cooldown>0: return
	impact_cooldown=0.15; play("impact")
func _event(kind: String, _id: String, _amount: int) -> void:
	if kind=="duel_started": play("simulation")
	elif kind=="boss": play("victory")
	elif kind in ["collect","education_task","academic_task"]: play("reward")
func _process(delta: float) -> void:
	impact_cooldown=maxf(0,impact_cooldown-delta)
	tick-=delta
	if tick>0: return
	tick=0.5
	var c: Node = platform.campaign
	var zone := "hall"
	var floor_name: String = c.phone._floor_for(c.player)
	if floor_name=="-1" or floor_name=="S": zone="workshop"
	elif floor_name=="3": zone="laboratory"
	elif floor_name=="2" and c.player.global_position.x < -25: zone="library"
	elif floor_name=="1" and c.player.global_position.x < -25: zone="casino"
	if c.player.get_meta("in_elevator",false): zone="elevator"
	if zone!=last_zone and samples.has(zone):
		last_zone=zone; ambient.stream=samples[zone]
		ambient.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD; ambient.stream.loop_end=ambient.stream.data.size()/2
		ambient.play()
	var menu: bool = c.ui.modal and c.active_duel==null
	if menu and not music.playing and music.stream: music.play()
	elif not menu and music.playing: music.stop()
	ambient.volume_db=-12 if c.active_duel!=null else 0
