class_name StoryRunner
extends RefCounted
## Обёртка над рантаймом Ink. Игра на GDScript говорит только с ней, поэтому рантайм
## меняется в одном файле: сейчас GodotInk (C#, .NET), запасной — inkgd (чистый GDScript,
## см. fallback-inkgd/scripts/story_runner.gd с тем же набором методов).
##
## История — JSON, собранный tools/ink_tool.mjs из story/ink (русский) или story/ink-en
## (английский). У обоих языков одинаковая логика, поэтому сохранение — это журнал выборов
## от начала сцены, и его можно проиграть в другом языке (см. switch_language()).

const STORIES := {
	"ru": "res://story/slice.ru.json",
	"en": "res://story/slice.en.json",
}

# preload, а не глобальное имя класса: в свежем клоне кэш глобальных классов собирается
# до сборки C#, и имя InkLoader ещё неизвестно GDScript (так падала сборка в CI).
const InkLoaderScript := preload("res://scripts/story/InkLoader.cs")

var language := "ru"
var _story  # GodotInk.InkStory
var _json_path := ""
var _setup := {}
var _picks: Array[int] = []


static func backend_name() -> String:
	return "GodotInk (C#, ink-engine-runtime 1.2)"


func load_json_text(json: String) -> void:
	_story = InkLoaderScript.new().Load(json)


## Начать историю из файла с заданными переменными героя.
func start(json_path: String, setup: Dictionary) -> void:
	_json_path = json_path
	_setup = setup.duplicate()
	_picks.clear()
	load_json_text(FileAccess.get_file_as_string(json_path))
	for key in setup:
		set_var(key, setup[key])


func start_language(lang: String, setup: Dictionary) -> void:
	language = lang
	start(STORIES[lang], setup)


func can_continue() -> bool:
	return _story.GetCanContinue()


## Следующая строка: {"text": String, "tags": PackedStringArray}.
func next_line() -> Dictionary:
	var text: String = _story.Continue()
	var tags := PackedStringArray(_story.GetCurrentTags())
	return {"text": text, "tags": tags}


func choices() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _story.GetCurrentChoices():
		out.append(c.GetText())
	return out


func choose(index: int) -> void:
	_picks.append(index)
	_story.ChooseChoiceIndex(index)


func get_var(name: String) -> Variant:
	return _story.FetchVariable(name)


func set_var(name: String, value: Variant) -> void:
	_story.StoreVariable(name, value)


## Родное сохранение Ink (точное, но привязано к версии JSON и языку).
func save_state() -> String:
	return _story.SaveState()


func load_state(state_json: String) -> void:
	_story.LoadState(state_json)


## Переносимое сохранение: начальные переменные и журнал выборов.
func save_log() -> Dictionary:
	return {"setup": _setup.duplicate(), "picks": _picks.duplicate()}


## Проиграть журнал выборов заново. Возвращает строки, которые прозвучали после последнего выбора
## (их показываем на экране), и оставляет историю в том же месте.
func replay(lang: String, log: Dictionary) -> Array[Dictionary]:
	start_language(lang, log["setup"])
	var tail: Array[Dictionary] = []
	for pick in log["picks"]:
		tail.clear()
		while can_continue():
			tail.append(next_line())
		choose(pick)
	tail.clear()
	while can_continue():
		tail.append(next_line())
	return tail


## Сменить язык посреди сцены: тот же журнал выборов в другом JSON.
func switch_language(lang: String) -> Array[Dictionary]:
	return replay(lang, save_log())
