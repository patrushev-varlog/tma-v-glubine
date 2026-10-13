extends Node
## Автозагрузка Game: настройки, текущее прохождение (StorySession) и сохранения.
## Экраны говорят с игрой через неё; правила боя и сюжета — в классах scripts/combat и scripts/state.

signal language_changed(lang: String)

const SETTINGS_PATH := "user://settings.cfg"

var language := "ru"
## Экран боя: действие по второму клику на ту же клетку (первый — прогноз). На тач-экране так всегда.
var battle_double_click := false
var session: StorySession = null
## Строки, которые экран истории покажет первыми после загрузки (см. StorySession.load_save).
var pending_tail: Array[Dictionary] = []
## Бой, который сейчас идёт (экран боя — поток I; пока бой проводит ИИ, см. auto_battle).
var battle: Battle = null


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		language = String(cfg.get_value("game", "language", _default_language()))
		battle_double_click = bool(cfg.get_value("battle", "double_click", false))
	else:
		language = _default_language()
	TranslationServer.set_locale(language)
	get_tree().root.theme = UiKit.theme()


static func _default_language() -> String:
	return "ru" if OS.get_locale_language() == "ru" else "en"


## Язык интерфейса и истории. История на английском есть, только когда story/ink-en/game.ink готов;
## до тех пор английский — только интерфейс, а сюжет идёт по-русски.
func set_language(lang: String) -> Array[Dictionary]:
	language = lang
	TranslationServer.set_locale(lang)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("game", "language", lang)
	cfg.save(SETTINGS_PATH)
	var tail: Array[Dictionary] = []
	if session != null and story_language() != session.runner.language:
		tail = session.load_save(session.to_save(), story_language())
	language_changed.emit(lang)
	return tail


func set_battle_double_click(on: bool) -> void:
	battle_double_click = on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("battle", "double_click", on)
	cfg.save(SETTINGS_PATH)


func story_language() -> String:
	return language if StoryRunner.languages().has(language) else "ru"


# --- Прохождение ----------------------------------------------------------------

## setup: {"hero": {...}, "difficulty": "story" | "trial"} с экрана создания героя.
func new_game(setup: Dictionary) -> void:
	_set_session(StorySession.new())
	session.new_game(setup, story_language())


func _set_session(s: StorySession) -> void:
	session = s
	session.scene_entered.connect(_on_scene_entered)


func _on_scene_entered(_scene: String) -> void:
	autosave()


func autosave() -> void:
	if session != null:
		SaveStore.write("auto", session.to_save())


func save_to(slot: String) -> Error:
	return SaveStore.write(slot, session.to_save())


## Экран для текущего места истории: карта локации, если сцена идёт на карте, иначе экран истории.
## Туда же возвращается экран боя после победы.
func screen_path() -> String:
	if session != null and LocationMap.for_scene(session.scene_name()) != "":
		return "res://scenes/location_screen.tscn"
	return "res://scenes/story_screen.tscn"


func can_continue() -> bool:
	return SaveStore.latest() != ""


## Загрузить слот. Возвращает строки, которые были на экране (с начала сцены или после последнего выбора).
func load_from(slot: String) -> Array[Dictionary]:
	var d := SaveStore.read(slot)
	if d.is_empty():
		return []
	_set_session(StorySession.new())
	return session.load_save(d, story_language())


# --- Бой --------------------------------------------------------------------------

const BATTLE_SCENE := "res://scenes/battle_screen.tscn"

## Куда вернуться после боя: start_battle ставит сюда экран текущей сцены (screen_path).
var battle_return_scene := "res://scenes/story_screen.tscn"


## Бой по тегу # battle:<id>: свой бой из data/combat/battles.json (бои пролога), иначе — тестовый бой
## уровня отряда, пока у глав нет своих карт. Ветка героя — первая из классов, пока нет экрана повышения уровня.
func battle_scenario(battle_id: String) -> Dictionary:
	var st := session.state
	var bid := battle_id if CombatData.table("battles").has(battle_id) else "level_%d" % clampi(st.level, 1, 5)
	var sc := CombatData.scenario(bid, String(st.hero.get("class", "fighter")), String(st.hero.get("archetype", "")),
		session.party_key(), st.difficulty, "kit", session.flags())
	sc["combat_darkness"] = st.combat_darkness
	var hero_name := String(st.hero.get("name", ""))
	if hero_name != "":
		var h: Combatant = sc.units[0]
		h.name = hero_name
		h.letter = hero_name.left(1)
	return sc


func dark_gifts_open() -> bool:
	return session.state.unlocks.has("dark_gifts")


## Начать бой, которого ждёт история. Экран боя (scenes/battle_screen.tscn) берёт его из Game.battle.
func start_battle(seed_value := -1) -> Battle:
	battle = Battle.new()
	battle.setup(battle_scenario(session.pending_battle), seed_value, session.state.difficulty)
	battle_return_scene = screen_path()
	return battle


## Провести бой силами ИИ (самопроверка и отладка). Возвращает {"outcome", "darkness", "rounds", "log"}.
func auto_battle(seed_value := -1) -> Dictionary:
	start_battle(seed_value)
	var guard := 0
	while battle.outcome == "" and guard < 3000:
		CombatAI.take_turn(battle, battle.current(), dark_gifts_open())
		battle.end_turn()
		guard += 1
	var out := {"outcome": battle.outcome if battle.outcome != "" else "timeout", "darkness": battle.darkness,
		"rounds": battle.round_num, "log": battle.log_lines.duplicate()}
	return out


## Победа в бою: история продолжается, бой засчитан, боевая Тьма уходит в шкалу.
func finish_battle(darkness: int) -> void:
	session.win_battle(darkness)
	battle = null
	SaveStore.remove("battle")


## Бой в процессе — для продолжения после выхода (DESIGN.md, «Режимы сложности»): пишется в начале
## каждого хода героя и удаляется после боя. Вручную не загружается.
func save_battle() -> void:
	if battle != null:
		SaveStore.write("battle", {"story": session.to_save(), "battle": battle.to_dict(),
			"return_scene": battle_return_scene})


## Есть ли бой, прерванный выходом из игры, и он свежее сюжетных сохранений.
func can_resume_battle() -> bool:
	var d := SaveStore.read("battle")
	if d.is_empty():
		return false
	var latest := SaveStore.latest()
	return latest == "" or float(d.get("time", 0)) >= float(SaveStore.read(latest).get("time", 0))


## Вернуться в прерванный бой: история загружается как была, бой — с начала хода.
func resume_battle() -> bool:
	var d := SaveStore.read("battle")
	if d.is_empty():
		return false
	_set_session(StorySession.new())
	pending_tail = session.load_save(d.story, story_language())
	battle = Battle.from_dict(d.battle)
	battle_return_scene = String(d.get("return_scene", battle_return_scene))
	return true


## Бросить бой (поражение на «Испытании», выход в меню): боевое сохранение больше не нужно.
func abandon_battle() -> void:
	battle = null
	SaveStore.remove("battle")
