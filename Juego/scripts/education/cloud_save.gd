extends Node
## Authoritative per-account campaign store. No shared local fallback.
signal status_changed(message: String)
var auth: Node
var account_id := ""
var project := ""
var generation := 0
var loaded := false
var busy := false
var conflicted := false
var revision := 0
var payload: Dictionary = {}
var pending: Dictionary = {}
var operation: Dictionary = {}
var last_error := ""
var retry_seconds := 0.0
var closing := false
var pending_backup := false
var journal := preload("res://scripts/education/pending_save_journal.gd").new()
var journal_enabled := true

func _persist_queue() -> bool:
	if not journal_enabled: return true
	if journal.write(project,account_id,{"revision":revision,"payload":payload,"pending":pending,"operation":operation,"pending_backup":pending_backup}): return true
	return _fail("No se pudo proteger el guardado pendiente en disco. Comprueba el espacio y los permisos.")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if auth == null: auth = get_node("/root/AuthManager")
	auth.session_changed.connect(_session_changed)
	get_window().close_requested.connect(_close_requested)

func _close_requested() -> void:
	if closing: return
	if not loaded:
		get_tree().quit()
		return
	closing = true
	var campaign := get_tree().get_first_node_in_group("campus_campaign")
	if campaign and campaign.cloud_mode: campaign.save_game()
	if await flush():
		get_tree().quit()
		return
	closing = false
	if campaign and is_instance_valid(campaign.ui):
		campaign.ui.dialog("PARTIDA SIN GUARDAR",last_error,["Reintentar y salir","Seguir jugando"],[_close_requested,campaign.ui.close_modal],true)

func available() -> bool:
	return not auth.dev_session and auth.can_enter_menu() and auth.role in ["student","teacher","admin"]

func _session_changed() -> void:
	# Token renewal for the same account must not discard an outstanding write.
	if account_id == auth.user_id and project == auth.client.project_url() and auth.can_enter_menu(): return
	generation += 1
	account_id = ""
	project = ""
	loaded = false
	busy = false
	conflicted = false
	revision = 0
	payload.clear()
	pending.clear()
	pending_backup = false
	operation.clear()
	last_error = ""
	get_tree().auto_accept_quit = true

func _same_session(ticket: int) -> bool:
	return ticket == generation and account_id == auth.user_id and project == auth.client.project_url()

func _token_ready() -> bool:
	if auth.session_valid(): return available()
	return await auth.refresh_session() and available()

func load_game(force: bool = false) -> bool:
	if busy: return false
	if conflicted and not force: return _fail("La partida cambió en otro dispositivo. Carga la partida de la nube para continuar.")
	if not await _token_ready(): return _fail("Inicia sesión para cargar tu partida.")
	if loaded and account_id == auth.user_id and project == auth.client.project_url() and not force: return true
	if not pending.is_empty() or not operation.is_empty(): return _fail("Hay cambios pendientes de guardar. Reintenta la sincronización.")
	account_id = auth.user_id
	project = auth.client.project_url()
	loaded = false
	var ticket := generation
	busy = true
	var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/load_campaign",HTTPClient.METHOD_POST,{},auth.access_token)
	if not _same_session(ticket): return false
	busy = false
	if not response.get("ok",false) or not response.get("data") is Dictionary:
		return _fail("No se pudo cargar la partida de Supabase. Comprueba la conexión y la migración 007.")
	var row: Dictionary = response.data
	if not row.get("payload") is Dictionary or int(row.get("revision",-1)) < 0:
		return _fail("Supabase devolvió una partida inválida.")
	var candidate: Dictionary = row.payload
	if not candidate.is_empty() and not preload("res://scripts/live/save_migration.gd").supported(candidate):
		return _fail("Esta partida pertenece a otra versión del juego. No se sobrescribirá.")
	payload = candidate.duplicate(true)
	revision = int(row.revision)
	loaded = true
	get_tree().auto_accept_quit = false
	conflicted = false
	if journal_enabled:
		var recovered: Dictionary = journal.recover(project,account_id)
		if not recovered.is_empty() and (not recovered.pending.is_empty() or not recovered.operation.is_empty()):
			pending = recovered.pending.duplicate(true)
			operation = recovered.operation.duplicate(true)
			pending_backup = bool(recovered.get("pending_backup",false))
			# Retry the exact operation ID first: the server may already have committed it.
			if not operation.is_empty(): revision = int(operation.p_revision)
			elif int(recovered.get("revision",-1)) != revision:
				conflicted = true
				return _fail("Hay cambios locales pendientes y otra revisión remota. Conservamos ambas; elige recuperar la nube o resolver el conflicto.")
			if not await flush(): return false
	last_error = ""
	status_changed.emit("Partida cargada de Supabase." if revision > 0 else "Esta cuenta todavía no tiene partida.")
	return true

