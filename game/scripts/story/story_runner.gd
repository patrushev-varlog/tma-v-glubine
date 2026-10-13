class_name StoryRunner
extends RefCounted
## Обёртка над рантаймом Ink. Игра говорит с Ink только через неё, поэтому рантайм меняется
## в одном файле: сейчас GodotInk (C#, .NET), запасной — inkgd (prototypes/stack-slice/fallback-inkgd).
##
## История — JSON, собранный tools/ink_tool.mjs из story/ink (русский) или story/ink-en (английский).
## Журнал выборов, сохранения и сцены — в StorySession; здесь только доступ к рантайму.

const STORIES := {
	"ru": "res://story/game.ru.json",
	"en": "res://story/game.en.json",
}

# preload, а не глобальное имя класса: в свежем клоне кэш глобальных классов собирается
# до сборки C#, и имя InkLoader ещё неизвестно GDScript (так падала сборка среза в CI).
const InkLoaderScript := preload("res://scripts/story/InkLoader.cs")

var language := "ru"
## Хэш JSON истории: сохранение с другим хэшем загружается проигрыванием журнала, а не родным состоянием Ink.
var story_hash := ""
var _story  # GodotInk.InkStory
var _vars: PackedStringArray = []


## Языки, для которых есть полная история. Английская появится, когда story/ink-en/game.ink будет готов.
static func languages() -> PackedStringArray:
	var out := PackedStringArray()
	for lang in STORIES:
		if FileAccess.file_exists(STORIES[lang]):
			out.append(lang)
	return out


static func backend_name() -> String:
	return "GodotInk (C#, ink-engine-runtime 1.2)"


func load_language(lang: String) -> void:
	language = lang if FileAccess.file_exists(STORIES.get(lang, "")) else "ru"
	load_json_text(FileAccess.get_file_as_string(STORIES[language]))


func load_json_text(json: String) -> void:
	story_hash = json.md5_text()
	_story = InkLoaderScript.new().Load(json)
	# Объявления переменных в JSON Ink: {"VAR=":"имя"}.
	_vars.clear()
	var re := RegEx.create_from_string("\\{\"VAR=\":\"(\\w+)\"")
	for m in re.search_all(json):
		_vars.append(m.get_string(1))


func can_continue() -> bool:
	return _story.GetCanContinue()


## Следующая строка: {"text": String, "tags": PackedStringArray}.
func next_line() -> Dictionary:
	var text: String = _story.Continue()
	return {"text": text.strip_edges(false, true), "tags": PackedStringArray(_story.GetCurrentTags())}


func choices() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _story.GetCurrentChoices():
		out.append(c.GetText())
	return out


## Теги вариантов выбора: по PackedStringArray на вариант (тег #obj: — объект на карте).
func choice_tags() -> Array[PackedStringArray]:
	var out: Array[PackedStringArray] = []
	for tags in _story.ChoiceTags():
		out.append(PackedStringArray(tags))
	return out


func choose(index: int) -> void:
	_story.ChooseChoiceIndex(index)


func go_to(path: String, args: Array = []) -> void:
	_story.GoTo(path, args)


func switch_flow(flow: String) -> void:
	_story.SwitchFlow(flow)


func default_flow() -> void:
	_story.SwitchToDefaultFlow()


## Путь, где стоит история («evening.0.12»); первая часть — узел сцены.
func current_path() -> String:
	return _story.CurrentPath()


func has_var(name: String) -> bool:
	return _vars.has(name)


func var_names() -> PackedStringArray:
	return _vars


func get_var(name: String) -> Variant:
	return _story.FetchVariable(name)


func set_var(name: String, value: Variant) -> void:
	_story.StoreVariable(name, value)


## Родное сохранение Ink (точное, но привязано к JSON конкретного языка и версии).
func save_state() -> String:
	return _story.SaveState()


func load_state(state_json: String) -> void:
	_story.LoadState(state_json)
