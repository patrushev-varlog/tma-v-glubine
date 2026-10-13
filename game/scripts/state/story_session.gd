class_name StorySession
extends RefCounted
## Прохождение истории: Ink через StoryRunner, состояние партии (GameState), журнал событий и сохранения.
##
## Журнал событий — всё, что игрок вносит в историю: выбор варианта, исход боя, осмотр на карте.
## История детерминирована, поэтому журнал с начала игры восстанавливает любое место.
## Сохранение (DESIGN.md, раздел 2): родное состояние Ink и состояние партии на входе в сцену
## плюс весь журнал. Тот же язык и та же версия истории — грузим состояние сцены и доигрываем
## журнал внутри сцены; другой язык или правленый текст — проигрываем журнал с начала игры
## (вся история проигрывается за доли секунды).

signal scene_entered(scene: String)

const SAVE_VERSION := 1
const SCENES_PATH := "res://story/scenes.json"
const SPOUSE_PATH := "res://data/hero/spouse_names.json"
## Падежи имени супруга. Если в Ink объявлены переменные spouse_name_<падеж>, игра их заполняет.
const CASES: Array[String] = ["gen", "dat", "acc", "ins", "pre"]

var runner := StoryRunner.new()
var state := GameState.new()
## События: {"pick": i} | {"battle": id, "dark": n} | {"explore": узел, "args": []} | {"var": имя, "value": v}
##   | {"branch": ветка} (повышение уровня в лагере) | {"shop": торговец, "buy": [[предмет, владелец], …]}.
var events: Array[Dictionary] = []
## Сцены всей истории по порядку (story/scenes.json).
var scenes: Array = []
## Индекс текущей сцены в scenes (−1 — до первой).
var scene_idx := -1
## Снимок на входе в текущую сцену: log_index, ink, game, scene_idx, flow.
var entry := {}
## Бой, который ждёт исхода (тег # battle: на последней показанной строке).
var pending_battle := ""
## Повышение уровня, которое ждёт выбора ветки (тег # levelup:N в лагере); 0 — нет.
var pending_levelup := 0
## Торговец, который ждёт покупок (тег # shop:<id>); "" — нет.
var pending_shop := ""
## "" — основной сюжет, "explore" — осмотр объекта на карте (отдельный поток Ink).
var flow := ""
## Где стоит герой на карте локации: {"location", "x", "y"}; пусто — на точке входа сцены.
## Не событие журнала: в сохранение идёт как есть, на входе в новую сцену сбрасывается.
var map_pos := {}

var _mark := {}
var _replaying := false
## При проигрывании с начала снимок нужен только в одной точке журнала.
var _mark_target := -1


func _init() -> void:
	scenes = JSON.parse_string(FileAccess.get_file_as_string(SCENES_PATH)).scenes


# --- Новая игра ---------------------------------------------------------------

## setup: hero (class, hero_f, name, spouse_f, spouse_name, spouse_id) и difficulty.
func new_game(setup: Dictionary, lang := "ru") -> void:
	state = GameState.new()
	state.hero = setup.hero.duplicate()
	state.difficulty = String(setup.get("difficulty", "story"))
	events.clear()
	_restart(lang)
	_set_mark()


func _restart(lang: String) -> void:
	runner.load_language(lang)
	scene_idx = -1
	entry = {}
	pending_battle = ""
	pending_levelup = 0
	pending_shop = ""
	flow = ""
	_apply_setup()


## Переменные героя в Ink. Имя супруга из списка ставится на языке истории, своё имя — как введено.
func _apply_setup() -> void:
	var h := state.hero
	runner.set_var("hero_class", String(h.get("class", "fighter")))
	runner.set_var("hero_f", bool(h.get("hero_f", false)))
	runner.set_var("spouse_f", bool(h.get("spouse_f", true)))
	var forms := spouse_forms(String(h.get("spouse_id", "")), bool(h.get("spouse_f", true)), runner.language)
	var nom: String = forms.get("nom", String(h.get("spouse_name", "")))
	if nom == "":
		nom = String(h.get("spouse_name", ""))
	runner.set_var("spouse_name", nom)
	for c in CASES:
		if runner.has_var("spouse_name_" + c):
			runner.set_var("spouse_name_" + c, String(forms.get(c, nom)))


