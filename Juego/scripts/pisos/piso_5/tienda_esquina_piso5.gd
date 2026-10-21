@tool
extends "res://scripts/pisos/piso_8/piso_8_completo.gd"
## Kiosco abierto junto al desembarco y los ascensores del piso 5.

func _ready() -> void:
	pass

func build() -> Dictionary:
	for child in get_children():
		child.free()
	position = Vector3(-28.2, 47.975, -136.6)
	rotation.y = 0.0
	scale = Vector3.ONE * 1.35
	init_materials()
	material("madera_tienda", Color(0.48, 0.33, 0.21), 0.85)
	material("menu_claro", Color(1.0, 0.90, 0.78), 0.7)
	material("azul_refrigerador", Color(0.035, 0.17, 0.48), 0.4)
	box("PisoBaldosasTienda", Vector3(0, -0.012, 0.15), Vector3(9.5, 0.024, 9.5), dark_floor)
	box("CieloHormigonNicho", Vector3(0, 6.3, 0.5), Vector3(9.5, 0.20, 10.2), materials.ceiling)
	box("BandejaInstalaciones", Vector3(0, 5.95, -2.0), Vector3(9.4, 0.12, 0.38), materials.black)
	for z in [-1.8, -1.4]:
		var pipe := cylinder("TuberiaSuperior", Vector3(0, 5.90, z), 0.055, 9.4, materials.steel)
		pipe.rotation.z = PI / 2.0
	var floor_sign := group("SenalPiso5", Vector3(-3.0, 5.0, 2.4))
	floor_sign.rotation.y = PI / 2.0
	box("PanelSenalPiso", Vector3.ZERO, Vector3(3.1, 1.55, 0.06), materials.white, false, floor_sign)
	box("BandaAmarillaPiso", Vector3(-1.15, 0, 0.045), Vector3(0.78, 1.55, 0.025), materials.yellow, false, floor_sign)
	label_on(floor_sign, "NumeroPiso", "5", Vector3(-1.15, 0.18, 0.065), 0, Color.BLACK, 0.018)
	label_on(floor_sign, "DestinosPiso", "SALAS\nCAFETERÍA\nTERRAZA", Vector3(0.3, 0.0, 0.065), 0, Color(0.10, 0.10, 0.10), 0.0038)
	for x in [-4.1, -1.9]:
		box("SuspensionSenal", Vector3(x, 5.93, 2.4), Vector3(0.025, 0.3, 0.025), materials.black)
	box("RevestimientoMadera", Vector3(0, 2.7, -4.3), Vector3(8.0, 5.4, 0.12), materials.madera_tienda)
	for i in range(12):
		box("JuntaMadera", Vector3(0, 0.2 + i * 0.44, -4.23), Vector3(8, 0.018, 0.015), materials.joint)
	# Mostrador en L y espacio de atención abierto por el extremo izquierdo.
	box("MostradorFrontal", Vector3(0.25, 1.0, -0.75), Vector3(6.9, 2.0, 1.4), materials.black, true)
	box("CubiertaFrontal", Vector3(0.25, 2.06, -0.75), Vector3(7.1, 0.12, 1.55), materials.black, true)
	box("MostradorRetorno", Vector3(3.0, 1.0, -2.45), Vector3(1.4, 2.0, 2.2), materials.black, true)
	box("CubiertaRetorno", Vector3(3.0, 2.06, -2.45), Vector3(1.55, 0.12, 2.3), materials.black)
	for x in [-2.1, -0.3, 1.5]:
		box("JuntaGabinete", Vector3(x, 0.98, -0.04), Vector3(0.018, 1.8, 0.025), materials.steel)
		box("TiradorGabinete", Vector3(x + 0.65, 1.45, -0.02), Vector3(0.35, 0.04, 0.04), materials.steel)
	# Vitrinas transparentes con marcos negros, repisas y productos.
	for x in [-1.9, 0.35]:
		box("Vitrina", Vector3(x, 2.7, -0.85), Vector3(2.05, 1.2, 1.2), materials.glass)
		for side in [-1.0, 1.0]:
			box("PerfilVitrina", Vector3(x + side * 1.0, 2.7, -0.22), Vector3(0.045, 1.2, 0.045), materials.black)
		box("MarcoVitrina", Vector3(x, 3.32, -0.22), Vector3(2.05, 0.045, 0.045), materials.black)
		for y in [2.15, 2.7]:
			box("RepisaVitrina", Vector3(x, y, -0.85), Vector3(1.95, 0.045, 1.1), materials.steel)
			for i in range(4):
				box("Sandwich", Vector3(x - 0.70 + i * 0.46, y + 0.12, -0.63), Vector3(0.35, 0.16, 0.42), materials.menu_claro)
	# Caja abierta por delante para que las botellas se vean tras el vidrio.
	box("RefrigeradorAzul", Vector3(-2.65, 2.25, -4.35), Vector3(2.25, 4.5, 0.12), materials.azul_refrigerador, true)
	for x in [-3.72, -1.58]:
		box("LateralRefrigerador", Vector3(x, 2.25, -3.6), Vector3(0.12, 4.5, 1.6), materials.azul_refrigerador, true)
	for y in [0.10, 4.4]:
		box("TapaRefrigerador", Vector3(-2.65, y, -3.6), Vector3(2.25, 0.20, 1.6), materials.azul_refrigerador, true)
	box("CristalRefrigerador", Vector3(-2.65, 2.1, -2.77), Vector3(1.94, 3.7, 0.06), materials.glass)
	box("RotuloRefrigerador", Vector3(-2.65, 4.07, -2.75), Vector3(2.1, 0.58, 0.07), materials.azul_refrigerador)
	box("TiradorRefrigerador", Vector3(-1.79, 2.25, -2.68), Vector3(0.07, 0.75, 0.08), materials.black)
	box("LuzInteriorFrio", Vector3(-3.59, 2.25, -2.88), Vector3(0.025, 3.75, 0.025), materials.lamp)
	for row in range(5):
		box("RepisaFrio", Vector3(-2.65, 0.65 + row * 0.62, -3.0), Vector3(1.9, 0.04, 0.4), materials.white)
		for col in range(5):
			cylinder("Botella", Vector3(-3.4 + col * 0.37, 0.86 + row * 0.62, -2.95), 0.12, 0.40, materials.green if col % 2 else materials.blue)
	box("MesonEquipos", Vector3(0.15, 1.05, -3.85), Vector3(3.1, 2.1, 1.1), materials.black, true)
	for x in [-0.6, 0.75]:
		box("MaquinaCafe", Vector3(x, 2.85, -3.8), Vector3(1.12, 1.5, 0.9), materials.black)
		box("FrenteMaquinaRojo", Vector3(x, 2.94, -3.32), Vector3(0.78, 1.1, 0.04), materials.red)
		box("PanelMaquina", Vector3(x, 3.15, -3.28), Vector3(0.40, 0.35, 0.025), materials.black)
		box("BandejaMaquina", Vector3(x, 2.23, -3.20), Vector3(0.90, 0.05, 0.55), materials.steel)
		box("BoquillaCafe", Vector3(x, 2.66, -3.20), Vector3(0.08, 0.22, 0.15), materials.steel)
		for side in [-1.0, 1.0]:
			cylinder("BotonCafe", Vector3(x + side * 0.18, 2.90, -3.26), 0.045, 0.02, materials.white).rotation.x = PI / 2.0
		cylinder("VasoCafe", Vector3(x, 2.32, -3.13), 0.11, 0.22, materials.white)
	box("CongeladorBlanco", Vector3(2.85, 0.98, -4.0), Vector3(1.75, 1.95, 1.05), materials.white, true)
	box("TapaCongelador", Vector3(2.85, 1.98, -4.0), Vector3(1.8, 0.10, 1.1), materials.white)
	box("FranjaCongelador", Vector3(2.85, 0.35, -3.45), Vector3(1.75, 0.08, 0.025), materials.green)
	cylinder("TermoNegro", Vector3(2.6, 2.58, -0.6), 0.27, 0.94, materials.black)
	box("CajaRegistradora", Vector3(1.8, 2.28, -0.75), Vector3(0.6, 0.32, 0.5), materials.black)
	# Cartelería de la propia fotografía: carta iluminada y marca circular.
	box("MarcoCartaIluminada", Vector3(-0.3, 4.7, -4.15), Vector3(6.3, 1.3, 0.12), materials.black)
	photo_panel("CartaFotografica", Vector3(-0.3, 4.7, -4.07), Vector2(6.15, 1.20), Vector4(0.70, 0.191, 0.216, 0.083))
	photo_panel("LetreroJuanValdez", Vector3(3.45, 4.82, -4.06), Vector2(1.12, 1.12), Vector4(0.888, 0.190, 0.094, 0.069), true)
	photo_panel("MarcaCachantunFoto", Vector3(-2.65, 4.07, -2.68), Vector2(2.04, 0.55), Vector4(0.720, 0.275, 0.060, 0.024))
	# Bandejas, dispenser y dispensación de café como en el mostrador real.
	box("BandejaAmarilla", Vector3(1.5, 2.17, -1.0), Vector3(0.8, 0.09, 0.6), materials.yellow)
	box("DispensadorServilletas", Vector3(2.2, 2.38, -1.15), Vector3(0.28, 0.52, 0.28), materials.white)
	box("CanillaTermo", Vector3(2.6, 2.40, -0.30), Vector3(0.08, 0.10, 0.22), materials.steel)
	box("VigaSuperiorMadera", Vector3(0, 5.65, -4.35), Vector3(8.1, 0.28, 0.42), materials.madera_tienda)
	box("LuzMostrador", Vector3(0.25, 1.90, -0.035), Vector3(6.7, 0.035, 0.025), materials.lamp)
	for x in [-2.2, 1.8]:
		linear_light(self, Vector3(x, 5.6, -2.0), 2.6)
	set_meta("piso", 5)
	set_meta("lado", "norte_desembarco_escalera")
	set_meta("referencia", "WhatsApp Image 2026-10-14 at 16.15.39.jpeg")
	return {"piso": 5, "mostrador": "L", "vitrinas": 2, "refrigerador": 1}

