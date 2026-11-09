extends RefCounted
var shell: Control
var service := preload("res://scripts/education/learning_activity_service.gd").new()
var fields: Dictionary = {}
var rows: Array = []
var list: VBoxContainer
const MENTORS := {"":"Actividad general","profesor_datos":"Bases de Datos · piso 3","profesor_algoritmos":"Algoritmos y Programación · piso 3","profesor_redes":"Redes · piso 3","docente_enfermeria":"Enfermería · piso 4","docente_odontologia":"Odontología · piso 4","coordinador_profesores":"Coordinación docente · piso 4","profesor_ingles":"Inglés · piso 6","profesor_etica":"Ética · piso 6","profesor_lenguaje":"Comunicación · piso 7","profesor_matematicas":"Matemáticas · piso 7","director":"Director de Informática · piso 8"}
const KIND_LABELS := ["Selección múltiple","Verdadero o falso","Ordenar elementos","Identificar objeto","Seleccionar zona","Resolver secuencia","Relacionar conceptos","Actividad práctica","Reflexión ética"]

func open() -> void:
	service.auth = shell.auth
	shell._clear("ACTIVIDADES EDUCATIVAS 4.0","Banco autorizado por asignatura · publicación mediante servidor")
	shell._button("CREAR ACTIVIDAD",edit.bind({}))
	shell._button("ESTADÍSTICAS AGREGADAS",statistics)
	shell._button("VOLVER",shell._home)
	var search := LineEdit.new()
	search.placeholder_text = "Buscar texto, unidad, tipo o dificultad"
	shell.column.add_child(search)
	list = VBoxContainer.new()
	shell.column.add_child(list)
	var generation: int = shell.page_generation
	var response := await service.rpc("learning_staff_bank")
	if generation != shell.page_generation: return
	if response.has("error"): shell._status(response.error); return
	rows = response.data if response.data is Array else []
	search.text_changed.connect(render)
	render("")

func render(query: String) -> void:
	for child in list.get_children(): child.queue_free()
	for row in rows:
		var kind_label: String=KIND_LABELS[maxi(0,service.KINDS.find(str(row.kind)))]
		var difficulty_label: String={"easy":"Fácil","medium":"Media","hard":"Difícil"}.get(row.difficulty,str(row.difficulty))
		if not query.is_empty() and not (str(row.prompt)+str(row.unit)+kind_label+difficulty_label).to_lower().contains(query.to_lower()): continue
		var label := Label.new()
		label.text = "%s · %s · %s · %s\n%s" % [row.unit,kind_label,difficulty_label,"PUBLICADA" if row.active else "INACTIVA",row.prompt]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(label)
		for item in [["EDITAR",edit.bind(row)],["PROBAR",preview.bind(row)],["DESACTIVAR" if row.active else "PUBLICAR",toggle.bind(row)]]:
			var button := Button.new()
			button.text = item[0]
			button.pressed.connect(item[1])
			if item[0]!="PROBAR" and shell.auth.role!="admin" and str(row.get("created_by",""))!=shell.auth.user_id: button.disabled=true
			list.add_child(button)

func toggle(row: Dictionary) -> void:
	var data := row.duplicate(true)
	data.active = not data.active
	var response := await service.rpc("save_learning_activity",{"p_id":row.id,"p_data":data})
	if response.has("error"): shell._status(response.error)
	else: open()