## Формы имени супруга из data/hero/spouse_names.json: {"nom", "gen", …}; для своего имени — пусто.
static func spouse_forms(spouse_id: String, female: bool, lang: String) -> Dictionary:
	if spouse_id == "":
		return {}
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPOUSE_PATH))
	for n in data["f" if female else "m"]:
		if n.id == spouse_id:
			var forms = n.get(lang, n.ru)
			return forms if forms is Dictionary else {"nom": String(forms)}
	return {}


# --- Ход истории ----------------------------------------------------------------

## Следующее, что показать игроку:
##   {"type": "line", "text", "tags", "speaker", "mood", "sfx", "scene"} — строка (scene — только у первой строки
##     сцены; sfx — звук по тегу # sfx:<id>, экран играет его вместе со строкой);
##   {"type": "choices", "options": PackedStringArray, "objects": Array[String]} — objects[i] — объект
##     на карте для варианта i (тег #obj:) или "", если вариант — обычная кнопка;
##   {"type": "battle", "id"} — нужен исход боя (win_battle);
##   {"type": "levelup", "level"} — новый уровень: выбрать ветку или оставить (choose_branch);
##   {"type": "shop", "id"} — торговец: покупки (leave_shop);
##   {"type": "explore_end"} — осмотр закончился, основной сюжет стоит там же;
##   {"type": "end"} — история закончилась.
## Звуки строк с находками и записями в журнал (теги # silver:, # item:, # journal:).
const AUTO_SFX := {"silver": "coin", "item": "pickup", "journal": "journal"}


func next() -> Dictionary:
	if pending_battle != "":
		return {"type": "battle", "id": pending_battle}
	if pending_levelup > 0:
		return {"type": "levelup", "level": pending_levelup}
	if pending_shop != "":
		return {"type": "shop", "id": pending_shop}
	if runner.can_continue():
		var line := runner.next_line()
		var tags: PackedStringArray = line.tags
		state.apply_tags(tags, line.text)
		var out := {"type": "line", "text": line.text, "tags": tags, "speaker": "", "mood": "", "sfx": ""}
		for t in tags:
			var kv := t.split(":", true, 1)
			if kv.size() < 2:
				continue
			match kv[0].strip_edges():
				"spk":
					out.speaker = kv[1].strip_edges()
				"mood":
					out.mood = kv[1].strip_edges()
				"sfx":
					out.sfx = kv[1].strip_edges()
				"silver", "item", "journal":
					# Находка или запись в журнале звучит сама, если у строки нет своего звука.
					if out.sfx == "" and not kv[1].strip_edges().begins_with("-"):
						out.sfx = AUTO_SFX[kv[0].strip_edges()]
				"battle":
					pending_battle = kv[1].strip_edges()
				"levelup":
					pending_levelup = int(kv[1])
				"shop":
					pending_shop = kv[1].strip_edges()
		var scene := _check_scene()
		if scene != "":
			out["scene"] = scene
		return out
	var options := runner.choices()
	if not options.is_empty():
		var objects: Array[String] = []
		for tags in runner.choice_tags():
			var obj := ""
			for t in tags:
				if t.begins_with("obj:"):
					obj = t.substr(4).strip_edges()
			objects.append(obj)
		return {"type": "choices", "options": options, "objects": objects}
	if flow != "":
		runner.default_flow()
		flow = ""
		return {"type": "explore_end"}
	return {"type": "end"}


func choose(index: int) -> void:
	_apply({"pick": index})


## Исход боя. darkness — боевая Тьма за бой (дары и тёмные предметы); в Тьму Ink идёт не больше,
## чем осталось до потолка за игру.
func win_battle(darkness := 0) -> void:
	assert(pending_battle != "", "Нет боя, который ждёт исхода")
	_apply({"battle": pending_battle, "dark": darkness})


