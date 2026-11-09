extends RefCounted
## Authored lofted sneaker geometry. One shared mesh, three surfaces, four skin binds.
static var shared_mesh: ArrayMesh
static var shared_skin: Skin
static var cut_bodies: Dictionary={}
var model: Node3D
var mesh: MeshInstance3D
var tools: Array[SurfaceTool]=[]
var side_index:=0
var foot_center:=Vector3.ZERO
var contact_offset:=0.0
var plants: Dictionary={}
var previous_origin:=Vector3.INF

func install(owner_model: Node3D) -> void:
	model=owner_model
	if shared_mesh==null: _build()
	mesh=MeshInstance3D.new()
	mesh.name="StudentSneakers63"
	mesh.mesh=shared_mesh
	mesh.skin=shared_skin
	model.human.add_child(mesh)
	mesh.skeleton=mesh.get_path_to(model.rig)
	for body in model.human.find_children("*","MeshInstance3D",true,false):
		if str(body.name)=="Body": body.mesh=_covered_body(body.mesh)

static func _covered_body(source: ArrayMesh) -> ArrayMesh:
	var key=source.resource_path
	if key.is_empty():
		var names=[]
		for shape in source.get_blend_shape_count(): names.append(source.get_blend_shape_name(shape))
		key=str(hash([source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],names]))
	if cut_bodies.has(key): return cut_bodies[key]
	var result=ArrayMesh.new()
	result.blend_shape_mode=source.blend_shape_mode
	for i in source.get_blend_shape_count(): result.add_blend_shape(source.get_blend_shape_name(i))
	for surface in source.get_surface_count():
		var arrays=source.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var original: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var indices=PackedInt32Array()
		for t in range(0,original.size(),3):
			if vertices[original[t]].y<0.125 and vertices[original[t+1]].y<0.125 and vertices[original[t+2]].y<0.125: continue
			indices.append_array(PackedInt32Array([original[t],original[t+1],original[t+2]]))
		arrays[Mesh.ARRAY_INDEX]=indices
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,source.surface_get_blend_shape_arrays(surface))
		result.surface_set_material(surface,source.surface_get_material(surface))
	cut_bodies[key]=result
	return result

func apply_profile(profile: Dictionary) -> void:
	var color=Color(preload("res://scripts/juego/character_appearance.gd").COLORS[profile.shoes])
	var sole=StandardMaterial3D.new();sole.albedo_color=Color("eef0ed");sole.roughness=0.94;sole.metallic_specular=0.18
	var upper=StandardMaterial3D.new();upper.albedo_color=Color("c8ced4") if int(profile.shoes)==6 else color;upper.roughness=0.88;upper.metallic_specular=0.20
	upper.roughness_texture=preload("res://scripts/juego/character_surface_6.gd").fabric()
	var trim=StandardMaterial3D.new();trim.albedo_color=Color("3a424b");trim.roughness=0.86;trim.metallic_specular=0.18
	for i in 3:
		var material: StandardMaterial3D=[sole,upper,trim][i]
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		mesh.set_surface_override_material(i,material)
	for old in model.pieces.get("clothing_shoes",[]): old.hide()
	mesh.show()

func _width(z: float) -> float:
	var zs=[-0.075,-0.055,-0.01,0.07,0.125,0.18,0.205]
	var widths=[0.0,0.038,0.044,0.054,0.056,0.040,0.0]
	for i in zs.size()-1:
		if z<=zs[i+1]: return lerpf(widths[i],widths[i+1],smoothstep(zs[i],zs[i+1],z))
	return 0
func _height(z: float) -> float:
	return (0.045+0.065*exp(-pow((z-0.015)/0.075,2)))*sqrt(maxf(0,sin(PI*clampf((z+0.075)/0.28,0,1))))
func _upper(z: float, angle: float) -> Vector3:
	return Vector3(sin(angle)*_width(z),0.027+cos(angle)*_height(z),z)
func _vertex(st: SurfaceTool, point: Vector3) -> void:
	var toe=smoothstep(0.085,0.18,point.z)
	st.set_bones(PackedInt32Array([side_index*2,side_index*2+1,0,0]))
	st.set_weights(PackedFloat32Array([1.0-toe,toe,0,0]))
	st.set_uv(Vector2(point.x*8+0.5,(point.z+0.075)/0.28))
	st.add_vertex(Vector3(point.x+foot_center.x,point.y,point.z+foot_center.z))
func _tri(surface: int, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b-a).cross(c-a).length_squared()<0.000000000001: return
	for p in [a,c,b]: _vertex(tools[surface],p)
