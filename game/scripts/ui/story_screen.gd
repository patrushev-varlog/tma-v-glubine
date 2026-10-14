extends Control
## Экран истории: строки Ink по одной, варианты выбора, переход в бой по тегу # battle: (экран боя),
## журнал, сохранения. Работает с мышью, клавиатурой и геймпадом.

const MAX_LINES := 120

var _chapter: Label
var _lines: VBoxContainer
var _scroll: ScrollContainer
var _bottom: VBoxContainer
var _hints: Label
var _status: Label
var _overlay: Control = null
## Портрет говорящего слева от текста и имя под ним.
var _face_box: VBoxContainer
var _face_holder: Control
var _face_name: Label
var _face_id := ""


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

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	col.add_child(mid)
	_face_box = VBoxContainer.new()
	_face_box.add_theme_constant_override("separation", 6)
	_face_holder = Control.new()
	_face_holder.custom_minimum_size = Vector2(256, 256)
	_face_box.add_child(_face_holder)
	_face_name = UiKit.heading("", UiKit.HEAD_SMALL, UiKit.SPEAKER)
	_face_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_face_name.custom_minimum_size = Vector2(256, 0)
	_face_box.add_child(_face_name)
	mid.add_child(_face_box)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid.add_child(_scroll)
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

	_show_face("hero", "")
	Sound.for_scene(Game.session.scene_name())
	for item in Game.pending_tail:
		_add_line(item)
	Game.pending_tail = []
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if _camp != null:
		return
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
		get_tree().change_scene_to_file(Game.screen_path())


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
			if item.has("scene") and Game.screen_path() != scene_file_path:
				# Сцена идёт на карте (строку покажет экран локации) или демо кончилось (экран конца демо).
				Game.pending_tail = [item]
				get_tree().change_scene_to_file(Game.screen_path())
				return
			if item.has("scene"):
				Sound.for_scene(String(item.scene))
			_add_line(item)
			_bottom.add_child(UiKit.button(tr("STORY_NEXT"), _advance, UiKit.FONT_BODY, "page_turn"))
		"choices":
			for i in item.options.size():
				_bottom.add_child(UiKit.button(String(item.options[i]), _choose.bind(i)))
		"battle":
			_battle_panel(String(item.id))
		"levelup":
			_camp_panel(CampPanels.levelup(self, int(item.level), func(branch: String) -> void:
				Game.session.choose_branch(branch)
				_camp_done()))
			return
		"shop":
			_camp_panel(CampPanels.shop(self, String(item.id), func(buy: Array, forge: Array) -> void:
				Game.session.leave_shop(buy, forge)
				_camp_done()))
			return
		"explore_end":
			_advance()
			return
		"end":
			_bottom.add_child(UiKit.label(Game.end_text(), UiKit.FONT_BODY, UiKit.ACCENT))
			_bottom.add_child(UiKit.button(tr("STORY_TO_MENU"), _to_menu))
	_refresh_hints()
	UiKit.focus_first(_bottom)


func _choose(i: int) -> void:
	var text := (_bottom.get_child(i) as Button).text
	_add_text("› " + text, UiKit.HERO)
	Game.session.choose(i)
	_advance()


func _add_line(item: Dictionary) -> void:
	Sound.sfx(String(item.get("sfx", "")))
	# Реплики в тексте уже с атрибуцией («— сказал Эйвин»), поэтому говорящего отмечаем цветом,
	# портретом и именем слева; на строках рассказчика портрет последнего говорящего гаснет.
	var who := String(item.get("speaker", ""))
	var color := UiKit.TEXT
	if who == "hero":
		color = UiKit.HERO
	elif who != "":
		color = UiKit.SPEAKER
	if who != "":
		_show_face(who, String(item.get("mood", "")))
	else:
		_face_box.modulate = Color(1, 1, 1, 0.45)
	for t in item.get("tags", PackedStringArray()):
		if String(t).begins_with("chapter:"):
			# Титр новой главы — крупно, по центру.
			var title := UiKit.heading(String(item.text).to_upper(), UiKit.HEAD_TITLE)
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_lines.add_child(title)
			_chapter.text = tr("CHAPTER_%d" % Game.session.state.chapter)
			return
	_add_text(String(item.text), color)


func _show_face(who: String, mood: String) -> void:
	var hero: Dictionary = Game.session.state.hero
	var id := Portraits.id_for(who, mood, hero)
	var dark := Game.session.darkness()
	var key := "%s/%d" % [id, Portraits.dark_stage(dark)]
	if key != _face_id:
		_face_id = key
		for c in _face_holder.get_children():
			c.queue_free()
		_face_holder.add_child(Portraits.view(id, 128, 2, dark))
	_face_name.text = Portraits.speaker_name(who, hero, String(Game.session.flag("spouse_name")))
	_face_box.modulate = Color.WHITE


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


# --- Лагерь -----------------------------------------------------------------

## Рамка лагеря (уровень, торговец) не закрывается Esc: история ждёт ответа. Ответ закрывает её сам.
var _camp: Control = null


func _camp_panel(panel: Control) -> void:
	_camp = panel
	panel.tree_exiting.connect(func() -> void: _camp = null)


func _camp_done() -> void:
	if _camp != null and is_instance_valid(_camp):
		_camp.queue_free()
	_camp = null
	_advance()


# --- Бой --------------------------------------------------------------------

func _battle_panel(battle_id: String) -> void:
	_bottom.add_child(UiKit.label(tr("BATTLE_AHEAD"), UiKit.FONT_BODY, UiKit.ACCENT))
	var party := PackedStringArray([String(Game.session.state.hero.get("name", ""))])
	for u in Game.battle_scenario(battle_id).units:
		if u.team == 0 and not u.is_hero:
			party.append(u.name)
	_bottom.add_child(UiKit.label(UiKit.fmt("BATTLE_PARTY", {"party": ", ".join(party)}), UiKit.FONT_SMALL, UiKit.MUTED))
	_bottom.add_child(UiKit.button(tr("BATTLE_START"), _fight))


func _fight() -> void:
	Game.start_battle()
	get_tree().change_scene_to_file(Game.BATTLE_SCENE)


# --- Журнал и меню -----------------------------------------------------------

func _open_journal() -> void:
	_close_overlay()
	_overlay = GameMenus.journal(self, _close_overlay)


func _open_menu() -> void:
	_close_overlay()
	_overlay = GameMenus.pause_menu(self, {
		"quicksave": func() -> void:
			_close_overlay()
			_save("quick"),
		"save": func() -> void:
			_close_overlay()
			_overlay = SlotPanel.open(self, "save", _save),
		"to_menu": _to_menu,
		"close": _close_overlay,
	})


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	UiKit.focus_first(_bottom)


func _save(slot: String) -> void:
	if Game.save_to(slot) == OK:
		Sound.sfx("save")
		_status.text = UiKit.fmt("STORY_SAVED", {"slot": SlotPanel.slot_name(slot)})


func _to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

