extends Node3D
var camera: Camera3D
func _ready(): run.call_deferred()
func run():
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-20,0);add_child(light)
 camera=Camera3D.new();camera.position=Vector3(0,5,14);add_child(camera);camera.look_at(Vector3(0,1,0));camera.make_current()
 var floor=StaticBody3D.new();add_child(floor)
 var col=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(100,0.1,100);col.shape=box;col.position.y=-0.05;floor.add_child(col)
 var player=Node3D.new();player.add_to_group("player");add_child(player)
 var bridge=load("res://scripts/juego/npc_visual_6_3.gd")
 var rows=[]
 var ids=[]
 for i in 30: ids.append("benchmark63_"+str(i))
 for variant in ["before","after"]:
  bridge.config={"enabled":variant=="after","batch":2,"pilot_ids":ids}
  for count in [1,5,15,30]:
   var actors=[]
   for i in count:
    var actor=Node3D.new();actor.name="Actor"+str(i);add_child(actor);actor.position=Vector3((i%6-2.5)*1.5,0,-float(i/6)*2)
    var visual=load("res://scripts/juego/student_visual.gd").new();visual.scale=Vector3.ONE*1.5;actor.add_child(visual)
    var presets=load("res://scripts/juego/character_visual_presets.gd")
    presets.apply(visual,presets.create(ids[i],"ESTUDIANTE"))
    actors.append(actor)
   for i in 3: await get_tree().process_frame
   var start=Time.get_ticks_msec()
   while Time.get_ticks_msec()-start<1500:
    for actor in actors: actor.get_child(0).animate(0.016,Vector3(0,0,-2.5),true,false)
    await get_tree().process_frame
   var samples=[];var draws=[];var elapsed=0.0
   for i in 180:
    var begin=Time.get_ticks_usec()
    for actor in actors: actor.get_child(0).animate(1.0/60.0,Vector3(0,0,-2.5),true,false)
    await get_tree().process_frame
    samples.append((Time.get_ticks_usec()-begin)/1000.0)
    draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
   samples.sort();draws.sort()
   var remodelled=0
   for actor in actors:
    if actor.get_child(0).has_meta("remodel63"): remodelled+=1
   rows.append({"variant":variant,"count":count,"median_ms":samples[90],"p95_ms":samples[171],"fps_from_median":1000.0/samples[90],"draw_calls":draws[90],"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"video_memory":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"remodelled":remodelled})
   for actor in actors: actor.queue_free()
   await get_tree().process_frame
   print("BENCH63 ",variant," ",count," ",rows[-1].median_ms)
 var out=FileAccess.open("res://reports/characters_6_3/benchmark.json",FileAccess.WRITE);out.store_string(JSON.stringify(rows,"\t"));out.close()
 print("BENCH63_DONE")
