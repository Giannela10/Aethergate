extends RefCounted
## Immutable smooth surfaces shared across actors. No skeleton or collision changes.
static var cache: Dictionary = {}
static func fabric() -> NoiseTexture2D:
	if cache.has("fabric"): return cache.fabric
	var noise := FastNoiseLite.new()
	noise.seed=600
	noise.frequency=0.18
	var texture := NoiseTexture2D.new()
	texture.width=128
	texture.height=128
	texture.noise=noise
	var ramp := Gradient.new()
	ramp.set_color(0,Color(0.86,0.86,0.86))
	ramp.set_color(1,Color.WHITE)
	texture.color_ramp=ramp
	cache.fabric=texture
	return texture
static func contour(key: String, rings: Array, depth: float, segments: int = 20) -> ArrayMesh:
	if cache.has(key): return cache[key]
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	for j in rings.size():
		var ring: Vector2 = rings[j]
		var previous: Vector2 = rings[maxi(0,j-1)]
		var next: Vector2 = rings[mini(rings.size()-1,j+1)]
		var slope := (next.y-previous.y)/maxf(next.x-previous.x,0.001)
		for i in segments+1:
			var angle := TAU*float(i)/segments
			vertices.append(Vector3(cos(angle)*ring.y,ring.x,sin(angle)*ring.y*depth))
			normals.append(Vector3(cos(angle),-slope,sin(angle)/depth).normalized())
			uv.append(Vector2(float(i)/segments,float(j)/(rings.size()-1)))
	for j in rings.size()-1:
		for i in segments:
			var a := j*(segments+1)+i
			var b := a+segments+1
			indices.append_array(PackedInt32Array([a,a+1,b,a+1,b+1,b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uv
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	cache[key]=mesh
	return mesh

static func fingers() -> ArrayMesh:
	if cache.has("fingers"): return cache.fingers
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4:
		var capsule := CapsuleMesh.new()
		capsule.radius=0.008
		capsule.height=0.043-absf(i-1.5)*0.004
		capsule.radial_segments=8
		capsule.rings=2
		tool.append_from(capsule,0,Transform3D(Basis.IDENTITY,Vector3((i-1.5)*0.016,-0.038,-0.002)))
	var mesh := tool.commit()
	cache.fingers=mesh
	return mesh
