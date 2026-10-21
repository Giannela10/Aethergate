extends Control
## Shared accessible shell for Login and role dashboards. No authorization in UI.
var auth: Node
var service: Node
var column: VBoxContainer
var status: Label
var page_generation := 0
var form_fields: Dictionary = {}
var form_subjects: Array = []
var editing_id := ""
var account_fields: Dictionary = {}
var menu_scroll: ScrollContainer
var administration: Node
var users_cache: Array = []
var users_list: VBoxContainer
var user_search: LineEdit
var user_filter: OptionButton
var remember_checkbox: CheckBox

func _resolve_services() -> void:
	auth = get_node("/root/AuthManager")
	service = get_node("/root/QuestionService")
	administration = preload("res://scripts/education/admin_service.gd").new()
	add_child(administration)

func _process(_delta: float) -> void:
	if not is_instance_valid(menu_scroll) or not is_instance_valid(column): return
	menu_scroll.custom_minimum_size = Vector2(minf(420 if name in ["Login","StudentMainMenu"] else 760,maxf(160,get_viewport_rect().size.x-96)),minf(column.get_combined_minimum_size().y,maxf(100,get_viewport_rect().size.y-96)))

func preview_resolution(width: int, height: int) -> void:
	if not OS.is_debug_build(): return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(width,height))
	# Embedded editor windows may lock native size; exercise the UI viewport too.
	get_window().content_scale_size = Vector2i(width,height)

func layout_diagnostics() -> Dictionary:
	var labels: Array[String] = []
	for child in column.get_children():
		if child is Button and child.visible: labels.append(child.text)
	return {"viewport":str(get_viewport_rect().size),"scrollbar":menu_scroll.get_v_scroll_bar().visible,"content_height":column.get_combined_minimum_size().y,"available_height":menu_scroll.size.y,"buttons":labels}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resolve_services()
	auth.session_changed.connect(_route)
	auth.status_changed.connect(_status)
	var background := ColorRect.new()
	background.color = Color("091526")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var campus_backdrop := name in ["Login","StudentMainMenu","PendingAccountScreen","TeacherDashboard","AdminDashboard"]
	if campus_backdrop:
		var campus := TextureRect.new()
		campus.name = "CampusBackground"
		campus.texture = load("res://resources/ui/campus_login.png")
		campus.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		campus.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		campus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		campus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(campus)
		var shade := ColorRect.new()
		shade.color = Color(0.025,0.055,0.10,0.18)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var layout := HBoxContainer.new()
	margin.add_child(layout)
	var left := Control.new()
	if not campus_backdrop: left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(left)
	var card := PanelContainer.new()
	card.name = "MenuCard"
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.025,0.055,0.10,0.94) if campus_backdrop else Color(0,0,0,0)
	card_style.set_corner_radius_all(16)
	card_style.set_content_margin_all(22 if campus_backdrop else 0)
	card.add_theme_stylebox_override("panel",card_style)
	layout.add_child(card)
	var scroll := ScrollContainer.new()
	menu_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.x = minf(420 if campus_backdrop else 760,get_viewport_rect().size.x-(108 if campus_backdrop else 64))
	card.add_child(scroll)
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	var theme_resource := Theme.new()
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("15324d")
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("24567c")
	var focused := StyleBoxFlat.new()
	focused.bg_color = Color(0,0,0,0)
	focused.border_color = Color("ffd344")
	focused.set_border_width_all(2)
	focused.set_corner_radius_all(8)
	theme_resource.set_stylebox("normal","Button",normal)
	theme_resource.set_stylebox("hover","Button",hover)
	theme_resource.set_stylebox("pressed","Button",hover)
	theme_resource.set_stylebox("focus","Button",focused)
	theme = theme_resource
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",8)
	scroll.add_child(column)
	_show_login()
	await auth.initialize()
	_route()

func _status(message: String) -> void:
	if is_instance_valid(status):
		status.text = message
		status.visible = not message.is_empty()

func _clear(title: String, subtitle: String = "") -> void:
	page_generation += 1
	account_fields.clear()
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	_label(title,32)
	if not subtitle.is_empty(): _label(subtitle,18)
	status = _label("",15)
	status.visible = false

func _label(value: String, size: int = 18) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	if size >= 30: label.add_theme_color_override("font_color",Color("ffd344"))
	column.add_child(label)
	return label

