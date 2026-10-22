extends SceneTree
const Client = preload("res://scripts/auth/supabase_client.gd")
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	check(Client.parse_response_body("") == null,"Empty network response")
	check(Client.parse_response_body("   ") == null,"Whitespace response")
	check(Client.parse_response_body("<html>Unavailable</html>") == null,"Non-JSON proxy error")
	check(Client.parse_response_body('{"broken":') == null,"Truncated JSON")
	check(Client.parse_response_body('{"id":"fixture"}') == {"id":"fixture"},"Valid object")
	check(Client.parse_response_body("[]") == [],"Valid REST array")
	check(Client.parse_response_body('{"error_code":"invalid_credentials"}').error_code == "invalid_credentials","Preserve backend errors")
	check(Client.classify_failure(0,HTTPRequest.RESULT_TIMEOUT) == "timeout","Preserve transport failure kind")
	print("SUPABASE_RESPONSE_RESULT ",JSON.stringify({"checks":8,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
