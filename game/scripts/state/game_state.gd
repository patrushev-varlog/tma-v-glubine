class_name GameState
extends RefCounted
## Состояние партии вне Ink: герой, уровень, серебро, вещи, журнал «Слухи и следы», боевая Тьма.
## Сюжетные флаги и шкала Тьмы живут в переменных Ink (источник правды); здесь — только то,
## что игра узнаёт из тегов строк (# levelup, # item, # silver, # journal …) и из боёв.
## Всё здесь выводится из истории и журнала событий, поэтому проигрывание журнала даёт то же состояние.

const SAVE_VERSION := 1

## Создание героя: class, hero_f, name, spouse_f, spouse_name, spouse_id ("" — своё имя).
var hero := {}
var difficulty := "story"
var chapter := 0
var level := 1
var silver := 0
## Вещи отряда: [{"id", "owner"}], owner — "hero", "garret", "irena" или "velior".
var inventory: Array[Dictionary] = []
## Записи журнала: [{"id", "text"}] в порядке получения.
var journal: Array[Dictionary] = []
## Открытое тегом # unlock: (dark_gifts — тёмные дары в бою после пролога).
var unlocks: Array[String] = []
## Изменения карт (# map:) — для экранов исследования.
var map_changes: Array[String] = []
## Боевая Тьма за игру: дары и тёмные предметы, не выше combat_dark_cap.
var combat_darkness := 0
## Пройденные бои: id → число побед (необязательные бои охот тоже здесь).
var battles := {}
var ending := ""


func apply_tags(tags: PackedStringArray, text: String) -> void:
	var owner := "hero"
	for t in tags:
		if t.begins_with("to:"):
			owner = t.substr(3).strip_edges()
	for t in tags:
		var kv := t.split(":", true, 1)
		if kv.size() < 2:
			continue
		var key := kv[0].strip_edges()
		var value := kv[1].strip_edges()
		match key:
			"chapter":
				chapter = int(value)
			"levelup":
				level = maxi(level, int(value))
			"silver":
				silver = maxi(silver + int(value), 0)
			"item":
				inventory.append({"id": value, "owner": owner})
			"item_remove":
				for i in inventory.size():
					if inventory[i].id == value:
						inventory.remove_at(i)
						break
			"journal":
				if not has_journal(value):
					journal.append({"id": value, "text": _journal_text(text)})
			"unlock":
				if not unlocks.has(value):
					unlocks.append(value)
			"map":
				if not map_changes.has(value):
					map_changes.append(value)
			"ending":
				ending = value


## Текст записи из строки «Отметка в журнале: «…»» — то, что в кавычках, иначе вся строка.
static func _journal_text(text: String) -> String:
	var a := text.find("«")
	var b := text.rfind("»")
	if a >= 0 and b > a:
		return text.substr(a + 1, b - a - 1)
	return text.strip_edges()


func has_journal(id: String) -> bool:
	for e in journal:
		if e.id == id:
			return true
	return false


func items_of(owner: String) -> Array[String]:
	var out: Array[String] = []
	for it in inventory:
		if it.owner == owner:
			out.append(String(it.id))
	return out


## Сколько боевой Тьмы ещё можно набрать за игру.
func combat_dark_room() -> int:
	return maxi(int(CombatData.rules().combat_dark_cap) - combat_darkness, 0)


## Глубокая копия: снимок на входе в сцену не должен меняться вместе с текущим состоянием.
func to_dict() -> Dictionary:
	var d := {
		"version": SAVE_VERSION, "hero": hero, "difficulty": difficulty, "chapter": chapter, "level": level,
		"silver": silver, "inventory": inventory, "journal": journal, "unlocks": Array(unlocks),
		"map_changes": Array(map_changes), "combat_darkness": combat_darkness, "battles": battles, "ending": ending,
	}
	return d.duplicate(true)


static func from_dict(d: Dictionary) -> GameState:
	var g := GameState.new()
	d = CombatData.whole_numbers(d)
	g.hero = d.get("hero", {})
	g.difficulty = String(d.get("difficulty", "story"))
	g.chapter = int(d.get("chapter", 0))
	g.level = int(d.get("level", 1))
	g.silver = int(d.get("silver", 0))
	for it in d.get("inventory", []):
		g.inventory.append(it)
	for e in d.get("journal", []):
		g.journal.append(e)
	for u in d.get("unlocks", []):
		g.unlocks.append(String(u))
	for m in d.get("map_changes", []):
		g.map_changes.append(String(m))
	g.combat_darkness = int(d.get("combat_darkness", 0))
	g.battles = d.get("battles", {})
	g.ending = String(d.get("ending", ""))
	return g