func photo_panel(title: String, p: Vector3, size_value: Vector2, crop: Vector4, circular: bool = false) -> void:
	var surface := ShaderMaterial.new()
	surface.shader = load("res://materials/piso5/carteleria_referencia.gdshader")
	surface.set_shader_parameter("fotografia", load("res://materials/piso5/referencia_tienda.jpeg"))
	surface.set_shader_parameter("recorte", crop)
	surface.set_shader_parameter("circular", circular)
	var mesh := QuadMesh.new()
	mesh.size = size_value
	var panel := MeshInstance3D.new()
	panel.name = title
	panel.mesh = mesh
	panel.material_override = surface
	panel.position = p
	owned(panel, self)

func preview_reference() -> void:
	var camera := Camera3D.new()
	camera.name = "PreviewCamera"
	add_child(camera)
	camera.position = Vector3(-5, 5.8, 9)
	camera.fov = 45
	camera.look_at(to_global(Vector3(0, 2.6, -2.0)), Vector3.UP)
	camera.current = true
	var sunlight := DirectionalLight3D.new()
	add_child(sunlight)
	sunlight.rotation_degrees = Vector3(-55, -25, 0)
	sunlight.light_energy = 1.2
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.18, 0.19, 0.20)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.85, 0.83, 0.77)
	environment.ambient_light_energy = 0.7
	world.environment = environment
	add_child(world)