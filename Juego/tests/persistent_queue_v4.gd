extends SceneTree
class FaultJournal extends "res://scripts/education/pending_save_journal.gd":
	var disk_failed := false
	func write(project_id: String, account: String, value: Dictionary) -> bool:
		return false if disk_failed else super.write(project_id,account,value)
var checks := 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var auth := preload("res://tests/cloud_auth_fixture.gd").new()
	root.add_child(auth)
	var journal := FaultJournal.new()
	journal.directory = "res://tests/tmp_queue_v4_" + str(Time.get_ticks_usec())
	var store := preload("res://scripts/education/cloud_save.gd").new()
	store.auth = auth
	store.journal = journal
	root.add_child(store)
	check(await store.load_game(),"Initial load")
	auth.client.lose_response = true
	store.enqueue({"version":1,"save_version":2,"credits":123})
	check(not await store.flush(),"Lost acknowledgment")
	var id: String = store.operation.p_request_id
	store.set_process(false)
	store.queue_free()
	await process_frame
	store = preload("res://scripts/education/cloud_save.gd").new()
	store.auth = auth
	store.journal = journal
	root.add_child(store)
	check(await store.load_game(),"Restart recovers and retries operation")
	check(store.payload.get("credits") == 123 and store.revision == 1,"Restart does not duplicate committed operation")
	var retries: Array = auth.client.requests.filter(func(r): return r.body.get("p_request_id", "") == id)
	check(retries.size() >= 2,"Stable operation ID survives restart")
	check(journal.recover(auth.client.project_url(),"user-b").is_empty(),"Other account cannot recover queue")
	auth.client.fail_next = true
	store.enqueue({"version":1,"save_version":2,"credits":200})
	check(not await store.flush(),"Network failure persisted")
	auth.client.rows["user-a"].revision += 1
	store.queue_free()
	await process_frame
	store = preload("res://scripts/education/cloud_save.gd").new()
	store.auth = auth
	store.journal = journal
	root.add_child(store)
	check(not await store.load_game() and store.conflicted,"Second-device edit blocks stale replay after restart")
	check(not store.operation.is_empty(),"Conflict retains pending operation")
	check(await store.discard_and_reload(),"Explicit remote recovery resolves conflict")
	check(journal.recover(auth.client.project_url(),auth.user_id).operation.is_empty(),"Discard tombstone prevents resurrection")
	var requests_before: int=auth.client.requests.size()
	journal.disk_failed=true
	check(not store.enqueue({"version":1,"save_version":2,"credits":300}),"Disk failure reports enqueue failure")
	await store._drain()
	await store._drain()
	check(auth.client.requests.size()==requests_before,"Repeated drains cannot send an unprotected operation after disk failure")
	journal.disk_failed=false
	check(await store.flush() and store.payload.credits==300,"Disk recovery persists and synchronizes the same pending operation")
	var second_device := preload("res://scripts/education/cloud_save.gd").new()
	second_device.auth=auth; second_device.journal_enabled=false; root.add_child(second_device)
	check(await second_device.load_game(),"Second device loads the same account revision")
	var shared_revision: int=store.revision
	auth.client.hold=true; auth.client.release=false
	store.enqueue({"version":1,"save_version":2,"credits":400})
	second_device.enqueue({"version":1,"save_version":2,"credits":500})
	store._drain(); second_device._drain()
	await process_frame
	check(store.busy and second_device.busy,"Two devices can have simultaneous in-flight writes")
	auth.client.release=true
	var deadline := Time.get_ticks_msec()+10000
	while (store.busy or second_device.busy) and Time.get_ticks_msec()<deadline: await process_frame
	check(int(store.conflicted)+int(second_device.conflicted)==1 and int(auth.client.rows[auth.user_id].revision)==shared_revision+1,"Exactly one simultaneous write commits; the other retains a conflict")
	check(auth.client.rows[auth.user_id].payload.credits in [400,500],"Concurrent devices never combine or duplicate rewards")
	check(await store.discard_and_reload(),"Explicit recovery selects the winning remote revision")
	second_device.queue_free()
	auth.client.hold=false
	var state := {"revision":0,"payload":{},"pending":{"version":1,"save_version":2},"operation":{}}
	check(journal.write("test-project","test-user",state),"Journal atomic write")
	check(journal.write("test-project","test-user",state),"Backup generation")
	var path: String = journal._path("test-project","test-user")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(not journal.recover("test-project","test-user").is_empty(),"Corrupt primary recovers backup")
	store.queue_free()
	auth.queue_free()
	await process_frame
	var directory := DirAccess.open(journal.directory)
	for name in directory.get_files(): directory.remove(name)
	DirAccess.remove_absolute(journal.directory)
	print("PERSISTENT_QUEUE_V4_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"remote_database_tested":false}))
	quit(0 if failures.is_empty() else 1)
