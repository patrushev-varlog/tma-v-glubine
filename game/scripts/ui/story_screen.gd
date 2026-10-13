extends Control
## Экран истории: строки Ink по одной, варианты выбора, бои по тегу # battle: (пока их проводит ИИ),
## журнал, сохранения. Работает с мышью, клавиатурой и геймпадом.

const MAX_LINES := 120

var _chapter: Label
var _lines: VBoxContainer
var _scroll: ScrollContainer
var _bottom: VBoxContainer
var _hints: Label
var _status: Label
var _overlay: Control = null


func _ready() -> void:
	var col := UiKit.screen(self, 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	_chapter = UiKit.label("", UiKit.FONT_SMALL, UiKit.ACCENT)
	_chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_chapter)
	_status = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	top.add_child(_status)
	top.add_child(UiKit.button(tr("STORY_JOURNAL"), _open_journal, UiKit.FONT_SMALL))
	top.add_child(UiKit.button(tr("STORY_MENU"), _open_menu, UiKit.FONT_SMALL))
	col.add_child(top)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(_scroll)
	_lines = VBoxContainer.new()
	_lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lines.add_theme_constant_override("separation", 10)
	_scroll.add_child(_lines)

	_bottom = VBoxContainer.new()
	_bottom.add_theme_constant_override("separation", 6)
	col.add_child(_bottom)
	_hints = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	col.add_child(_hints)
	InputSetup.device_changed.connect(func(_k: String) -> void: _refresh_hints())
	_refresh_hints()

	for item in Game.pending_tail:
		_add_line(item)
	Game.pending_tail = []
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null and is_instance_valid(_overlay):
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_menu"):
			_close_overlay()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("game_journal"):
		_open_journal()
	elif event.is_action_pressed("game_menu"):
		_open_menu()
	elif event.is_action_pressed("game_quicksave"):
		_save("quick")
	elif event.is_action_pressed("game_quickload") and SaveStore.exists("quick"):
		Game.pending_tail = Game.load_from("quick")
		get_tree().reload_current_scene()


func _refresh_hints() -> void:
	_hints.text = UiKit.fmt("STORY_HINTS", {"next": InputSetup.glyph("ui_accept"),
		"journal": InputSetup.glyph("game_journal"), "menu": InputSetup.glyph("game_menu")})
	_chapter.text = tr("CHAPTER_%d" % Game.session.state.chapter)


# --- Ход истории -------------------------------------------------------------

func _advance() -> void:
	_clear_bottom()
	var item := Game.session.next()
	match String(item.type):
		"line":
			_add_line(item)
			_bottom.add_child(UiKit.button(tr("STORY_NEXT"), _advance))
		"choices":
			for i in item.options.size():
				_bottom.add_child(UiKit.button(String(item.options[i]), _choose.bind(i)))
		"battle":
			_battle_panel(String(item.id))
		"explore_end":
			_advance()
			return
		"end":
			_bottom.add_child(UiKit.label(tr("STORY_END"), UiKit.FONT_BODY, UiKit.ACCENT))
			_bottom.add_child(UiKit.button(tr("STORY_TO_MENU"), _to_menu))
	_refresh_hints()
	UiKit.focus_first(_bottom)


func _choose(i: int) -> void:
	var text := (_bottom.get_child(i) as Button).text
	_add_text("› " + text, UiKit.HERO)
	Game.session.choose(i)
	_advance()


func _add_line(item: Dictionary) -> void:
	# Реплики в тексте уже с атрибуцией («— сказал Эйвин»), поэтому говорящего отмечаем только цветом;
	# имя над репликой появится вместе с портретами (поток H).
	var who := String(item.get("speaker", ""))
	var color := UiKit.TEXT
	if who == "hero":
		color = UiKit.HERO
	elif who != "":
		color = UiKit.SPEAKER
	_add_text(String(item.text), color)


func _add_text(text: String, color: Color) -> void:
	_lines.add_child(UiKit.label(text, UiKit.FONT_BODY, color))
	while _lines.get_child_count() > MAX_LINES:
		var old := _lines.get_child(0)
		_lines.remove_child(old)
		old.queue_free()
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _clear_bottom() -> void:
	for c in _bottom.get_children():
		_bottom.remove_child(c)
		c.queue_free()


# --- Бой (заглушка до экрана боя) -------------------------------------------