func edit(row: Dictionary) -> void:
	shell._clear("EDITAR ACTIVIDAD" if not row.is_empty() else "NUEVA ACTIVIDAD","La solución solo se muestra al estudiante después de responder. En secuencias, indica números separados por comas, por ejemplo: 3, 1, 2.")
	fields = {}
	var generation: int = shell.page_generation
	var subjects: Array = await shell.service.get_subjects()
	if generation != shell.page_generation: return
	var subject := OptionButton.new()
	for item in subjects:
		subject.add_item(str(item.name)+" · Piso "+str(item.floor))
		if item.id == row.get("subject_id",""): subject.select(subject.item_count-1)
	shell.column.add_child(subject)
	var kind := OptionButton.new()
	for value in KIND_LABELS: kind.add_item(value)
	kind.select(maxi(0,service.KINDS.find(row.get("kind","multiple_choice"))))
	shell.column.add_child(kind)
	var mentor_choice := OptionButton.new()
	var mentor_ids: Array = MENTORS.keys()
	for id in mentor_ids:
		mentor_choice.add_item(MENTORS[id])
		if id==row.get("mentor_id",""): mentor_choice.select(mentor_choice.item_count-1)
	shell.column.add_child(mentor_choice)
	for entry in [["unit","Unidad temática",""],["prompt","Enunciado",""],["image_path","Imagen educativa (se completa al subir)",""],["content","Alternativas o elementos: uno por línea","Alternativa 1\nAlternativa 2\nAlternativa 3\nAlternativa 4"],["answer","Número de alternativa correcta, o secuencia de números. Para reflexión se ignora.","1"],["explanation","Explicación posterior",""]]:
		var label := Label.new(); label.text = entry[1]; shell.column.add_child(label)
		var input := TextEdit.new()
		input.custom_minimum_size.y = 65
		var value = row.get(entry[0],entry[2])
		if entry[0]=="content" and value is Dictionary:
			input.text="\n".join(Array(value.get("options",value.get("items",[]))).map(func(item): return str(item)))
		elif entry[0]=="answer" and row.has("answer"):
			input.text=", ".join(value.map(func(index): return str(int(index)+1))) if value is Array else (str(int(value)+1) if value is int or value is float else str(value))
		else: input.text=str(value if value!=null else "")
		shell.column.add_child(input)
		fields[entry[0]] = input
		if entry[0]=="image_path": input.hide()
	var difficulty := OptionButton.new()
	shell._button("SUBIR IMAGEN AUTORIZADA",func():
		var picker := FileDialog.new()
		picker.access=FileDialog.ACCESS_FILESYSTEM; picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE
		picker.filters=PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Imágenes educativas autorizadas"])
		shell.add_child(picker)
		picker.file_selected.connect(func(path):
			picker.queue_free()
			var result: Dictionary = await service.upload_image(path)
			if generation != shell.page_generation: return
			if result.has("error"): shell._status(result.error)
			else: fields.image_path.text=str(result.path))
		picker.canceled.connect(picker.queue_free)
		picker.popup_centered_ratio(0.7))
	for item in ["Fácil","Media","Difícil"]: difficulty.add_item(item)
	difficulty.select(maxi(0,["easy","medium","hard"].find(row.get("difficulty","easy"))))
	shell.column.add_child(difficulty)
	var active := CheckBox.new(); active.text = "Publicada"; active.button_pressed = row.get("active",false); shell.column.add_child(active)
	var access := CheckBox.new(); access.text = "Pregunta de acceso al piso de esta asignatura"; access.button_pressed = row.get("access_challenge",false); shell.column.add_child(access)
	var retry_label := Label.new(); retry_label.text="Espera entre intentos (segundos)"; shell.column.add_child(retry_label)
	var retry_delay := SpinBox.new(); retry_delay.min_value=0; retry_delay.max_value=300; retry_delay.value=int(row.get("retry_delay_seconds",0)); shell.column.add_child(retry_delay)
	var attempts_label := Label.new(); attempts_label.text="Intentos por día: 0 permite intentos ilimitados. Los accesos siempre requieren 0."; attempts_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; shell.column.add_child(attempts_label)
	var attempts := SpinBox.new(); attempts.min_value=0; attempts.max_value=100; attempts.value=int(row.get("max_attempts_per_day",0)); shell.column.add_child(attempts)
	shell._button("GUARDAR",func():
		if subjects.is_empty(): shell._status("Solicita una asignatura al administrador."); return
		var data := {"subject_id":subjects[subject.selected].id,"kind":service.KINDS[kind.selected],"difficulty":["easy","medium","hard"][difficulty.selected],"active":active.button_pressed,"access_challenge":access.button_pressed}
		for key in fields: data[key] = fields[key].text.strip_edges()
		data.mentor_id=mentor_ids[mentor_choice.selected]
		data.retry_delay_seconds=int(retry_delay.value); data.max_attempts_per_day=int(attempts.value)
		var items: Array = Array(str(data.content).split("\n")).map(func(item): return str(item).strip_edges()).filter(func(item): return not item.is_empty())
		if data.kind=="reflection": data.content={}; data.answer=""
		elif data.kind in ["multiple_choice","true_false","identify","physical_zone"]:
			if not str(data.answer).is_valid_int(): shell._status("Indica el número de la alternativa correcta."); return
			data.content={"options":items}; data.answer=int(data.answer)-1
		else:
			var order: Array = []
			for token in str(data.answer).split(","):
				if not token.strip_edges().is_valid_int(): shell._status("Indica el orden con números separados por comas."); return
				order.append(int(token.strip_edges())-1)
			data.content={"items":items}; data.answer=order
		var error: String = service.validate(data)
		if not error.is_empty(): shell._status(error); return
		var result: Dictionary = await service.rpc("save_learning_activity",{"p_id":row.get("id",null),"p_data":data})
		if generation != shell.page_generation: return
		if result.has("error"): shell._status(result.error)
		else: open())
	shell._button("CANCELAR",open)