func enqueue(value: Dictionary, backup: bool = false) -> bool:
	if value.is_empty() or not preload("res://scripts/live/save_migration.gd").supported(value): return _fail("La partida no tiene un formato compatible.")
	if not loaded or conflicted or auth.dev_session or auth.role not in ["student","teacher","admin"] or account_id != auth.user_id or project != auth.client.project_url():
		return _fail("No se pudo guardar: la sesión o la partida no están listas.")
	pending = value.duplicate(true)
	pending_backup = pending_backup or backup
	if not _persist_queue(): return false
	if not busy: _drain.call_deferred()
	return true

func _fail(message: String) -> bool:
	last_error = message
	status_changed.emit(message)
	return false

func _process(delta: float) -> void:
	if busy or conflicted or (pending.is_empty() and operation.is_empty()): return
	retry_seconds -= delta
	if retry_seconds <= 0:
		retry_seconds = 10.0
		_drain()

func _drain() -> void:
	if busy or conflicted or not loaded or (pending.is_empty() and operation.is_empty()): return
	busy = true
	var ticket := generation
	while not pending.is_empty() or not operation.is_empty():
		if not await _token_ready() or not _same_session(ticket):
			if _same_session(ticket):
				busy = false
				_fail("La partida no se ha guardado. Renueva tu sesión y reintenta.")
			return
		if operation.is_empty():
			operation = {"p_payload":pending.duplicate(true),"p_revision":revision,"p_request_id":Crypto.new().generate_random_bytes(16).hex_encode(),"p_backup":pending_backup}
			pending.clear()
			pending_backup = false
		if not _persist_queue():
			busy = false
			return
		var response: Dictionary = await auth.client.request_json("/rest/v1/rpc/save_campaign",HTTPClient.METHOD_POST,operation,auth.access_token)
		if not _same_session(ticket): return
		if not response.get("ok",false) or not response.get("data") is Dictionary:
			busy = false
			retry_seconds = 10.0
			_fail("Pendiente de sincronización con Supabase. Hay una copia local de recuperación." if journal_enabled else "No se ha guardado en Supabase. Se reintentará; conserva el juego abierto.")
			return
		var row: Dictionary = response.data
		if row.get("conflict",false):
			conflicted = true
			busy = false
			_fail("La partida cambió en otro dispositivo. Vuelve a cargar la partida de la nube para continuar.")
			return
		if int(row.get("revision",0)) != int(operation.p_revision)+1 or str(row.get("request_id","")) != str(operation.p_request_id):
			busy = false
			_fail("No se pudo confirmar el guardado en Supabase.")
			return
		revision = int(row.revision)
		payload = operation.p_payload.duplicate(true)
		operation.clear()
		if not _persist_queue():
			busy = false
			return
		last_error = ""
	busy = false
	status_changed.emit("Partida guardada en Supabase.")

func flush() -> bool:
	while busy:
		await get_tree().process_frame
	if conflicted: return false
	if not pending.is_empty() or not operation.is_empty(): await _drain()
	return loaded and pending.is_empty() and operation.is_empty() and last_error.is_empty()

func discard_and_reload() -> bool:
	if busy: return false
	pending.clear()
	pending_backup = false
	operation.clear()
	if not account_id.is_empty() and not _persist_queue(): return false
	return await load_game(true)