func _button(value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	column.add_child(button)
	return button

func _route() -> void:
	if not auth.can_enter_menu():
		if name != "Login":
			get_tree().call_deferred("change_scene_to_file","res://scenes/education/Login.tscn")
			return
		_show_login()
		return
	var scene: String = auth.route_authenticated_user(str(get_tree().get_meta("education_menu_view","")))
	if scene == "Login":
		auth.clear_session()
		_route()
		_status("Rol de perfil no válido. Contacta al administrador.")
		return
	if name != scene:
		get_tree().call_deferred("change_scene_to_file","res://scenes/education/"+scene+".tscn")
		return
	if auth.role == "student": _student()
	elif auth.role == "pending": _pending()
	elif scene == "StudentMainMenu": _student()
	elif scene == "TeacherDashboard": _teacher()
	elif scene == "AdminDashboard": _admin()

func _open_menu(view: String) -> void:
	get_tree().set_meta("education_menu_view",view)
	_route()

func _pending() -> void:
	_clear("CUENTA PENDIENTE","Hola, " + auth.display_name)
	_label("Tu cuenta fue creada correctamente, pero aún no tiene un rol asignado.")
	_label("Un administrador debe habilitar tu acceso.")
	_button("ACTUALIZAR ESTADO",_refresh_account)
	_button("CERRAR SESIÓN",_logout)

func _refresh_account() -> void:
	var current := page_generation
	for child in column.get_children():
		if child is Button: child.disabled = true
	_status("Consultando estado…")
	var result: Dictionary = await auth.refresh_profile()
	if current != page_generation: return
	for child in column.get_children():
		if child is Button: child.disabled = false
	_status(str(result.message))

func _show_login() -> void:
	_clear("DUOCGAMES","Aprende. Explora. Supera desafíos.")
	_button("INICIAR SESIÓN",_account_form.bind(false)).grab_focus()
	_button("REGISTRARSE",_account_form.bind(true))
	if auth.client.configured() and auth.client.config.get("google_enabled",false):
		_button("CONTINUAR CON GOOGLE",auth.google_login)
	_button("SALIR",get_tree().quit)
	_debug_button()
	column.move_child(status,column.get_child_count()-1)

func _debug_button() -> void:
	if OS.is_debug_build(): _button("DEBUG",_development)

func _development() -> void:
	if not OS.is_debug_build(): return
	_clear("PANEL DE DESARROLLO")
	if OS.is_debug_build():
		for selected_role in ["pending","student","teacher","admin"]:
			_button("DEV " + selected_role.to_upper(),auth.dev_login.bind(selected_role))
		_button("AUTH STATUS",_debug)
	_button("VOLVER",_home)

func _account_form(registering: bool) -> void:
	_clear("REGISTRARSE" if registering else "INICIAR SESIÓN")
	if registering: _account_input("full_name","Nombre",false)
	_account_input("email","Correo electrónico",false)
	_account_input("password","Contraseña",true)
	if not registering:
		remember_checkbox = CheckBox.new()
		remember_checkbox.name = "RememberLogin"
		remember_checkbox.text = "Mantener sesión iniciada"
		remember_checkbox.button_pressed = false
		column.add_child(remember_checkbox)
	if registering:
		_account_input("confirmation","Repetir contraseña",true)
		_label("Mínimo 8 caracteres. Tu cuenta quedará pendiente de asignación.",14)
	_button("CREAR CUENTA" if registering else "INICIAR SESIÓN",_submit_account.bind(registering)).name = "SubmitAccount"
	_button("VOLVER",_show_login).name = "BackToLogin"
	account_fields["full_name" if registering else "email"].grab_focus()
	for field in account_fields.values():
		field.text_submitted.connect(func(_value): _submit_account(registering))
	column.move_child(status,column.get_child_count()-1)

func _account_input(key: String, title: String, secret: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	column.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 112
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",14)
	row.add_child(label)
	var input := LineEdit.new()
	input.name = "Account_" + key
	input.placeholder_text = title
	input.secret = secret
	input.max_length = 254 if key == "email" else (80 if key == "full_name" else 1024)
	input.custom_minimum_size.y = 40
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if key == "email": input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	elif secret: input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	row.add_child(input)
	account_fields[key] = input

func _submit_account(registering: bool) -> void:
	if auth.busy and not auth.silent_restore:
		_status("Hay una autenticación en curso. Espera a que termine.")
		return
	if not account_fields.has("email"): return
	var address := str(account_fields.email.text).strip_edges()
	var password := str(account_fields.password.text)
	var full_name := str(account_fields.full_name.text) if registering else ""
	var confirmation := str(account_fields.confirmation.text) if registering else ""
	var error: String = auth.validate_email_credentials(address,password,registering,full_name,confirmation)
	if not error.is_empty():
		_status(error)
		return
	var current := page_generation
	for input in account_fields.values():
		input.editable = false
	for child in column.get_children():
		if child is Button: child.disabled = true
	column.get_node("SubmitAccount").text = "CONECTANDO…"
	_status("Creando cuenta…" if registering else "Iniciando sesión…")
	var result: Dictionary
	if registering: result = await auth.register_email(address,password,full_name,confirmation)
	else: result = await auth.login_email(address,password,remember_checkbox.button_pressed)
	password = ""
	confirmation = ""
	if not is_inside_tree() or current != page_generation: return
	for input in account_fields.values(): input.editable = true
	if result.get("ok",false):
		for input in account_fields.values():
			if input.secret: input.clear()
	for child in column.get_children():
		if child is Button: child.disabled = false
	column.get_node("SubmitAccount").text = "CREAR CUENTA" if registering else "INICIAR SESIÓN"
	if result.get("confirmation_required",false):
		_account_form(false)
		account_fields.email.text = address
	_status(str(result.get("message","No se pudo completar la solicitud.")))

func _logout() -> void:
	get_tree().remove_meta("education_menu_view")
	service.clear_session()
	auth.logout()

func _student() -> void:
	_clear("DUOCGAMES","Bienvenido, " + auth.display_name)
	var continue_button := _button("CONTINUAR",_play.bind("continue"))
	continue_button.disabled = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary("user://campus_campaign_v1.json").is_empty()
	continue_button.grab_focus()
	_button("NUEVA PARTIDA",_confirm_new)
	_button("PROGRESO ACADÉMICO",_progress)
	_button("AJUSTES",_settings)
	_button("CERRAR SESIÓN",_logout)
	if auth.role in ["teacher","admin"]: _button("VOLVER A MI PANEL",_open_menu.bind(""))
	_debug_button()
	_load_avatar()

func _confirm_new() -> void:
	_clear("NUEVA PARTIDA","El menú de campaña pedirá confirmación y permitirá personalizar al estudiante. Se conserva el mecanismo de copia del guardado anterior.")
	_button("CONTINUAR A PERSONALIZACIÓN",_play.bind("new"))
	_button("CANCELAR",_student)

func _play(entry: String) -> void:
	if not auth.can_enter_menu() or auth.role not in ["student","teacher","admin"]:
		_route()
		return
	get_tree().set_meta("education_entry",entry)
	get_tree().set_meta("education_enabled",true)
	get_tree().change_scene_to_file("res://Main.tscn")

func _load_avatar() -> void:
	if not auth.avatar_url.begins_with("https://"): return
	var current := page_generation
	var request := HTTPRequest.new()
	request.timeout = 5
	request.body_size_limit = 1048576
	add_child(request)
	if request.request(auth.avatar_url) != OK:
		request.queue_free()
		return
	var response: Array = await request.request_completed
	request.queue_free()
	if not is_inside_tree() or current != page_generation or response[1] != 200: return
	var picture := Image.new()
	var bytes: PackedByteArray = response[3]
	var err := picture.load_png_from_buffer(bytes)
	if err != OK: err = picture.load_jpg_from_buffer(bytes)
	if err != OK: err = picture.load_webp_from_buffer(bytes)
	if err != OK: return
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(64,64)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture = ImageTexture.create_from_image(picture)
	column.add_child(avatar)

func _progress() -> void:
	var raw: Dictionary = preload("res://scripts/compartidos/lectura_guardado.gd").read_dictionary("user://campus_campaign_v1.json")
	var data: Dictionary = preload("res://scripts/education/academic_progress.gd").migrate(raw)
	_clear("PROGRESO DE APRENDIZAJE EN EL JUEGO","Estos resultados no son una nota oficial.")
	_label("Respondidas: %d · Correctas: %d · Incorrectas: %d\nAsignaturas: %s\nPiso 3: %s" % [data.academic_progress.answered,data.academic_progress.correct,data.academic_progress.incorrect,str(data.academic_progress.subjects.keys()),"Desbloqueado" if data.academic_floor_unlocks.get("3",false) else "Pendiente"])
	_button("VOLVER",_student)

func _settings() -> void:
	_clear("AJUSTES","Las opciones completas de calidad, idioma y audio siguen disponibles en Esc → Opciones dentro del campus.")
	_button("VENTANA / PANTALLA COMPLETA",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN))
	_button("VOLVER",_student)

func _teacher() -> void:
	_clear("PANEL DOCENTE","Hola, Profesor/a " + auth.display_name)
	_button("MIS ASIGNATURAS",_subjects_page).grab_focus()
	_button("MIS PREGUNTAS",_questions)
	_button("CREAR PREGUNTA",_form.bind({}))
	_button("EDITAR PREGUNTAS",_questions)
	_button("VISTA PREVIA",_questions)
	_button("ESTADÍSTICAS",_placeholder.bind("Estadísticas", "Las estadísticas docentes se incorporarán en una etapa posterior."))
	_button("JUGAR",_open_menu.bind("StudentMainMenu"))
	_button("CERRAR SESIÓN",_logout)
	if auth.role == "admin": _button("ADMINISTRACIÓN",_open_menu.bind(""))
	_debug_button()

func _admin() -> void:
	_clear("ADMINISTRACIÓN DUOCGAMES","Administrador: " + auth.display_name)
	_button("USUARIOS",_users_page.bind("")).grab_focus()
	_button("PROFESORES",_users_page.bind("teacher"))
	_button("ASIGNATURAS",_subjects_page)
	_button("PREGUNTAS",_questions)
	_button("ESTADÍSTICAS",_placeholder.bind("Estadísticas","Disponible en una próxima etapa."))
	_button("PANEL DOCENTE",_open_menu.bind("TeacherDashboard"))
	_button("JUGAR",_open_menu.bind("StudentMainMenu"))
	_button("CERRAR SESIÓN",_logout)
	_debug_button()

func _home() -> void:
	_route()

func _users_page(initial_role: String = "") -> void:
	if auth.role != "admin": return
	_clear("GESTIÓN DE USUARIOS")
	user_search = LineEdit.new()
	user_search.placeholder_text = "Buscar por nombre o correo"
	column.add_child(user_search)
	user_filter = OptionButton.new()
	for title in ["Todos","Pending","Estudiantes","Profesores","Admin"]: user_filter.add_item(title)
	user_filter.select(maxi(0,["","pending","student","teacher","admin"].find(initial_role)))
	column.add_child(user_filter)
	_button("ACTUALIZAR",_reload_users)
	_button("VOLVER",_home)
	users_list = VBoxContainer.new()
	users_list.add_theme_constant_override("separation",8)
	column.add_child(users_list)
	user_search.text_changed.connect(func(_value): _render_users())
	user_filter.item_selected.connect(func(_value): _render_users())
	await _reload_users()

func _reload_users() -> void:
	var current := page_generation
	_status("Cargando usuarios…")
	var result: Dictionary = await administration.list_profiles()
	if current != page_generation: return
	if not result.get("ok",false):
		_status(str(result.message))
		return
	users_cache = result.data
	_render_users()

func _render_users() -> void:
	if not is_instance_valid(users_list) or not is_instance_valid(user_search): return
	for child in users_list.get_children():
		users_list.remove_child(child)
		child.queue_free()
	var selected_role: String = ["","pending","student","teacher","admin"][user_filter.selected]
	var rows: Array = preload("res://scripts/education/admin_service.gd").filter_profiles(users_cache,user_search.text,selected_role)
	_status("%d cuentas" % rows.size())
	for row in rows:
		var button := Button.new()
		button.text = "%s\n%s\n%s · Registro: %s" % [row.get("display_name","Usuario"),row.get("email",""),str(row.get("role","")).to_upper(),str(row.get("created_at","")).left(10)]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_user_detail.bind(row))
		users_list.add_child(button)