## Ветка класса на новом уровне (DESIGN.md, «Умения в бою»): на 2 уровне выбор, дальше в каждом лагере
## её можно сменить — умения новой ветки приходят сразу все по текущему уровню.
func choose_branch(branch: String) -> void:
	assert(pending_levelup > 0, "Нет повышения уровня, которое ждёт выбора")
	_apply({"branch": branch})


## Уйти от торговца. buy — [[предмет, владелец], …]; цены считает Shops, серебро списывается здесь.
func leave_shop(buy: Array = []) -> void:
	assert(pending_shop != "", "Нет торговца, который ждёт покупок")
	_apply({"shop": pending_shop, "buy": buy})


## Осмотр объекта на карте: узел Ink в отдельном потоке (story/ink/explore_common.ink).
## Можно, только когда основной сюжет ждёт выбора игрока.
func explore(node: String, args: Array = []) -> void:
	assert(flow == "" and not runner.can_continue() and pending_battle == "", "Осмотр — только когда сюжет ждёт игрока")
	_apply({"explore": node, "args": args})


func _apply(ev: Dictionary) -> void:
	events.append(ev)
	if ev.has("pick"):
		runner.choose(int(ev.pick))
	elif ev.has("battle"):
		var id := String(ev.battle)
		state.battles[id] = int(state.battles.get(id, 0)) + 1
		# Добыча после боя (design/equipment-catalog.md: 10–15 серебра за бой главы).
		var bt: Dictionary = CombatData.table("battles").get(id, {})
		state.silver += int(bt.get("silver", 0))
		var dark := mini(int(ev.get("dark", 0)), state.combat_dark_room())
		if dark > 0:
			state.combat_darkness += dark
			runner.set_var("darkness", clampi(int(runner.get_var("darkness")) + dark, 0, 100))
		pending_battle = ""
	elif ev.has("explore"):
		flow = "explore"
		runner.switch_flow("explore")
		runner.go_to(String(ev.explore), ev.get("args", []))
	elif ev.has("var"):
		runner.set_var(String(ev["var"]), ev.value)
	elif ev.has("branch"):
		state.branch = String(ev.branch)
		pending_levelup = 0
	elif ev.has("shop"):
		for b in ev.get("buy", []):
			var price := Shops.price(String(ev.shop), String(b[0]))
			if price < 0 or price > state.silver:
				continue
			state.silver -= price
			state.inventory.append({"id": String(b[0]), "owner": String(b[1])})
		pending_shop = ""
	_set_mark()


## Снимок для входа в сцену: после каждого события (родное сохранение Ink — 2–8 мс).
func _set_mark() -> void:
	if _replaying and events.size() != _mark_target:
		return
	_mark = {"log_index": events.size(), "ink": runner.save_state(), "game": state.to_dict(),
		"scene_idx": scene_idx, "flow": flow}


## Вошли ли в следующую сцену: история стоит в узле одной из следующих сцен. Возвращает имя сцены.
func _check_scene() -> String:
	if flow != "":
		return ""
	var knot := runner.current_path().get_slice(".", 0)
	if knot == "":
		return ""
	for j in range(scene_idx + 1, scenes.size()):
		if String(scenes[j].scene) == knot:
			scene_idx = j
			entry = _mark.duplicate()
			entry["scene"] = knot
			map_pos = {}
			if not _replaying:
				scene_entered.emit(knot)
			return knot
	return ""


func scene_name() -> String:
	return String(scenes[scene_idx].scene) if scene_idx >= 0 else ""


func chapter_name() -> String:
	return String(scenes[scene_idx].chapter) if scene_idx >= 0 else "prologue"


# --- Сюжетные флаги и отряд (из переменных Ink) ---------------------------------

func darkness() -> int:
	return int(runner.get_var("darkness"))


func flag(name: String) -> Variant:
	return runner.get_var(name) if runner.has_var(name) else null


## Все переменные Ink: имя → значение (для журнала и отладки).
func flags() -> Dictionary:
	var out := {}
	for n in runner.var_names():
		out[n] = runner.get_var(n)
	return out


