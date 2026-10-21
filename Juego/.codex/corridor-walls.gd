extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var s=load("res://Main.tscn").instantiate()
 root.add_child(s)
 for level in ["Piso1","Piso2","Piso 3","Piso 4"]:
  for m in s.get_node(level).get_children():
   if m is MeshInstance3D and m.is_visible_in_tree() and not "Floor" in str(m.name):
    var b=m.global_transform*m.get_aabb()
    if minf(b.size.x,b.size.z)<1 and b.size.y>5: print(m.get_path()," ",b)
 quit()
