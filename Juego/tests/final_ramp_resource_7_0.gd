extends Node
func install(parent: Node) -> String:
	parent.add_child(self);run.call_deferred();return "RAMP_RESOURCE_CHECK_STARTED"
func run() -> void:
	var packed=ResourceLoader.load("res://Main.tscn","PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var rows=[]
	if packed!=null:
		var state=packed.get_state()
		for i in state.get_node_count():
			var path=str(state.get_node_path(i)).trim_prefix("./")
			if path!="PisoMenos1/AmbientacionIndustrial2026/RampaVehicularExterior/LosaInclinada" and path!="PisoMenos1/AmbientacionIndustrial2026/RampaVehicularExterior/LosaInclinada/ColisionEstatica/Forma": continue
			var row={"path":path}
			for property in state.get_node_property_count(i):
				var key=state.get_node_property_name(i,property);var value=state.get_node_property_value(i,property)
				if key=="transform": row["transform"]=str(value);row["center_y"]=value.origin.y
				if key=="mesh" or key=="shape": row["size"]=str(value.size);row["length"]=value.size.z
			rows.append(row)
	var ok=rows.size()==2 and rows.all(func(r): return is_equal_approx(r.length,49.06409)) and absf(rows[0].center_y+6.246011)<0.0001
	var out="res://"+FileAccess.get_file_as_string("res://reports/final_7_0/active_run.txt").strip_edges().trim_prefix("Juego/")+"/"
	var file=FileAccess.open(out+"ramp_persisted_resource_check.json",FileAccess.WRITE);file.store_string(JSON.stringify({"passed":ok,"rows":rows,"note":"Fresh PackedScene read from disk, without instantiating campaign or using saves. Confirms persisted geometry, not upper exit approval."},"\t"))
	print("RAMP_PERSISTED_RESOURCE_CHECK ",ok)