func _user_detail(profile: Dictionary) -> void:
	_clear("USUARIO",str(profile.get("display_name","Usuario")))
	_label("Correo: " + str(profile.get("email","")))
	_label("Rol actual: " + str(profile.get("role","")).to_upper())
	_label("Cambiar rol",15)
	var selected := OptionButton.new()
	for title in ["PENDIENTE","ESTUDIANTE","PROFESOR","ADMINISTRADOR"]: selected.add_item(title)
	selected.select(maxi(0,["pending","student","teacher","admin"].find(profile.get("role"))))
	column.add_child(selected)
	_button("GUARDAR CAMBIOS",_save_user_role.bind(profile,selected))
	if profile.get("role")=="teacher": _button("ASIGNAR ASIGNATURAS",_assign_subjects.bind(profile))
	_button("VOLVER",_users_page.bind(""))

func _save_user_role(profile: Dictionary, selected: OptionButton) -> void:
	var current := page_generation
	for child in column.get_children():
		if child is Button: child.disabled = true
	var selected_role: String = ["pending","student","teacher","admin"][selected.selected]
	var result: Dictionary = await administration.set_user_role(str(profile.id),selected_role)
	if current != page_generation: return
	for child in column.get_children():
		if child is Button: child.disabled = false
	if not result.get("ok",false):
		_status(str(result.message))
		return
	if str(profile.id)==auth.user_id:
		var refreshed: Dictionary = await auth.refresh_profile()
		if current==page_generation and not refreshed.get("ok",false): _status(str(refreshed.message))
		return
	if selected_role=="teacher": _assign_subjects(result.data)
	else:
		_user_detail(result.data)
		_status("Rol actualizado correctamente.")

