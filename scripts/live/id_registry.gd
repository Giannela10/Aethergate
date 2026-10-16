extends RefCounted
var ids: Dictionary = {}
var duplicates: Array[String] = []
static func valid_id(id: String) -> bool:
	if id.is_empty() or id.length() > 80: return false
	for character in ["/","\\",":",".","\n"]:
		if id.contains(character): return false
	return true
func reserve(kind: String, id: String, source: String) -> bool:
	var key := kind+":"+id
	if not valid_id(id): duplicates.append("Invalid "+key); return false
	if ids.has(key):
		if ids[key] != source: duplicates.append(key+" · "+str(ids[key])+" / "+source)
		return ids[key] == source
	ids[key] = source
	return true
