extends RefCounted
## Shared curved headband and ear cups; no physics or interaction nodes.
static var cached: ArrayMesh
static var material: StandardMaterial3D
static func geometry() -> ArrayMesh:
	if cached!=null: return cached
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in 24:
		var a=PI*float(segment)/24;var b=PI*float(segment+1)/24
		var ca=Vector3(cos(a)*0.11,sin(a)*0.135,0)
		var cb=Vector3(cos(b)*0.11,sin(b)*0.135,0)
		for ring in 8:
			var u=TAU*float(ring)/8;var v=TAU*float(ring+1)/8
			var pa=ca+(Vector3(cos(a),sin(a),0)*cos(u)+Vector3.BACK*sin(u))*0.007
			var qa=ca+(Vector3(cos(a),sin(a),0)*cos(v)+Vector3.BACK*sin(v))*0.007
			var pb=cb+(Vector3(cos(b),sin(b),0)*cos(u)+Vector3.BACK*sin(u))*0.007
			var qb=cb+(Vector3(cos(b),sin(b),0)*cos(v)+Vector3.BACK*sin(v))*0.007
			for point in [pa,pb,qa,qa,pb,qb]: st.add_vertex(point)
	st.generate_normals();st.index();cached=st.commit()
	var combined=SurfaceTool.new();combined.begin(Mesh.PRIMITIVE_TRIANGLES);combined.append_from(cached,0,Transform3D.IDENTITY)
	var cup=SphereMesh.new();cup.radius=0.028;cup.height=0.056;cup.radial_segments=12;cup.rings=6
	for side in [-1,1]: combined.append_from(cup,0,Transform3D(Basis.IDENTITY.scaled(Vector3(0.6,1.1,0.9)),Vector3(side*0.11,0,0)))
	cached=combined.commit()
	return cached
static func finish() -> StandardMaterial3D:
	if material==null:
		material=StandardMaterial3D.new();material.albedo_color=Color("34495b");material.roughness=0.75;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	return material
