extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var scene=load("res://Main.tscn").instantiate()
 root.add_child(scene)
 for stair in scene.find_children("Escalera*","Node3D",true,false):
  var bounds=AABB()
  var found=false
  for step in stair.find_children("Step*","MeshInstance3D",true,false):
   var b=step.global_transform*step.get_aabb()
   bounds=b if not found else bounds.merge(b)
   found=true
  if found: print(stair.get_path()," ",bounds)
 quit()