func _battle_panel(battle_id: String) -> void:
	_bottom.add_child(UiKit.label(UiKit.fmt("BATTLE_TITLE", {"id": battle_id}), UiKit.FONT_BODY, UiKit.ACCENT))
	var party := PackedStringArray([String(Game.session.state.hero.get("name", ""))])
	for c in Game.session.companions():
		party.append(tr("COMPANION_" + c))
	_bottom.add_child(UiKit.label(UiKit.fmt("BATTLE_STUB_NOTE", {"party": ", ".join(party),
		"level": Game.session.state.level}), UiKit.FONT_SMALL, UiKit.MUTED))
	_bottom.add_child(UiKit.button(tr("BATTLE_AUTO"), _fight))


func _fight() -> void:
	var r := Game.auto_battle()
	_clear_bottom()
	if r.outcome == "victory":
		_add_text(UiKit.fmt("BATTLE_WON", {"rounds": r.rounds, "dark": r.darkness}), UiKit.ACCENT)
		_bottom.add_child(UiKit.button(tr("BATTLE_CONTINUE"), func() -> void:
			Game.finish_battle(int(r.darkness))
			_advance()))
	else:
		_add_text(tr("BATTLE_LOST"), UiKit.DANGER)
		_bottom.add_child(UiKit.button(tr("BATTLE_RETRY"), _fight))
	UiKit.focus_first(_bottom)


# --- Журнал и меню -----------------------------------------------------------

func _open_journal() -> void:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var col := UiKit.overlay(_overlay)
	var s := Game.session
	col.add_child(UiKit.label(tr("JOURNAL_TITLE"), UiKit.FONT_BODY, UiKit.ACCENT))
	var party := PackedStringArray([String(s.state.hero.get("name", ""))])
	for c in s.companions():
		party.append(tr("COMPANION_" + c))
	col.add_child(UiKit.label(UiKit.fmt("JOURNAL_PARTY", {"party": ", ".join(party), "level": s.state.level,
		"silver": s.state.silver}), UiKit.FONT_SMALL))
	var items := PackedStringArray()
	for it in s.state.inventory:
		var key := "ITEM_" + String(it.id)
		items.append(tr(key) if tr(key) != key else String(it.id))
	col.add_child(UiKit.label(UiKit.fmt("JOURNAL_ITEMS", {"items": ", ".join(items)}) if not items.is_empty()
		else tr("JOURNAL_NO_ITEMS"), UiKit.FONT_SMALL))
	col.add_child(UiKit.label(tr("JOURNAL_QUESTS"), UiKit.FONT_SMALL, UiKit.MUTED))
	for q in QuestJournal.entries(s):
		var line := tr(q.title_key)
		if q.state == "done":
			line += " — " + tr("QUEST_DONE")
		elif q.has("clues"):
			line += " — " + UiKit.fmt("QUEST_CLUES", {"n": q.clues, "max": q.clues_max})
		col.add_child(UiKit.label("• " + line, UiKit.FONT_BODY, UiKit.ACCENT if q.state == "active" else UiKit.MUTED))
		for note in q.notes:
			col.add_child(UiKit.label("    " + note, UiKit.FONT_SMALL))
	col.add_child(UiKit.button(tr("STORY_CLOSE"), _close_overlay))
	UiKit.focus_first(col)


func _open_menu() -> void:
	_close_overlay()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var col := UiKit.overlay(_overlay)
	col.add_child(UiKit.label(tr("STORY_MENU"), UiKit.FONT_BODY, UiKit.ACCENT))
	col.add_child(UiKit.button(tr("STORY_QUICKSAVE"), func() -> void:
		_close_overlay()
		_save("quick")))
	col.add_child(UiKit.button(tr("STORY_SAVE"), func() -> void:
		_close_overlay()
		_overlay = SlotPanel.open(self, "save", _save)))
	col.add_child(UiKit.button(tr("STORY_TO_MENU"), _to_menu))
	col.add_child(UiKit.button(tr("STORY_CLOSE"), _close_overlay))
	UiKit.focus_first(col)


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	UiKit.focus_first(_bottom)


func _save(slot: String) -> void:
	if Game.save_to(slot) == OK:
		_status.text = UiKit.fmt("STORY_SAVED", {"slot": SlotPanel.slot_name(slot)})


func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
