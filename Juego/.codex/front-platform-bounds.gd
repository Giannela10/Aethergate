extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var s=load("res://Main.tscn").instantiate()
 root.add_child(s)
 var v=AABB(Vector3(65,0,-163),Vector3(22,48,88))
 for m in s.find_children("*","MeshInstance3D",true,false):
  var b=m.global_transform*m.get_aabb()
  if m.is_visible_in_tree() and b.intersects(v) and not "Step" in str(m.name): print(m.get_path()," ",b)
 quit()
