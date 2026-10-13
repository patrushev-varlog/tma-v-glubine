extends Node
## Автозагрузка Game: настройки, текущее прохождение (StorySession) и сохранения.
## Экраны говорят с игрой через неё; правила боя и сюжета — в классах scripts/combat и scripts/state.

signal language_changed(lang: String)

const SETTINGS_PATH := "user://settings.cfg"

var language := "ru"
var session: StorySession = null
## Строки, которые экран истории покажет первыми после загрузки (см. StorySession.load_save).
var pending_tail: Array[Dictionary] = []
## Бой, который сейчас идёт (экран боя — поток I; пока бой проводит ИИ, см. auto_battle).
var battle: Battle = null


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		language = String(cfg.get_value("game", "language", _default_language()))
	else:
		language = _default_language()
	TranslationServer.set_locale(language)
	# Набор шрифтов: FONT_SET из окружения (снимки для сравнения) или [ui] font_set в settings.cfg.
	UiKit.font_set = OS.get_environment("FONT_SET")
	if UiKit.font_set == "":
		UiKit.font_set = String(cfg.get_value("ui", "font_set", UiKit.DEFAULT_FONT_SET))
	if not UiKit.FONT_SETS.has(UiKit.font_set):
		UiKit.font_set = UiKit.DEFAULT_FONT_SET
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

## Бой по тегу # battle:<id>. Пока сюжетных карт боёв нет (поток G), берётся тестовый бой уровня отряда
## из data/combat/battles.json. Ветка героя — первая из классов, пока нет экрана повышения уровня.
func battle_scenario(battle_id: String) -> Dictionary:
	var st := session.state
	var bid := battle_id if CombatData.table("battles").has(battle_id) else "level_%d" % clampi(st.level, 1, 5)
	var sc := CombatData.scenario(bid, String(st.hero.get("class", "fighter")), String(st.hero.get("archetype", "")),
		session.party_key(), st.difficulty)
	sc["combat_darkness"] = st.combat_darkness
	return sc


func dark_gifts_open() -> bool:
	return session.state.unlocks.has("dark_gifts")


## Провести бой силами ИИ (заглушка до экрана боя). Возвращает {"outcome", "darkness", "rounds", "log"}.
func auto_battle(seed_value := -1) -> Dictionary:
	battle = Battle.new()
	battle.setup(battle_scenario(session.pending_battle), seed_value, session.state.difficulty)
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


## Бой в процессе — для продолжения после выхода (DESIGN.md, «Режимы сложности»).
func save_battle() -> void:
	if battle != null:
		SaveStore.write("battle", {"story": session.to_save(), "battle": battle.to_dict()})
