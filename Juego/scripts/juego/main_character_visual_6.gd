extends "res://scripts/juego/student_visual.gd"
## Player-only authored surfaces. Existing joints, sockets and timing are inherited.
var wardrobe6: Array[Node] = []
var hair6: Array[Node] = []
var fingers6: Array[MeshInstance3D] = []

func _build_head() -> void:
	var mesh := Surface6.contour("player_skull60",[Vector2(-0.012,0),Vector2(0,0.040),Vector2(0.025,0.066),Vector2(0.055,0.080),Vector2(0.087,0.091),Vector2(0.12,0.090),Vector2(0.155,0.087),Vector2(0.185,0.077),Vector2(0.212,0.048),Vector2(0.226,0)],0.96,40).duplicate() as ArrayMesh
	# Sculpt the front into cheekbones, recessed sockets, forehead and chin.
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var v := vertices[i]
		if v.z<0:
			var front := pow(maxf(0,-v.z/maxf(0.001,Vector2(v.x,v.z).length())),5)
			v.z += front*(0.007*exp(-pow((v.y-0.116)/0.023,2))-0.008*exp(-pow((v.y-0.051)/0.032,2)))
		vertices[i]=v
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=null
	var sculpt := ArrayMesh.new()
	sculpt.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var tool := SurfaceTool.new()
	tool.create_from(sculpt,0)
	tool.generate_normals()
	var face := _node(head_pivot,tool.commit(),Vector3.ZERO,skin_color,Vector3.ONE,0.82)
	face.name="FaceContour6"
	for side in [-1.0,1.0]:
		var eye := _ball(head_pivot,0.013,Vector3(side*0.035,0.115,-0.076),Color("e5e2d8"),Vector3(1.08,0.48,0.50),0.38)
		eyes.append({"mesh":eye,"height":eye.scale.y})
		var iris=_ball(head_pivot,0.0056,Vector3(side*0.035,0.115,-0.0825),Color("526753"),Vector3(1,1,0.35),0.4)
		var pupil=_ball(head_pivot,0.0028,Vector3(side*0.035,0.115,-0.084),Color("111819"),Vector3(1,1,0.3),0.3)
		var glint=_ball(head_pivot,0.0012,Vector3(side*0.0335,0.117,-0.085),Color.WHITE,Vector3.ONE,0.2)
		for ocular in [iris,pupil,glint]: eyes.append({"mesh":ocular,"height":ocular.scale.y})
		for upper in [true,false]:
			var points: Array[Vector3]=[]
			for i in 9:
				var x := float(i)/8*2-1
				points.append(Vector3(side*0.035+x*0.015,0.115+(0.006 if upper else -0.004)*sqrt(maxf(0,1-x*x)),-0.079-0.003*(1-x*x)))
			_curve(head_pivot,points,0.0018,skin_color,"HEAD")
		var brow := _curve(head_pivot,[Vector3(side*0.018,0.135,-0.079),Vector3(side*0.033,0.139,-0.079),Vector3(side*0.049,0.135,-0.073)],0.0028,hair_color,"HEAD")
		eyebrows.append(brow)
		var ear := _ball(head_pivot,0.021,Vector3(side*0.092,0.092,0.002),skin_color,Vector3(0.52,1.15,0.72),0.84)
		ear.name="Auricle6"
		_ball(head_pivot,0.012,Vector3(side*0.101,0.095,-0.005),skin_color.darkened(0.06),Vector3(0.3,1.1,0.6),0.9)
		_curve(head_pivot,[Vector3(side*0.103,0.075,-0.004),Vector3(side*0.106,0.092,-0.01),Vector3(side*0.103,0.109,-0.005)],0.0028,skin_color,"HEAD")
		_ball(head_pivot,0.009,Vector3(side*0.009,0.082,-0.09),skin_color,Vector3(0.8,0.55,0.8),0.82)
	var nose := Surface6.contour("player_nose60",[Vector2(0.075,0),Vector2(0.079,0.008),Vector2(0.086,0.011),Vector2(0.095,0.007),Vector2(0.12,0.004),Vector2(0.132,0)],1.3,16)
	_node(head_pivot,nose,Vector3(0,0,-0.084),skin_color.darkened(0.06),Vector3.ONE,0.82)
	_ball(head_pivot,0.008,Vector3(0,0.086,-0.098),skin_color,Vector3(1,0.7,0.8),0.82)
	mouth=_curve(head_pivot,[Vector3(-0.019,0,0.004),Vector3(-0.008,0.002,-0.002),Vector3(0,0,-0.003),Vector3(0.008,0.002,-0.002),Vector3(0.019,0,0.004)],0.002,Color("995e54"),"HEAD")
	mouth.position=Vector3(0,0.049,-0.08)
	_curve(head_pivot,[Vector3(-0.017,0.047,-0.078),Vector3(0,0.044,-0.083),Vector3(0.017,0.047,-0.078)],0.0025,Color("b37768"),"HEAD")
	# Animation code positions brows at y=.135; keep their geometry local.
	for brow in eyebrows:
		brow.position.y=0.135
		var a := brow.mesh.surface_get_arrays(0)
		var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		for i in v.size(): v[i].y-=0.135
		a[Mesh.ARRAY_VERTEX]=v
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
		brow.mesh=m

