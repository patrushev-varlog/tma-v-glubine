extends Control
## Экран среза: диалог Ink (сцена 1 пролога), кусок поля с якорями графики и портрет по Тьме.
## Всё управляется мышью, клавиатурой и геймпадом; вёрстка тянется от 1280×720 до 1280×800 (Steam Deck)
## и выше. Язык RU/EN меняется посреди сцены без потери выборов.

const FONT_BODY := 22
const FONT_SMALL := 17
const DEFAULT_NAMES := {"ru": "Эйла", "en": "Eila"}
const HERO := {"hero_class": "wizard", "hero_f": false, "spouse_f": true}

var story := StoryRunner.new()
var lang := "ru"

var _info: Label
var _title: Label
var board: IsoBoard
var portrait: DarkPortrait
var _stage_label: Label
var _art_label: Label
var _portrait_note: Label
var _hints: Label
var _speaker: Label
var _text: Label
var _choices: VBoxContainer
var _continue: Button
var _pending: Array[Dictionary] = []


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		_selftest()
		return
	TranslationServer.set_locale(lang)
	_build_ui()
	InputSetup.device_changed.connect(func(_k): _refresh_static())
	get_viewport().size_changed.connect(_refresh_static)
	start_scene()


# --- Вёрстка -----------------------------------------------------------------

func _label(size: int, color := Color("#c7dcd0")) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("#2e222f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var top := HBoxContainer.new()
	_title = _label(FONT_SMALL, Color("#f9c22b"))
	_info = _label(FONT_SMALL, Color("#9babb2"))
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_title)
	top.add_child(_info)
	col.add_child(top)

	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 16)
	col.add_child(middle)

	board = IsoBoard.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_child(board)

	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 6)
	middle.add_child(side)
	portrait = DarkPortrait.new()
	side.add_child(portrait)
	_stage_label = _label(FONT_SMALL)
	_portrait_note = _label(FONT_SMALL - 2, Color("#7f708a"))
	_art_label = _label(FONT_SMALL - 2, Color("#9babb2"))
	_art_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hints = _label(FONT_SMALL - 2, Color("#9babb2"))
	for n in [_stage_label, _portrait_note, _art_label, _hints]:
		side.add_child(n)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#3e3546")
	sb.border_color = Color("#694f62")
	sb.set_border_width_all(2)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size.y = 200
	col.add_child(panel)
	var dlg := VBoxContainer.new()
	dlg.add_theme_constant_override("separation", 6)
	panel.add_child(dlg)
	_speaker = _label(FONT_SMALL, Color("#f9c22b"))
	_text = _label(FONT_BODY)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 4)
	_continue = _button("")
	_continue.pressed.connect(_advance)
	for n in [_speaker, _text, _choices, _continue]:
		dlg.add_child(n)


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", FONT_BODY - 2)
	b.focus_mode = Control.FOCUS_ALL
	return b


func _refresh_static() -> void:
	var vs := get_viewport_rect().size
	_title.text = tr("TITLE")
	_info.text = tr("INFO").format({
		"backend": StoryRunner.backend_name(), "lang": lang.to_upper(),
		"device": tr("DEVICE_" + InputSetup.device), "w": int(vs.x), "h": int(vs.y)})
	_stage_label.text = tr("STAGE").format({"name": tr(portrait.stage_name())})
	_portrait_note.text = tr("PORTRAIT_NOTE")
	_art_label.custom_minimum_size.x = portrait.custom_minimum_size.x
	_art_label.text = tr(board.art_name())
	_hints.text = "\n".join([
		tr("HINT_MOVE").format({"move": InputSetup.glyph("move"), "key": InputSetup.glyph("ui_accept")}),
		"%s · %s" % [tr("HINT_FOCUS").format({"key": InputSetup.glyph("slice_focus")}),
			tr("HINT_LANG").format({"key": InputSetup.glyph("slice_language")})],
		"%s · %s" % [tr("HINT_ART").format({"key": InputSetup.glyph("slice_art")}),
			tr("HINT_DARK").format({"a": InputSetup.glyph("slice_dark_down"), "b": InputSetup.glyph("slice_dark_up")})],
	])
	_continue.text = tr("CONTINUE").format({"key": InputSetup.glyph("ui_accept")})


# --- Диалог ------------------------------------------------------------------

func _setup() -> Dictionary:
	var s := HERO.duplicate()
	s["spouse_name"] = DEFAULT_NAMES[lang]
	return s