func preview(row: Dictionary) -> void:
	shell._clear("PRUEBA DOCENTE · NO REGISTRA PROGRESO")
	var view := preload("res://scripts/education/learning_activity_view.gd").new()
	view.activity = row
	view.answered.connect(func(answer): shell._status(("Reflexión registrada en vista previa. " if row.kind == "reflection" else ("Correcto. " if answer == row.answer else "Revisar. "))+str(row.explanation)))
	shell.column.add_child(view)
	shell._button("VOLVER",open)

func statistics() -> void:
	service.auth = shell.auth
	shell._clear("ESTADÍSTICAS EDUCATIVAS","Resultados agregados del juego; no son notas oficiales. No se muestran identidades.")
	var generation: int = shell.page_generation
	var response := await service.rpc("education_statistics_v4")
	if generation != shell.page_generation: return
	if response.has("error"): shell._status(response.error)
	elif response.data is Array:
		for row in response.data: shell._label("%s · %s\nIntentos %s · Correctas %s · Incorrectas %s · Reflexiones %s" % [row.unit,row.prompt,row.attempts,row.correct,row.incorrect,row.reflections])
	shell._button("VOLVER",shell._home)
	shell._button("POR ASIGNATURA E HISTORIAL",history)

func history() -> void:
	service.auth=shell.auth
	shell._clear("HISTORIAL EDUCATIVO","Datos agregados del juego, sin identidades personales. Últimos 30 días en UTC.")
	var generation: int=shell.page_generation
	var response := await service.rpc("learning_history_v4")
	if not is_instance_valid(shell) or generation!=shell.page_generation: return
	if response.has("error"): shell._status(response.error)
	elif response.data is Dictionary:
		shell._label("POR ASIGNATURA")
		for row in response.data.get("subjects",[]): shell._label("%s · Respuestas %s · Correctas %s · Incorrectas %s · Reflexiones %s" % [row.name,row.answered,row.correct,row.incorrect,row.reflections],16)
		shell._label("ACTIVIDAD DIARIA")
		for row in response.data.get("days",[]): shell._label("%s · Respuestas %s · Correctas %s" % [row.day,row.answered,row.correct],16)
		shell._label("PUBLICACIONES Y CAMBIOS")
		for row in response.data.get("published",[]): shell._label("%s · %s\nCreada: %s · Actualizada: %s · %s" % [row.unit,row.prompt,row.created_at,row.updated_at,"Publicada" if row.active else "Inactiva"],16)
	shell._button("VOLVER",shell._home)