func _quad(surface: int, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(surface,a,c,b);_tri(surface,a,d,c)
func _tube(surface: int, points: Array[Vector3], radius: float) -> void:
	for i in points.size()-1:
		var axis=(points[i+1]-points[i]).normalized()
		var right=axis.cross(Vector3.UP).normalized()
		if right.length_squared()<0.1: right=Vector3.RIGHT
		var up=right.cross(axis).normalized()
		for k in 6:
			var a=TAU*float(k)/6;var b=TAU*float(k+1)/6
			var first=(right*cos(a)+up*sin(a))*radius
			var second=(right*cos(b)+up*sin(b))*radius
			_quad(surface,points[i]+first,points[i]+second,points[i+1]+second,points[i+1]+first)

func _build() -> void:
	for i in 3:
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);tools.append(st)
	shared_skin=Skin.new()
	for label in ["foot_l","ball_l","foot_r","ball_r"]:
		var bone=model.rig.find_bone(label)
		shared_skin.add_bind(bone,model.rig.get_bone_global_rest(bone).affine_inverse())
	for side in 2:
		side_index=side
		foot_center=model.rig.get_bone_global_rest(model.rig.find_bone("foot_l" if side==0 else "foot_r")).origin
		var outline: Array[Vector3]=[]
		for i in 29:
			var z=lerpf(-0.075,0.205,float(i)/28)
			outline.append(Vector3(-_width(z),0,z))
		for i in range(27,0,-1):
			var z=lerpf(-0.075,0.205,float(i)/28)
			outline.append(Vector3(_width(z),0,z))
		for i in outline.size():
			var a=outline[i];var b=outline[(i+1)%outline.size()]
			for tier in 3:
				var ys=[0.0,0.006,0.023,0.028];var widths=[0.96,1.02,1.01,0.96]
				_quad(2 if tier==0 else 0,Vector3(a.x*widths[tier],ys[tier],a.z),Vector3(b.x*widths[tier],ys[tier],b.z),Vector3(b.x*widths[tier+1],ys[tier+1],b.z),Vector3(a.x*widths[tier+1],ys[tier+1],a.z))
			_tri(0,Vector3(0,0.028,0.06),Vector3(a.x*0.96,0.028,a.z),Vector3(b.x*0.96,0.028,b.z))
			_tri(2,Vector3(0,0,0.06),b,a)
		for j in 28:
			var z0=lerpf(-0.075,0.205,float(j)/28);var z1=lerpf(-0.075,0.205,float(j+1)/28)
			for i in 18:
				var a=lerpf(-PI*0.5,PI*0.5,float(i)/18);var b=lerpf(-PI*0.5,PI*0.5,float(i+1)/18)
				if z0> -0.035 and z1<0.055 and absf((a+b)*0.5)<0.65: continue
				_quad(1,_upper(z0,a),_upper(z0,b),_upper(z1,b),_upper(z1,a))
		var collar: Array[Vector3]=[]
		for i in 25:
			var angle=TAU*float(i)/24
			collar.append(Vector3(cos(angle)*0.031,0.116+sin(angle)*0.008,0.012+sin(angle)*0.043))
		_tube(2,collar,0.003)
		for j in 8:
			var z0=lerpf(0.025,0.15,float(j)/8);var z1=lerpf(0.025,0.15,float(j+1)/8)
			for i in 6:
				var x0=lerpf(-0.027,0.027,float(i)/6);var x1=lerpf(-0.027,0.027,float(i+1)/6)
				var points=[]
				for pair in [Vector2(x0,z0),Vector2(x1,z0),Vector2(x1,z1),Vector2(x0,z1)]:
					points.append(Vector3(pair.x,0.031+_height(pair.y)*sqrt(maxf(0.05,1-pow(pair.x/maxf(_width(pair.y),0.001),2))),pair.y))
				_quad(1,points[0],points[1],points[2],points[3])
		for lace in 5:
			var z=0.046+lace*0.022
			var points: Array[Vector3]=[]
			for i in 9:
				var x=lerpf(-0.032,0.032,float(i)/8)
				var at_z=z+x*0.22
				var y=0.031+_height(at_z)*sqrt(maxf(0.05,1-pow(x/maxf(_width(at_z),0.001),2)))
				points.append(Vector3(x,y,at_z))
			_tube(0,points,0.0017)
		# Heel counter and rounded toe bumper are authored patch surfaces.
		for i in 12:
			var a=lerpf(-PI*0.5,PI*0.5,float(i)/12);var b=lerpf(-PI*0.5,PI*0.5,float(i+1)/12)
			for j in 4:
				var z0=lerpf(-0.058,-0.037,float(j)/4);var z1=lerpf(-0.058,-0.037,float(j+1)/4)
				_quad(2,_upper(z0,a)*Vector3(1.025,1.025,1),_upper(z0,b)*Vector3(1.025,1.025,1),_upper(z1,b)*Vector3(1.025,1.025,1),_upper(z1,a)*Vector3(1.025,1.025,1))
	shared_mesh=ArrayMesh.new()
	for st in tools:
		st.generate_normals();st.index();st.commit(shared_mesh)