func start_scene() -> void:
	story.start_language(lang, _setup())
	_pending.clear()
	_refresh_static()
	_advance()


## Показать следующую строку, или выборы, или конец сцены.
func _advance() -> void:
	if _pending.is_empty() and story.can_continue():
		_pending.append(story.next_line())
	if not _pending.is_empty():
		_show_line(_pending.pop_front())
		var more := not _pending.is_empty() or story.can_continue()
		if more:
			_set_choices([])
			_continue.visible = true
			_continue.grab_focus()
			return
	_continue.visible = false
	var ch := story.choices()
	if ch.is_empty():
		_set_choices([tr("RESTART")], true)
	else:
		_set_choices(Array(ch))


func _show_line(line: Dictionary) -> void:
	var tags: PackedStringArray = line["tags"]
	var who := ""
	for t in tags:
		if t == "spk:spouse":
			who = story.get_var("spouse_name")
		elif t == "spk:hero":
			who = tr("SPEAKER_HERO")
	_speaker.text = who
	_speaker.visible = who != ""
	_text.text = String(line["text"]).strip_edges()


func _set_choices(items: Array, restart := false) -> void:
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	for i in items.size():
		var b := _button("%d. %s" % [i + 1, items[i]] if not restart else items[i])
		if restart:
			b.pressed.connect(start_scene)
		else:
			b.pressed.connect(_choose.bind(i))
		_choices.add_child(b)
	if items.size() > 0:
		(_choices.get_child(0) as Button).grab_focus()


func _choose(i: int) -> void:
	story.choose(i)
	_advance()


func set_language(l: String) -> void:
	if l == lang:
		return
	var log := story.save_log()
	# Имя по умолчанию переводим; имя, введённое игроком, осталось бы как есть.
	if log["setup"].get("spouse_name") == DEFAULT_NAMES[lang]:
		log["setup"]["spouse_name"] = DEFAULT_NAMES[l]
	lang = l
	TranslationServer.set_locale(lang)
	var tail := story.replay(lang, log)
	_refresh_static()
	# Показываем последнюю строку перед текущим местом: остальное уже прочитано на другом языке.
	_pending.clear()
	if not tail.is_empty():
		_pending.append(tail.back())
	_advance()


# --- Общие кнопки --------------------------------------------------------------

func _dialogue_has_focus() -> bool:
	var f := get_viewport().gui_get_focus_owner()
	return f != null and f != board


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("slice_language"):
		set_language("en" if lang == "ru" else "ru")
	elif event.is_action_pressed("slice_art"):
		board.next_art()
		_refresh_static()
	elif event.is_action_pressed("slice_dark_up"):
		portrait.set_stage(portrait.stage + 1)
		_refresh_static()
	elif event.is_action_pressed("slice_dark_down"):
		portrait.set_stage(portrait.stage - 1)
		_refresh_static()
	elif event.is_action_pressed("ui_cancel") and board.has_focus():
		_toggle_focus()
	elif event.is_action_pressed("slice_restart"):
		start_scene()
	else:
		return
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Tab и View переключают фокус раньше, чем кнопки съедят событие.
	if event.is_action_pressed("slice_focus"):
		_toggle_focus()
		get_viewport().set_input_as_handled()


func _toggle_focus() -> void:
	if _dialogue_has_focus():
		board.grab_focus()
	elif _continue.visible:
		_continue.grab_focus()
	elif _choices.get_child_count() > 0:
		(_choices.get_child(0) as Button).grab_focus()
	board.queue_redraw()


# --- Самопроверка собранной игры: TmaStackSlice -- --selftest ---------------------

## Проигрывает всю историю (пролог — эпилог) из JSON внутри сборки и выходит с кодом 0/1.
## Так экспорт на каждой платформе проверяется без рук: рантайм Ink, C# и файлы истории на месте.
func _selftest() -> void:
	var t0 := Time.get_ticks_msec()
	var json := FileAccess.get_file_as_string("res://story/game.ru.json")
	var t := InkTranscript.run(json, {"cls": "wizard", "hero_f": true, "spouse_f": false}, 1, ["darkness"], "Mara")
	var ok: bool = t["lines"] > 500 and String(t["text"]).contains("ending:")
	print("selftest %s: %s, %d строк, %d выборов, %d мс, OS %s" % [
		"OK" if ok else "FAIL", StoryRunner.backend_name(), t["lines"], t["picks"], Time.get_ticks_msec() - t0, OS.get_name()])
	get_tree().quit(0 if ok else 1)
