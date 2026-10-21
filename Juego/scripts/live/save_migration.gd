extends RefCounted
const CURRENT := 2
static func defaults() -> Dictionary:
	return {"once":{},"discoveries":{},"moments":{},"journal":[],"dialogues":[],"markers":[],"contact_favorites":{},"classrooms":{},"reward_spent":0,"cooldown":90.0}
static func migrate(raw: Dictionary) -> Dictionary:
	var result := raw.duplicate(true)
	var live = result.get("campus_live",{})
	if not live is Dictionary: live = {}
	var normalized := defaults()
	for key in normalized:
		if live.has(key) and typeof(live[key]) == typeof(normalized[key]):
			normalized[key] = live[key]
		elif key == "cooldown" and (live.get(key) is float or live.get(key) is int):
			normalized[key] = clampf(float(live[key]),30,900)
		elif normalized[key] is int and (live.get(key) is float or live.get(key) is int):
			normalized[key] = int(live[key])
	for key in ["journal","dialogues","markers"]:
		normalized[key] = normalized[key].filter(func(value): return value is Dictionary).slice(-80 if key == "journal" else (-20 if key == "dialogues" else -3))
	normalized.reward_spent = clampi(int(normalized.reward_spent),0,100000)
	normalized.cooldown = clampf(float(normalized.cooldown),30,900)
	result.campus_live = normalized
	result.version = 1
	result.save_version = CURRENT
	# Completing the legacy archive remains completed, but no longer ends the campaign.
	result.campaign_completed = raw.get("campaign_completed",false) == true or raw.get("bosses",{}).get("nexo",false) == true
	result = preload("res://scripts/campaign/academic_expansion_data.gd").migrate(result)
	return preload("res://scripts/education/academic_progress.gd").migrate(result)
static func supported(raw: Dictionary) -> bool:
	return int(raw.get("version",-1)) in [1,2] and int(raw.get("save_version",1)) in range(1,CURRENT+1)