func resolve_contact(poses: Array[Transform3D], delta: float) -> void:
	var actor: Node3D=model.host.get_parent()
	if not model.host.was_on_floor or model.host.dead:
		plants.clear();contact_offset=move_toward(contact_offset,0.0,delta*2)
		return
	if previous_origin!=Vector3.INF and actor.global_position.distance_to(previous_origin)>0.75: plants.clear()
	previous_origin=actor.global_position
	var supports=[]
	var target_offset=INF
	for side in ["l","r"]:
		var foot=model.rig.find_bone("foot_"+side)
		var ball=model.rig.find_bone("ball_"+side)
		var rest: Transform3D=model.rests[foot]
		var foot_matrix=poses[foot]*rest.affine_inverse()
		var ball_matrix=poses[ball]*model.rests[ball].affine_inverse()
		var bottom=INF
		for pair in [Vector2(0,-0.075),Vector2(-0.044,-0.01),Vector2(0.044,-0.01),Vector2(-0.054,0.10),Vector2(0.054,0.10),Vector2(0,0.205)]:
			var point=Vector3(rest.origin.x+pair.x,0,rest.origin.z+pair.y)
			var t=smoothstep(0.085,0.18,pair.y)
			var world: Vector3=model.rig.global_transform*((foot_matrix*point).lerp(ball_matrix*point,t))
			bottom=minf(bottom,world.y)
		var ankle: Vector3=model.rig.global_transform*poses[foot].origin
		var ray=PhysicsRayQueryParameters3D.create(ankle+Vector3.UP*0.50,ankle-Vector3.UP*0.70)
		if actor is CollisionObject3D: ray.exclude=[actor.get_rid()]
		var hit=model.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y<0.75:
			plants.erase(side);continue
		var visible_y=preload("res://scripts/juego/character_ground_6_3.gd").height_at(model,ankle,hit.position.y)
		var clearance=bottom-visible_y
		if clearance>0.25 or clearance< -0.22:
			plants.erase(side);continue
		var correction=visible_y+0.004-bottom
		target_offset=minf(target_offset,correction)
		supports.append({"side":side,"foot":foot,"ball":ball,"ankle":ankle,"hit":hit,"correction":correction})
	if target_offset==INF: target_offset=0.0
	# Authored NPC spawn offsets can be 0.12 m above the walking surface.
	contact_offset=move_toward(contact_offset,clampf(target_offset,-0.20,0.20),delta*2.5)
	var shift: Vector3=model.rig.global_basis.inverse()*(Vector3.UP*contact_offset)
	for i in poses.size(): poses[i].origin+=shift
	for support in supports:
		var target: Vector3=support.ankle+Vector3.UP*support.correction
		var side: String=support.side
		var moving=model.host.visual_speed>0.2
		if moving:
			if plants.has(side):
				var plant: Dictionary=plants[side]
				plant.age+=delta
				if is_instance_valid(plant.collider):
					var platform_delta: Vector3=plant.collider.global_position-plant.platform
					if platform_delta.length()<0.25: plant.point+=platform_delta
					plant.platform=plant.collider.global_position
				if plant.age>0.48 or plant.point.distance_to(target)>0.30 or plant.collider!=support.hit.collider: plants.erase(side)
			if not plants.has(side): plants[side]={"point":target,"age":0.0,"collider":support.hit.collider,"platform":support.hit.collider.global_position}
			target=plants[side].point
		else: plants.erase(side)
		var thigh=model.rig.find_bone("thigh_"+side)
		var calf=model.rig.find_bone("calf_"+side)
		var local_target: Vector3=model.rig.to_local(target)
		var upper_length=model.rests[calf].origin.distance_to(model.rests[thigh].origin)
		var lower_length=model.rests[support.foot].origin.distance_to(model.rests[calf].origin)
		if poses[thigh].origin.distance_to(local_target)>(upper_length+lower_length)*0.999:
			plants.erase(side)
			local_target=model.rig.to_local(support.ankle+Vector3.UP*support.correction)
		_solve_leg(poses,thigh,calf,support.foot,support.ball,local_target,upper_length,lower_length)

func _solve_leg(poses: Array[Transform3D], thigh: int, calf: int, foot: int, ball: int, target: Vector3, upper_length: float, lower_length: float) -> void:
	var hip=poses[thigh].origin
	var old_knee=poses[calf].origin
	var old_ankle=poses[foot].origin
	var distance=clampf(hip.distance_to(target),0.05,upper_length+lower_length-0.0001)
	var direction=(target-hip).normalized()
	var pole=old_knee-hip-direction*(old_knee-hip).dot(direction)
	if pole.length()<0.001: pole=Vector3.BACK-direction*Vector3.BACK.dot(direction)
	pole=pole.normalized()
	var along=(upper_length*upper_length-lower_length*lower_length+distance*distance)/(2*distance)
	var knee=hip+direction*along+pole*sqrt(maxf(0,upper_length*upper_length-along*along))
	var ankle=hip+direction*distance
	poses[thigh].basis=Basis(Quaternion((old_knee-hip).normalized(),(knee-hip).normalized()))*poses[thigh].basis
	poses[calf].basis=Basis(Quaternion((old_ankle-old_knee).normalized(),(ankle-knee).normalized()))*poses[calf].basis
	poses[calf].origin=knee
	poses[foot].origin=ankle
	poses[ball].origin+=ankle-old_ankle
