class_name SaveStore
extends RefCounted
## Файлы сохранений в user://saves/ (Steam Cloud синхронизирует эту папку целиком, Auto-Cloud).
## Слоты: auto — автосейв на входе в сцену, quick — быстрое сохранение, slot_1…slot_N — ручные,
## battle — бой в процессе (только для продолжения после выхода, удаляется после боя).

const DIR := "user://saves/"
const MANUAL_SLOTS := 6

static var dir := DIR


static func path_of(slot: String) -> String:
	return dir + slot + ".json"


static func slots() -> Array[String]:
	var out: Array[String] = ["auto", "quick"]
	for i in MANUAL_SLOTS:
		out.append("slot_%d" % (i + 1))
	return out


## Записать атомарно: сначала во временный файл, потом переименовать (обрыв не портит старое сохранение).
static func write(slot: String, data: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(dir)
	data = data.duplicate()
	data["slot"] = slot
	data["time"] = Time.get_unix_time_from_system()
	var tmp := path_of(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data))
	f.close()
	return DirAccess.rename_absolute(tmp, path_of(slot))


static func read(slot: String) -> Dictionary:
	if not FileAccess.file_exists(path_of(slot)):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path_of(slot)))
	return d if d is Dictionary else {}


static func exists(slot: String) -> bool:
	return FileAccess.file_exists(path_of(slot))


static func remove(slot: String) -> void:
	if exists(slot):
		DirAccess.remove_absolute(path_of(slot))


## Самое свежее сюжетное сохранение (для «Продолжить»): имя слота или "".
static func latest() -> String:
	var best := ""
	var best_time := -1.0
	for s in slots():
		var d := read(s)
		if not d.is_empty() and float(d.get("time", 0)) > best_time:
			best_time = float(d.time)
			best = s
	return best