func _assign_subjects(profile: Dictionary) -> void:
	_clear("ASIGNAR ASIGNATURAS",str(profile.get("display_name",""))+" · "+str(profile.get("email","")))
	var current := page_generation
	var subjects: Dictionary = await administration.list_subjects()
	if current != page_generation: return
	var assignments: Dictionary = await administration.get_teacher_subjects(str(profile.id))
	if current != page_generation: return
	if not subjects.get("ok",false) or not assignments.get("ok",false):
		_status(str(subjects.get("message",assignments.get("message","No se pudieron cargar las asignaturas."))))
		_button("VOLVER",_user_detail.bind(profile))
		return
	var selected_ids: Array = assignments.data.map(func(item): return str(item.subject_id))
	var checks: Array = []
	for subject in subjects.data:
		var checkbox := CheckBox.new()
		checkbox.text = "%s · Piso %s%s" % [subject.name,subject.floor,"" if subject.active else " (inactiva)"]
		checkbox.button_pressed = str(subject.id) in selected_ids
		checkbox.set_meta("subject_id",str(subject.id))
		column.add_child(checkbox)
		checks.append(checkbox)
	_button("GUARDAR",_save_assignments.bind(str(profile.id),checks))
	_button("VOLVER",_user_detail.bind(profile))

func _save_assignments(target_id: String, checks: Array) -> void:
	var current := page_generation
	var ids: Array = []
	for checkbox in checks:
		if checkbox.button_pressed: ids.append(str(checkbox.get_meta("subject_id")))
	for child in column.get_children():
		if child is Button: child.disabled = true
	var result: Dictionary = await administration.set_teacher_subjects(target_id,ids)
	if current != page_generation: return
	for child in column.get_children():
		if child is Button: child.disabled = false
	_status("Asignaturas guardadas." if result.get("ok",false) else str(result.message))

