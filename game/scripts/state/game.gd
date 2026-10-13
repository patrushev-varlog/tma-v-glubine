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
	# Тесты, самопроверка и инструменты (godot -s …) не пишут в журнал плейтеста.
	if OS.get_cmdline_args().has("-s") or OS.get_cmdline_user_args().has("--selftest"):
		PlaytestLog.enabled = false
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		PlaytestLog.event("quit", _where())
		get_tree().quit()


## Где игрок сейчас — для журнала плейтеста.
func _where() -> Dictionary:
	if session == null:
		return {"scene": ""}
	return {"scene": session.scene_name(), "battle": battle.id if battle != null else "", "darkness": session.darkness()}


# --- Демо -------------------------------------------------------------------------

## Демо (DESIGN.md, раздел 8): пролог целиком, в конце титр главы 1 и ссылка на страницу в Steam.
## Сборки демо — пресеты «… Demo» в export_presets.cfg (свой признак "demo"); из редактора — «-- --demo».
const DEMO_END_SCENE := "res://scenes/demo_end.tscn"


## Включить демо без сборки демо (тесты).
var demo_forced := false


func is_demo() -> bool:
	return demo_forced or OS.has_feature("demo") or OS.get_cmdline_user_args().has("--demo")


## Демо закончилось: история вошла в первую сцену главы 1. Автосохранение на входе в эту сцену уже
## записано, с него полная игра продолжит (формат сохранений у демо и игры один).
func demo_over() -> bool:
	return is_demo() and session != null and session.chapter_name() != "prologue"


## Страница игры в Steam (настройка tma/steam_url в project.godot). Пусто, пока нет приложения в Steamworks.
static func steam_url() -> String:
	return String(ProjectSettings.get_setting("tma/steam_url", ""))


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
	PlaytestLog.event("new_game", {"class": String(setup.hero.get("class", "")), "hero_f": bool(setup.hero.get("hero_f", false)),
		"difficulty": String(setup.get("difficulty", "story"))})


func _set_session(s: StorySession) -> void:
	session = s
	session.scene_entered.connect(_on_scene_entered)


func _on_scene_entered(scene: String) -> void:
	autosave()
	PlaytestLog.event("scene", {"scene": scene, "darkness": session.darkness()})
	if demo_over():
		PlaytestLog.event("demo_end", {"darkness": session.darkness(), "choice": String(session.flag("column_choice"))})


func autosave() -> void:
	if session != null:
		SaveStore.write("auto", session.to_save())


func save_to(slot: String) -> Error:
	return SaveStore.write(slot, session.to_save())


## Экран для текущего места истории: карта локации, если сцена идёт на карте, иначе экран истории.
## Туда же возвращается экран боя после победы.
func screen_path() -> String:
	if demo_over():
		return DEMO_END_SCENE
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
	var tail := session.load_save(d, story_language())
	PlaytestLog.event("load", {"slot": slot, "scene": session.scene_name()})
	return tail


# --- Бой --------------------------------------------------------------------------

const BATTLE_SCENE := "res://scenes/battle_screen.tscn"

## Куда вернуться после боя: start_battle ставит сюда экран текущей сцены (screen_path).
var battle_return_scene := "res://scenes/story_screen.tscn"


## Бой по тегу # battle:<id>: свой бой из data/combat/battles.json (бои пролога), иначе — тестовый бой
## уровня отряда, пока у главы нет своих карт. Ветка героя — выбранная в лагере (экран уровня).
## Экипировка — гарантированный набор уровня, вещи отряда из инвентаря встают поверх, если не хуже.
func battle_scenario(battle_id: String) -> Dictionary:
	var st := session.state
	var bid := battle_id if CombatData.table("battles").has(battle_id) else "level_%d" % clampi(st.level, 1, 5)
	var owned := {}
	for it in st.inventory:
		owned.get_or_add(String(it.owner), []).append(String(it.id))
	var sc := CombatData.scenario(bid, String(st.hero.get("class", "fighter")), st.hero_branch(),
		session.party_key(), st.difficulty, "kit", session.flags(), owned)
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
	PlaytestLog.event("battle_start", {"battle": battle.id, "difficulty": battle.difficulty})
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
	if battle != null:
		PlaytestLog.event("battle_won", {"battle": battle.id, "rounds": battle.round_num, "darkness": darkness,
			"rescued": bool(battle.stage.get("rescued", false))})
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
