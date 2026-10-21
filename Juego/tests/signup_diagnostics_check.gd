extends Node
## Real HTTP diagnostics with no valid signup payload and no accounts created.
var finished := false
var result: Dictionary = {}

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var auth := get_node("/root/AuthManager")
	result = {"config":auth.client.configuration_summary(auth.config_source),"signup_endpoint":auth.client.endpoint_url("/auth/v1/signup"),"users_created":0,"valid_signup_sent":false,"original_signup_result":"NOT CAPTURED: user must retry manually","tables":{}}
	if auth.client.configured():
		var probe: Dictionary = await auth.client.debug_probe_signup_transport()
		result.signup_transport_probe = probe
		var settings: Dictionary = await auth.client.request_json("/auth/v1/settings")
		result.auth_http_status = int(settings.status)
		result.auth_accessible = settings.ok
		if settings.ok and settings.data is Dictionary:
			var external = settings.data.get("external",{})
			result.email_provider_enabled = external.get("email",false) == true if external is Dictionary else false
			result.signup_disabled = settings.data.get("disable_signup",false) == true
			if settings.data.has("mailer_autoconfirm"):
				result.email_confirmation_required = settings.data.mailer_autoconfirm == false
		for table in ["profiles","subjects","teacher_subjects","questions","question_keys","question_attempts"]:
			var response: Dictionary = await auth.client.request_json("/rest/v1/"+table+"?select=*&limit=0")
			var code := str(response.data.get("code","")) if response.get("data") is Dictionary else ""
			result.tables[table] = {"http_status":int(response.status),"not_found":code in ["PGRST205","42P01"],"auth_required":int(response.status) in [401,403]}
	var file := FileAccess.open("res://reports/signup_runtime_diagnostics.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result,"\t"))
		file.close()
	finished = true
	print("SIGNUP_RUNTIME_DIAGNOSTICS ",JSON.stringify(result))
