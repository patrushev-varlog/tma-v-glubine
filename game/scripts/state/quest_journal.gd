class_name QuestJournal
extends RefCounted
## Журнал заданий: главная цель главы и побочные задания (охоты за легендарками, загадка двери).
## Состояние заданий не хранится отдельно: оно выводится из переменных Ink и записей журнала
## (data/story/quests.json), поэтому всегда совпадает с историей.

const PATH := "res://data/story/quests.json"


static func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH))


## Задания для экрана журнала: [{"id", "title_key", "state" ("active"/"done"), "clues", "clues_max", "notes": [текст]}].
## Первым идёт главная цель текущей главы.
static func entries(session: StorySession) -> Array[Dictionary]:
	var data := _data()
	var out: Array[Dictionary] = []
	var main_id := String(data.main.get(session.chapter_name(), ""))
	if main_id != "":
		out.append({"id": main_id, "title_key": "QUEST_" + main_id, "state": "active", "notes": []})
	for q in data.side:
		var visible := false
		var active := String(q.active)
		if active.begins_with("journal:"):
			visible = _notes(session, active.substr(8)).size() > 0
		else:
			visible = bool(session.flag(active))
		if not visible:
			continue
		var e := {"id": q.id, "title_key": "QUEST_" + String(q.id), "notes": _notes(session, String(q.id)),
			"state": "done" if bool(session.flag(String(q.done))) else "active"}
		if q.has("clues"):
			e["clues"] = int(session.flag(String(q.clues)))
			e["clues_max"] = int(q.clues_max)
		out.append(e)
	return out


## Записи «Слухов и следов» с id, начинающимся с prefix.
static func _notes(session: StorySession, prefix: String) -> Array[String]:
	var out: Array[String] = []
	for j in session.state.journal:
		if String(j.id).begins_with(prefix):
			out.append(String(j.text))
	return out
