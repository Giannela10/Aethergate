extends RefCounted
## No private solution is requested by student RPCs. No automatic offline grading.
const KINDS := ["multiple_choice","true_false","ordering","identify","physical_zone","sequence","matching","practical","reflection"]
var auth: Node

func rpc(method: String, data: Dictionary = {}) -> Dictionary:
	if auth == null or auth.dev_session or not auth.session_valid(): return {"error":"Se requiere una sesión real. Las actividades publicadas no se sustituyen por respuestas locales."}
	var owner_id: String = auth.user_id
	var project: String = auth.client.project_url()
	var result: Dictionary = await auth.client.request_json("/rest/v1/rpc/"+method,HTTPClient.METHOD_POST,data,auth.access_token)
	if auth.user_id != owner_id or auth.client.project_url() != project or not auth.session_valid(): return {"error":"La sesión cambió. Abre nuevamente la actividad."}
	return {"data":result.data} if result.get("ok",false) else {"error":"No se pudo consultar la actividad. Comprueba conexión, permisos y migración 008."}

func fetch(floor_number: int, context: String, mentor: String = "") -> Dictionary:
	var data := {"p_floor":floor_number,"p_context":context}
	if not mentor.is_empty(): data["p_mentor"]=mentor
	var result := await rpc("get_learning_activity",data)
	return result.data if result.get("data") is Dictionary else result

func submit(id: String, answer: Variant, context: String) -> Dictionary:
	var result := await rpc("submit_learning_activity",{"p_id":id,"p_answer":answer,"p_context":context})
	return result.data if result.get("data") is Dictionary else result

func storage_path(path: String) -> String:
	return "/".join(Array(path.split("/")).map(func(part): return str(part).uri_encode()))

func upload_image(path: String) -> Dictionary:
	if auth == null or auth.dev_session or not auth.session_valid() or auth.role not in ["teacher","admin"]: return {"error":"Se requiere sesión docente autorizada."}
	var extension := path.get_extension().to_lower()
	if extension not in ["png","jpg","jpeg","webp"]: return {"error":"Usa PNG, JPEG o WebP."}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null or file.get_length()>5242880: return {"error":"La imagen no se puede leer o supera 5 MiB."}
	var bytes := file.get_buffer(file.get_length()); file.close()
	var image := Image.new()
	var decoded := image.load_png_from_buffer(bytes) if extension=="png" else (image.load_webp_from_buffer(bytes) if extension=="webp" else image.load_jpg_from_buffer(bytes))
	if decoded!=OK: return {"error":"La imagen no es válida."}
	var owner_id: String = auth.user_id
	var object_path := owner_id+"/"+Crypto.new().generate_random_bytes(16).hex_encode()+"."+extension
	var request := HTTPRequest.new(); request.timeout=20; request.max_redirects=0; request.body_size_limit=2097152
	auth.add_child(request)
	var mime := "image/png" if extension=="png" else ("image/webp" if extension=="webp" else "image/jpeg")
	var headers := PackedStringArray(["apikey: "+auth.client.publishable_key(),"Authorization: Bearer "+auth.access_token,"Content-Type: "+mime,"x-upsert: false"])
	var error := request.request_raw(auth.client.endpoint_url("/storage/v1/object/educational-images/"+storage_path(object_path)),headers,HTTPClient.METHOD_POST,bytes)
	if error!=OK: request.queue_free(); return {"error":"No se pudo iniciar la subida."}
	var result: Array = await request.request_completed
	request.queue_free()
	if auth.user_id!=owner_id or not auth.session_valid(): return {"error":"La sesión cambió durante la subida."}
	return {"path":object_path} if int(result[0])==HTTPRequest.RESULT_SUCCESS and int(result[1]) in [200,201] else {"error":"Subida rechazada. Comprueba migración 008, bucket y permisos."}

func image_texture(path: String) -> Texture2D:
	if path.is_empty() or auth==null or not auth.session_valid(): return null
	var owner_id: String = auth.user_id
	var request := HTTPRequest.new(); request.timeout=15; request.max_redirects=0; request.body_size_limit=5242880
	auth.add_child(request)
	var error := request.request(auth.client.endpoint_url("/storage/v1/object/authenticated/educational-images/"+storage_path(path)),auth.client.headers_for(auth.access_token))
	if error!=OK: request.queue_free(); return null
	var result: Array = await request.request_completed
	request.queue_free()
	if auth.user_id!=owner_id or int(result[0])!=HTTPRequest.RESULT_SUCCESS or int(result[1])!=200: return null
	var image := Image.new()
	var extension := path.get_extension().to_lower()
	var decoded := image.load_png_from_buffer(result[3]) if extension=="png" else (image.load_webp_from_buffer(result[3]) if extension=="webp" else image.load_jpg_from_buffer(result[3]))
	return ImageTexture.create_from_image(image) if decoded==OK else null

static func validate(data: Dictionary) -> String:
	for key in ["subject_id","unit","prompt","explanation"]:
		if str(data.get(key,"")).strip_edges().is_empty(): return "Completa asignatura, unidad, enunciado y explicación."
	if data.get("kind") not in KINDS: return "Tipo de actividad inválido."
	if data.get("difficulty") not in ["easy","medium","hard"]: return "Dificultad inválida."
	if int(data.get("retry_delay_seconds",0)) not in range(0,301) or int(data.get("max_attempts_per_day",0)) not in range(0,101): return "Configuración de reintentos inválida."
	if data.get("access_challenge",false) and int(data.get("max_attempts_per_day",0))!=0: return "Los desafíos de acceso deben permitir intentos ilimitados."
	if not data.get("content") is Dictionary or not data.has("answer"): return "Contenido y respuesta deben ser JSON válido."
	var content: Dictionary = data.content
	for key in ["answer","correct","correct_option","solution","explanation"]:
		if content.has(key): return "La solución debe estar en el campo privado."
	if data.kind == "reflection":
		return "Una reflexión no puede bloquear acceso." if data.get("access_challenge",false) else ""
	if data.kind in ["multiple_choice","true_false","identify","physical_zone"]:
		var options = content.get("options",[])
		if not options is Array or options.size()<2 or options.size()>8: return "Se requieren entre dos y ocho opciones."
		if data.kind == "multiple_choice" and options.size()!=4: return "Selección múltiple requiere cuatro alternativas."
		if data.kind == "true_false" and options.size()!=2: return "Verdadero/falso requiere dos alternativas."
		if not (data.answer is int or data.answer is float) or float(data.answer)!=floorf(float(data.answer)) or data.answer<0 or data.answer>=options.size(): return "La solución debe ser el índice de la alternativa (desde cero)."
	else:
		var items = content.get("items",[])
		if not items is Array or items.size()<2 or items.size()>12 or not data.answer is Array or items.size()!=data.answer.size(): return "La secuencia requiere de dos a doce elementos y una permutación de índices."
		var seen := {}
		for index in data.answer:
			if not (index is int or index is float) or float(index)!=floorf(float(index)) or index<0 or index>=items.size() or seen.has(int(index)): return "La solución no es una permutación válida."
			seen[int(index)] = true
	return ""
