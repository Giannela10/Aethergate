extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var auth := preload("res://tests/cloud_auth_fixture.gd").new()
	root.add_child(auth)
	var store := preload("res://scripts/education/cloud_save.gd").new()
	store.auth = auth
	store.journal_enabled = false
	root.add_child(store)
	check(await store.load_game(),"Existing account without save can load")
	check(store.revision == 0 and store.payload.is_empty(),"No shared legacy save is automatically claimed")
	var first := {"version":1,"save_version":2,"inventory":{"entries":[]},"credits":10,"settings":{"language":"es"}}
	check(store.enqueue(first),"Accept campaign snapshot")
	first.credits = 999
	check(await store.flush(),"Remote confirmation succeeds")
	check(store.payload.credits == 10 and store.revision == 1,"Queued snapshot is immutable")
	auth.sign_as("user-b")
	check(store.payload.is_empty() and not store.loaded,"Account switch clears prior account state")
	check(await store.load_game() and store.revision == 0,"Second account sees no first-account save")
	check(not store.enqueue({}) or store.pending.is_empty(),"Empty payload is not treated as a campaign")
	store.pending.clear()
	auth.sign_as("user-a")
	check(await store.load_game() and store.payload.credits == 10,"Existing account recovers its inventory and progress")
	auth.client.fail_next = true
	store.enqueue({"version":1,"save_version":2,"credits":20})
	check(not await store.flush(),"Network failure never reports success")
	check(not store.operation.is_empty() and store.payload.credits == 10,"Failed write retained without changing confirmed state")
	check(await store.flush() and store.payload.credits == 20,"Retry confirms pending state")
	auth.client.lose_response = true
	store.enqueue({"version":1,"save_version":2,"credits":30})
	var before := store.revision
	check(not await store.flush(),"Lost response remains unconfirmed")
	check(await store.flush() and store.revision == before+1,"Lost response retry is idempotent")
	auth.client.rows["user-a"].revision += 1
	store.enqueue({"version":1,"save_version":2,"credits":40})
	check(not await store.flush() and store.conflicted,"Other-device revision prevents overwrite")
	check(auth.client.rows["user-a"].payload.credits == 30,"Conflicting write does not change server payload")
	check(await store.discard_and_reload() and not store.conflicted,"Explicit reload recovers conflict")
	auth.expired = true
	store.pending = {"version":1,"save_version":2,"credits":50}
	check(await store.flush() and store.payload.credits == 50,"Token refresh preserves same-account pending write")
	auth.client.hold = true
	store.enqueue({"version":1,"save_version":2,"credits":60})
	store._drain()
	await process_frame
	auth.sign_as("user-b")
	auth.client.release = true
	await process_frame
	check(not store.loaded and store.payload.is_empty(),"Late previous-account response is ignored")
	check(await store.load_game() and store.revision == 0,"Late response never contaminates new account")
	auth.client.rows["user-b"] = {"revision":1,"payload":{"version":1,"save_version":999}}
	check(not await store.load_game(true),"Future save version is not overwritten")
	store.queue_free()
	auth.queue_free()
	await process_frame
	print("CLOUD_SAVE_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"remote_database_tested":false}))
	quit(0 if failures.is_empty() else 1)