func _placeholder(title: String, message: String) -> void:
	_clear(title,message)
	_button("VOLVER",_home)

func _debug() -> void:
	if not OS.is_debug_build(): return
	_clear("AUTH DEBUG",auth.diagnostics()+"\nQuestion service: "+service.mode+"\nOffline fallback: "+str(service.mode.contains("offline") or service.mode.contains("local")))
	_button("VOLVER",_home)

func _subjects_page() -> void:
	_clear("ASIGNATURAS","Cargando…")
	var current := page_generation
	var rows: Array
	if auth.role == "admin":
		var result: Dictionary = await administration.list_subjects()
		if current != page_generation: return
		if not result.get("ok",false):
			_status(str(result.message))
			_button("VOLVER",_home)
			return
		rows = result.data
	else: rows = await service.get_subjects()
	if current != page_generation: return
	_status("%d asignaturas%s" % [rows.size()," asignadas" if auth.role=="teacher" else " en el catálogo"])
	for row in rows: _label("%s · Piso %s · %s" % [row.name,row.floor,row.code])
	_button("VOLVER",_home)

func _questions() -> void:
	_clear("PREGUNTAS","Cargando preguntas autorizadas…")
	var current := page_generation
	_button("CREAR PREGUNTA",_form.bind({}))
	_button("VOLVER",_home)
	var rows: Array = await service.get_questions_for_teacher()
	if current != page_generation: return
	_status("%d preguntas. %s" % [rows.size(),"Demostración local; no se guarda en Supabase." if auth.dev_session else "El backend limita asignaturas y permisos."])
	for row in rows:
		var subject_name := str(row.get("subjects",{}).get("name",row.subject_id))
		_label("%s\nAsignatura: %s · %s · %s" % [row.question_text,subject_name,row.difficulty,"Activa" if row.active else "Inactiva"])
		if auth.role == "admin":
			var creator = row.get("creator",{})
			_label("Creador: " + str(creator.get("display_name","Sin nombre")) if creator is Dictionary else "Creador no disponible",14)
		var writable: bool = auth.role == "admin" or auth.dev_session or str(row.get("created_by","")) == auth.user_id
		_button("EDITAR",_form.bind(row)).disabled = not writable
		_button("DESACTIVAR" if row.active else "ACTIVAR",_toggle.bind(row)).disabled = not writable
		_button("VISTA PREVIA",_preview.bind(row))