func _curve(parent: Node3D, points: Array[Vector3], radius: float, color: Color, module: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size()-1:
		var delta := points[i+1]-points[i]
		var axis := delta.normalized()
		var tangent := axis.cross(Vector3.FORWARD).normalized()
		if tangent.length_squared()<0.01: tangent=Vector3.RIGHT
		var cross_axis := tangent.cross(axis).normalized()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=radius*0.75
		cylinder.bottom_radius=radius
		cylinder.height=delta.length()
		cylinder.radial_segments=8
		st.append_from(cylinder,0,Transform3D(Basis(tangent,axis,cross_axis), (points[i]+points[i+1])*0.5))
	var result := _node(parent,st.commit(),Vector3.ZERO,color,Vector3.ONE,0.9)
	result.set_meta("visual_module",module)
	return result

func _build() -> void:
	super._build()
	for joint in [spine,chest]:
		for child in joint.get_children():
			if child is MeshInstance3D and child.material_override.albedo_color.is_equal_approx(shirt_color):
				joint.remove_child(child)
				child.free()
	_node(spine,Surface6.contour("player_abdomen60",[Vector2(0,0),Vector2(0.005,0.137),Vector2(0.08,0.141),Vector2(0.20,0.154),Vector2(0.24,0.16),Vector2(0.25,0)],0.76,32),Vector3.ZERO,shirt_color,Vector3.ONE,0.92)
	_node(chest,Surface6.contour("player_torso60b",[Vector2(-0.015,0),Vector2(0,0.15),Vector2(0.08,0.164),Vector2(0.18,0.181),Vector2(0.23,0.18),Vector2(0.265,0.158),Vector2(0.295,0.10),Vector2(0.315,0.057),Vector2(0.32,0)],0.78,32),Vector3.ZERO,shirt_color,Vector3.ONE,0.92)

func _build_arm(side: float) -> Array:
	var joints := super._build_arm(side)
	for joint in [joints[0],joints[1]]:
		for child in joint.get_children():
			if child is MeshInstance3D:
				joint.remove_child(child)
				child.free()
	_node(joints[0],Surface6.contour("player_upperarm60",[Vector2(-0.29,0),Vector2(-0.28,0.035),Vector2(-0.23,0.041),Vector2(-0.14,0.05),Vector2(-0.04,0.055),Vector2(0.015,0.048),Vector2(0.045,0)],0.93,24),Vector3.ZERO,skin_color,Vector3.ONE,0.84)
	_node(joints[0],Surface6.contour("player_shortsleeve60",[Vector2(-0.15,0.051),Vector2(-0.14,0.056),Vector2(-0.08,0.062),Vector2(0,0.057),Vector2(0.04,0.033),Vector2(0.048,0)],0.98,24),Vector3.ZERO,shirt_color,Vector3.ONE,0.93)
	_node(joints[1],Surface6.contour("player_forearm60",[Vector2(-0.28,0),Vector2(-0.26,0.025),Vector2(-0.22,0.029),Vector2(-0.12,0.036),Vector2(-0.04,0.039),Vector2(0.012,0.033),Vector2(0.028,0)],0.83,24),Vector3.ZERO,skin_color,Vector3.ONE,0.84)
	# Replace the spherical fist; preserve the wrist and every socket transform.
	for mesh in joints[2].get_children():
		if mesh is MeshInstance3D:
			joints[2].remove_child(mesh)
			mesh.free()
	_node(joints[2],Surface6.contour("player_palm60",[Vector2(-0.035,0),Vector2(-0.03,0.027),Vector2(0,0.032),Vector2(0.025,0.022),Vector2(0.032,0)],0.53,16),Vector3.ZERO,skin_color,Vector3(1,1,1),0.83)
	fingers6.append(_node(joints[2],Surface6.fingers(),Vector3.ZERO,skin_color,Vector3.ONE,0.83))
	_curve(joints[2],[Vector3(-side*0.022,0.012,0),Vector3(-side*0.039,-0.005,-0.012),Vector3(-side*0.035,-0.025,-0.022)],0.009,skin_color,"BODY")
	return joints

func _build_leg(side: float) -> Array:
	var joints := super._build_leg(side)
	for joint in joints:
		for child in joint.get_children():
			if child is MeshInstance3D:
				joint.remove_child(child)
				child.free()
	_node(joints[0],Surface6.contour("player_denim_thigh60",[Vector2(-0.46,0),Vector2(-0.445,0.058),Vector2(-0.39,0.062),Vector2(-0.28,0.074),Vector2(-0.14,0.084),Vector2(-0.03,0.087),Vector2(0.03,0.07),Vector2(0.045,0)],0.90,28),Vector3.ZERO,pants_color,Vector3.ONE,0.94)
	_node(joints[1],Surface6.contour("player_denim_calf60",[Vector2(-0.435,0.04),Vector2(-0.405,0.043),Vector2(-0.32,0.048),Vector2(-0.22,0.057),Vector2(-0.10,0.061),Vector2(-0.02,0.057),Vector2(0.018,0.05),Vector2(0.025,0)],0.90,28),Vector3.ZERO,pants_color,Vector3.ONE,0.94)
	var sole := _node(joints[2],Surface6.contour("player_sole60",[Vector2(-0.08,0),Vector2(-0.078,0.049),Vector2(-0.062,0.052),Vector2(-0.054,0.048),Vector2(-0.05,0)],2.65,28),Vector3(0,0,-0.067),SHOE_SOLE,Vector3.ONE,0.96)
	sole.name="SneakerSole60"
	_node(joints[2],Surface6.contour("player_sneaker60",[Vector2(-0.06,0),Vector2(-0.058,0.047),Vector2(-0.04,0.047),Vector2(-0.02,0.039),Vector2(0.012,0.025),Vector2(0.02,0)],2.5,28),Vector3(0,0,-0.058),SHOE_UPPER,Vector3.ONE,0.91)
	return joints

func _ready() -> void:
	super._ready()
	var old_bag=backpack_socket.get_node_or_null("Mochila")
	if old_bag:
		backpack_socket.remove_child(old_bag)
		old_bag.free()
	var bag=_node(backpack_socket,Surface6.contour("player_backpack60",[Vector2(-0.25,0),Vector2(-0.235,0.115),Vector2(-0.18,0.165),Vector2(0.10,0.163),Vector2(0.19,0.13),Vector2(0.23,0.065),Vector2(0.24,0)],0.62,28),Vector3(0,0,0.05),Color("bb874e"),Vector3.ONE,0.94)
	bag.name="Mochila"
	_capture_modules()
	set_meta("main_character_remodel","6.0")

func apply_appearance(profile: Dictionary) -> void:
	for part in wardrobe6+hair6:
		if is_instance_valid(part):
			part.get_parent().remove_child(part)
			part.free()
	wardrobe6.clear()
	hair6.clear()
	super.apply_appearance(profile)
	for part in appearance_adapter.parts:
		var node: MeshInstance3D=part.mesh
		if node.get_parent() in [shoulder_l,shoulder_r,elbow_l,elbow_r]:
			node.visible=int(profile.top)==0
	for extra in appearance_adapter.extras:
		if extra.get_meta("visual_module","")=="HAIR": extra.visible=false
	var cloth := Color(preload("res://scripts/juego/character_appearance.gd").COLORS[profile.clothes])
	var hair := Color(preload("res://scripts/juego/character_appearance.gd").HAIR[profile.hair_color])
	var style := int(profile.hair)
	if style!=2:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cap := Surface6.contour("player_hair60",[Vector2(0.139,0.092),Vector2(0.172,0.092),Vector2(0.205,0.074),Vector2(0.229,0.035),Vector2(0.233,0)],1.0,32)
		st.append_from(cap,0,Transform3D.IDENTITY)
		for i in 22:
			var angle := TAU*float(i)/22
			var lock := SphereMesh.new()
			lock.radius=1
			lock.height=2
			lock.radial_segments=10
			lock.rings=5
			var long_style := 1.0 if style==1 else 0.45 if style==4 else 0.0
			var pos := Vector3(cos(angle)*0.077,0.181+sin(angle*3)*0.01,sin(angle)*0.072)
			if sin(angle)>-0.35: pos.y-=long_style*0.04
			var basis := Basis.from_euler(Vector3(0.2*cos(angle),angle,-0.35*cos(angle))).scaled(Vector3(0.019,0.049+long_style*0.047,0.019))
			st.append_from(lock,0,Transform3D(basis,pos))
		var locks := _node(head_pivot,st.commit(),Vector3.ZERO,hair,Vector3.ONE,0.77)
		locks.name="LayeredHair60"
		hair6.append(locks)
	# Cloth detail belongs to the current selected garment; existing choices remain.
	if int(profile.top)==1:
		wardrobe6.append(_node(chest,Surface6.contour("hood_fold60",[Vector2(-0.075,0),Vector2(-0.065,0.064),Vector2(-0.02,0.099),Vector2(0.035,0.11),Vector2(0.06,0.074),Vector2(0.065,0)],0.55,24),Vector3(0,0.24,0.12),cloth,Vector3.ONE,0.95))
		wardrobe6.append(_node(chest,Surface6.contour("hood_pocket60",[Vector2(-0.04,0),Vector2(-0.03,0.095),Vector2(0.035,0.105),Vector2(0.055,0.075),Vector2(0.06,0)],0.13,24),Vector3(0,0.025,-0.124),cloth.darkened(0.04),Vector3.ONE,0.95))
		for elbow in [elbow_l,elbow_r]:
			wardrobe6.append(_node(elbow,Surface6.contour("sleeve60",[Vector2(-0.26,0),Vector2(-0.25,0.034),Vector2(-0.19,0.041),Vector2(-0.06,0.045),Vector2(0.015,0.038),Vector2(0.02,0)],1,20),Vector3.ZERO,cloth,Vector3.ONE,0.94))
		for side in [-1.0,1.0]:
			wardrobe6.append(_curve(chest,[Vector3(side*0.034,0.27,-0.07),Vector3(side*0.04,0.18,-0.145),Vector3(side*0.043,0.12,-0.146)],0.0025,Color("d7d3c6"),"TOP"))
	for ankle in [ankle_l,ankle_r]:
		wardrobe6.append(_node(ankle,Surface6.contour("shoe_tongue60",[Vector2(-0.02,0),Vector2(-0.01,0.033),Vector2(0.03,0.032),Vector2(0.045,0)],0.25,16),Vector3(0,-0.01,-0.075),Color("454c55"),Vector3.ONE,0.91))
	if int(profile.get("bottom_style",0))==1:
		var denim := Color(preload("res://scripts/juego/character_appearance.gd").COLORS[profile.pants])
		for hip in [hip_l,hip_r]:
			wardrobe6.append(_curve(hip,[Vector3(0.074,-0.08,-0.025),Vector3(0.070,-0.23,-0.024),Vector3(0.056,-0.40,-0.025)],0.0018,denim.lightened(0.18),"BOTTOM"))
			wardrobe6.append(_curve(hip,[Vector3(-0.04,-0.06,-0.066),Vector3(-0.02,-0.12,-0.072),Vector3(0.025,-0.14,-0.073)],0.0018,denim.lightened(0.18),"BOTTOM"))
	if int(profile.backpack)>0:
		for side in [-1.0,1.0]:
			wardrobe6.append(_curve(chest,[Vector3(side*0.12,-0.02,-0.13),Vector3(side*0.14,0.17,-0.135),Vector3(side*0.15,0.25,-0.07),Vector3(side*0.14,0.25,0.09),Vector3(side*0.12,0.12,0.18)],0.012,Color("28343d"),"BACKPACK"))
		wardrobe6.append(_curve(backpack_socket,[Vector3(-0.10,-0.12,0.20),Vector3(-0.12,0.08,0.15),Vector3(0,0.17,0.15),Vector3(0.12,0.08,0.15),Vector3(0.1,-0.12,0.20)],0.003,Color("a3a4a0"),"BACKPACK"))
	for mesh in wardrobe6:
		if mesh.material_override is StandardMaterial3D: mesh.material_override.roughness_texture=Surface6.fabric()
	_capture_modules()

func animate(delta: float, velocity: Vector3, on_floor: bool, crouching: bool) -> void:
	super.animate(delta,velocity,on_floor,crouching)
	for fingers in fingers6:
		fingers.rotation.x=lerpf(fingers.rotation.x,1.25 if armed or is_punching() else 0.14,minf(delta*12,1))
