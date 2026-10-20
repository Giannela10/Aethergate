extends Node
## One bounded HTTP GET callback, bound only to IPv4 loopback.
signal code_received(code: String)
signal failed(message: String)
var server := TCPServer.new()
var peer: StreamPeerTCP
var buffer := ""
var nonce := ""
var port := 8765
var deadline := 0
var peer_deadline := 0

func _ready() -> void:
	set_process(false)

func start(callback_port: int, state_nonce: String) -> Error:
	stop()
	port = callback_port
	nonce = state_nonce
	var err := server.listen(port, "127.0.0.1")
	deadline = Time.get_ticks_msec() + 180000
	set_process(err == OK)
	return err

func stop() -> void:
	server.stop()
	if peer: peer.disconnect_from_host()
	peer = null
	buffer = ""
	nonce = ""
	set_process(false)

func parse_request(header: String) -> Dictionary:
	var lines := header.split("\r\n")
	var first := lines[0].split(" ")
	if first.size() != 3 or first[0] != "GET" or first[2] != "HTTP/1.1": return {}
	var host_valid := false
	for line in lines:
		if line.to_lower() == "host: 127.0.0.1:%d" % port: host_valid = true
		if line.to_lower().begins_with("origin:"): return {}
	if not host_valid or not first[1].begins_with("/auth/callback?"): return {}
	var params := {}
	for item in first[1].get_slice("?", 1).split("&"):
		var key := item.get_slice("=", 0).uri_decode()
		if params.has(key): return {}
		params[key] = item.get_slice("=", 1).uri_decode()
	if nonce.is_empty() or params.get("nonce", "") != nonce: return {}
	if params.has("error"): return {"error":true}
	var code := str(params.get("code", ""))
	if code.is_empty() or code.length() > 2048: return {}
	return {"code":code}

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() > deadline:
		stop()
		failed.emit("El inicio de sesión agotó el tiempo. Intenta nuevamente.")
		return
	if not peer and server.is_connection_available():
		peer = server.take_connection()
		peer_deadline = Time.get_ticks_msec() + 3000
	if not peer: return
	peer.poll()
	if Time.get_ticks_msec() > peer_deadline or peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		peer.disconnect_from_host()
		peer = null
		buffer = ""
		return
	var available := peer.get_available_bytes()
	if available > 0: buffer += peer.get_utf8_string(mini(available,8192))
	if buffer.length() > 8192:
		peer.disconnect_from_host()
		peer = null
		buffer = ""
		return
	if not buffer.contains("\r\n\r\n"): return
	var result := parse_request(buffer)
	var valid := not result.is_empty()
	var html := "<!doctype html><meta charset='utf-8'><title>DuocGames</title><p>" + ("Inicio de sesión completado. Puedes volver a DuocGames." if result.has("code") else "Solicitud no válida o acceso cancelado. Vuelve a DuocGames.") + "</p>"
	peer.put_data(("HTTP/1.1 %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nCache-Control: no-store\r\nContent-Security-Policy: default-src 'none'\r\nConnection: close\r\n\r\n%s" % ["200 OK" if valid else "400 Bad Request",html.to_utf8_buffer().size(),html]).to_utf8_buffer())
	peer.disconnect_from_host()
	peer = null
	buffer = ""
	if valid:
		stop()
		if result.has("code"): code_received.emit(result.code)
		else: failed.emit("Acceso cancelado en el proveedor.")
