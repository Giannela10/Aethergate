extends Node
var f: Node
func install(parent: Node) -> String:
	f=parent;parent.add_child(self);run.call_deferred();return "FINAL70_RAMP_DIAGNOSTIC_STARTED"
func run() -> void:
	var ramp=f.campus.get_node("PisoMenos1/AmbientacionIndustrial2026/RampaVehicularExterior")
	var deck=ramp.get_node("LosaInclinada")
	var before={"transform":str(deck.global_transform),"size":str(deck.mesh.size)}
	var rise=12.058385849;var run_length=46.94;var angle=atan(rise/run_length)
	var corrected=[]
	for child in ramp.get_children():
		if child is Node3D and child.rotation.x< -0.1:
			child.rotation.x=angle;corrected.append(str(child.name))
	deck.position.y=-rise*0.5-0.21/cos(angle)
	deck.mesh=deck.mesh.duplicate();deck.mesh.size.z=sqrt(rise*rise+run_length*run_length)+0.6
	var collision=deck.get_node("ColisionEstatica/Forma")
	collision.shape=collision.shape.duplicate();collision.shape.size=deck.mesh.size
	await get_tree().physics_frame
	var helper=f.get_children().filter(func(n): return n.get_script()!=null and n.get_script().resource_path.ends_with("final_probe_7_0.gd"))[0]
	await helper.walk(Vector3(24.37,-11.9,-114),Vector3(24.37,0,-164),"ramp_corrected_diagnostic",28)
	var data={"before":before,"after":{"transform":str(deck.global_transform),"size":str(deck.mesh.size)},"rotated_nodes":corrected,"route":helper.rows[-1],"arrival":str(f.player.global_position)}
	var file=FileAccess.open(f.out+"ramp_diagnostic.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"\t"))
	await f.shot("ramp_corrected_lower",Vector3(24.37,-9.8,-114),Vector3(24.37,-8,-130))
	await f.shot("ramp_corrected_upper",Vector3(24.37,-1,-150),Vector3(24.37,1,-165))
	print("FINAL70_RAMP_DIAGNOSTIC_DONE ",helper.rows[-1].passed)