## Спутники в отряде сейчас: Гаррет всегда; Велиор — с главы 1, пока его не изгнали и не убили;
## Ирена — пока не ушла после конфронтации в главе 4.
func companions() -> Array[String]:
	var out: Array[String] = []
	if String(flag("irena_confronted")) != "left":
		out.append("irena")
	out.append("garret")
	if String(flag("velior_terms")) != "" and not ["exiled", "killed"].has(String(flag("velior_fate"))):
		out.append("velior")
	return out


## Состав для правил боя (rules.json parties): full, no_velior, no_irena, duo.
func party_key() -> String:
	var c := companions()
	if state.level <= 1:
		return "full" if c.has("irena") else "no_irena"
	if c.has("irena") and c.has("velior"):
		return "full"
	if c.has("irena"):
		return "no_velior"
	if c.has("velior"):
		return "no_irena"
	return "duo"


# --- Сохранение -----------------------------------------------------------------

func to_save() -> Dictionary:
	var d := {
		"version": SAVE_VERSION, "lang": runner.language, "story_hash": runner.story_hash,
		"hero": state.hero, "difficulty": state.difficulty, "events": events, "entry": entry, "map": map_pos,
		# Для списка сохранений, без загрузки истории.
		"scene": scene_name(), "chapter": state.chapter, "level": state.level, "darkness": darkness(),
	}
	return d.duplicate(true)


## Загрузить сохранение. Возвращает строки, показанные после последнего события в журнале
## (с начала сцены, если событий в ней ещё не было): их интерфейс показывает снова.
func load_save(d: Dictionary, lang := "") -> Array[Dictionary]:
	if lang == "":
		lang = String(d.get("lang", "ru"))
	var saved_events: Array[Dictionary] = []
	for ev in d.get("events", []):
		saved_events.append(CombatData.whole_numbers(ev))
	var e: Dictionary = d.get("entry", {})
	var saved_map: Dictionary = d.get("map", {})
	runner.load_language(lang)
	var fast: bool = not e.is_empty() and d.get("story_hash", "") == runner.story_hash and d.get("lang", "") == runner.language
	events = saved_events.duplicate()
	if fast:
		runner.load_state(String(e.ink))
		state = GameState.from_dict(e.game)
		scene_idx = int(e.scene_idx)
		flow = String(e.get("flow", ""))
		pending_battle = ""
		pending_levelup = 0
		pending_shop = ""
		if flow != "":
			runner.switch_flow(flow)
		_mark = e.duplicate()
		entry = {}
		events.resize(int(e.log_index))
		var tail_fast := _replay(saved_events, int(e.log_index))
		map_pos = saved_map
		return tail_fast
	state = GameState.new()
	state.hero = d.hero.duplicate()
	state.difficulty = String(d.get("difficulty", "story"))
	_restart(lang)
	events.clear()
	_mark_target = int(e.get("log_index", 0))
	_set_mark_if_target()
	var tail := _replay(saved_events, 0)
	map_pos = saved_map
	return tail


## Какого ответа ждёт история для события журнала.
static func _event_kind(ev: Dictionary) -> String:
	if ev.has("battle"):
		return "battle"
	if ev.has("branch"):
		return "levelup"
	if ev.has("shop"):
		return "shop"
	return "choices"


func _set_mark_if_target() -> void:
	_replaying = true
	_set_mark()
	_replaying = false


## Проиграть события начиная с from. Строки после последнего события возвращаются для показа.
func _replay(saved: Array[Dictionary], from: int) -> Array[Dictionary]:
	_replaying = true
	var tail: Array[Dictionary] = []
	var i := from
	while true:
		var item := next()
		match String(item.type):
			"line":
				if item.has("scene"):
					tail.clear()
				tail.append(item)
				continue
			"explore_end":
				continue
			"end":
				break
		if i >= saved.size():
			break
		var ev: Dictionary = saved[i]
		var fits: bool = _event_kind(ev) == ("choices" if item.type == "choices" else String(item.type))
		if not fits:
			push_error("Журнал не совпадает с историей на событии %d: %s" % [i, ev])
			break
		_apply(ev)
		tail.clear()
		i += 1
	_replaying = false
	_mark_target = -1
	return tail