func _toggle(row: Dictionary) -> void:
	var current := page_generation
	var result: Dictionary = await service.set_question_active(str(row.id),not row.active)
	if current != page_generation: return
	if result.has("error"): _status(result.error)
	else: _questions()

func _preview(row: Dictionary) -> void:
	_clear("VISTA PREVIA · NO REGISTRA INTENTO")
	var view := preload("res://scripts/education/question_view.gd").new()
	view.question = row
	view.selected.connect(func(_option): _status("Selección de vista previa. No se envió ninguna respuesta."))
	column.add_child(view)
	_button("VOLVER",_questions)

func _input_field(key: String, title: String, value: String, multiline: bool = false) -> void:
	_label(title,15)
	var input: Control = TextEdit.new() if multiline else LineEdit.new()
	input.set("text",value)
	input.custom_minimum_size.y = 80 if multiline else 38
	column.add_child(input)
	form_fields[key] = input

func _form(row: Dictionary) -> void:
	_clear("EDITAR PREGUNTA" if not row.is_empty() else "CREAR PREGUNTA")
	var current := page_generation
	form_fields = {}
	editing_id = str(row.get("id",""))
	form_subjects = await service.get_subjects()
	if current != page_generation: return
	var subject := OptionButton.new()
	for item in form_subjects:
		subject.add_item("%s · Piso %s" % [item.name,item.floor])
		if str(item.id) == str(row.get("subject_id","")): subject.select(subject.item_count-1)
	column.add_child(subject)
	form_fields.subject = subject
	var difficulty := OptionButton.new()
	for value in ["Fácil","Media","Difícil"]: difficulty.add_item(value)
	difficulty.select(maxi(0,["easy","medium","hard"].find(row.get("difficulty","easy"))))
	column.add_child(difficulty)
	form_fields.difficulty = difficulty
	_input_field("question_text","Pregunta",str(row.get("question_text","")),true)
	for option in ["a","b","c","d"]: _input_field("option_"+option,"Alternativa "+option.to_upper(),str(row.get("option_"+option,"")))
	var keys = row.get("question_keys",{})
	if keys is Array: keys = keys[0] if not keys.is_empty() else {}
	if not keys is Dictionary: keys = {}
	_label("Respuesta correcta",15)
	var correct := OptionButton.new()
	for value in ["A","B","C","D"]: correct.add_item(value)
	correct.select(maxi(0,["A","B","C","D"].find(row.get("correct_option",keys.get("correct_option","A")))))
	column.add_child(correct)
	form_fields.correct = correct
	_input_field("explanation","Explicación",str(row.get("explanation",keys.get("explanation",""))),true)
	var active := CheckButton.new()
	active.text = "Activo"
	active.button_pressed = row.get("active",true)
	column.add_child(active)
	form_fields.active = active
	_button("GUARDAR",_save_form)
	_button("CANCELAR",_questions)
	if form_subjects.is_empty(): _status("No hay asignaturas asignadas. Solicita una asignación al administrador.")

func _save_form() -> void:
	if form_subjects.is_empty(): return
	var data := {}
	for key in ["question_text","option_a","option_b","option_c","option_d","explanation"]: data[key] = str(form_fields[key].text).strip_edges()
	data.subject_id = str(form_subjects[form_fields.subject.selected].id)
	data.difficulty = ["easy","medium","hard"][form_fields.difficulty.selected]
	data.correct_option = ["A","B","C","D"][form_fields.correct.selected]
	data.active = form_fields.active.button_pressed
	var current := page_generation
	var result: Dictionary = await service.update_question(editing_id,data)
	if current != page_generation: return
	if result.has("error"): _status(result.error)
	else: _questions()
