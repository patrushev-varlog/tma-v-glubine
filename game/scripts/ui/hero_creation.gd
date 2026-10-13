extends Control
## Создание героя (DESIGN.md, раздел 5): класс, пол, имя героя, имя супруга из списка склоняемых имён
## или своё, сложность. Предыстории нет. Пол супруга следует из пола героя: у героя — жена, у героини — муж.

var _class := "fighter"
var _hero_f := false
var _spouse_id := ""
var _difficulty := "story"
var _name: LineEdit
var _spouse_names: OptionButton
var _spouse_own: LineEdit
var _spouse_label: Label
var _class_desc: Label
var _diff_desc: Label
var _hint: Label
var _start: Button


func _ready() -> void:
	var col := UiKit.screen(self, 10)
	col.add_child(UiKit.label(tr("CREATE_TITLE"), UiKit.FONT_TITLE, UiKit.ACCENT))

	col.add_child(UiKit.label(tr("CREATE_CLASS"), UiKit.FONT_SMALL, UiKit.MUTED))
	var classes := _choice_row(CombatData.class_ids(), func(id: String) -> String: return tr("CLASS_" + id),
		func(id: String) -> void:
			_class = id
			_refresh())
	col.add_child(classes)
	_class_desc = UiKit.label("", UiKit.FONT_SMALL)
	col.add_child(_class_desc)

	col.add_child(UiKit.label(tr("CREATE_HERO_SEX"), UiKit.FONT_SMALL, UiKit.MUTED))
	col.add_child(_choice_row(["m", "f"], func(id: String) -> String: return tr("SEX_" + id),
		func(id: String) -> void:
			_hero_f = id == "f"
			_fill_spouse_names()
			_refresh()))

	col.add_child(UiKit.label(tr("CREATE_NAME"), UiKit.FONT_SMALL, UiKit.MUTED))
	_name = LineEdit.new()
	_name.placeholder_text = tr("CREATE_NAME_PLACEHOLDER")
	_name.max_length = 24
	_name.add_theme_font_size_override("font_size", UiKit.FONT_BODY)
	_name.text_changed.connect(func(_t: String) -> void: _refresh())
	col.add_child(_name)

	_spouse_label = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	col.add_child(_spouse_label)
	var spouse_row := HBoxContainer.new()
	spouse_row.add_theme_constant_override("separation", 10)
	_spouse_names = OptionButton.new()
	_spouse_names.add_theme_font_size_override("font_size", UiKit.FONT_BODY)
	_spouse_names.item_selected.connect(func(_i: int) -> void: _refresh())
	spouse_row.add_child(_spouse_names)
	_spouse_own = LineEdit.new()
	_spouse_own.max_length = 24
	_spouse_own.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spouse_own.add_theme_font_size_override("font_size", UiKit.FONT_BODY)
	_spouse_own.text_changed.connect(func(_t: String) -> void: _refresh())
	spouse_row.add_child(_spouse_own)
	col.add_child(spouse_row)

	col.add_child(UiKit.label(tr("CREATE_DIFFICULTY"), UiKit.FONT_SMALL, UiKit.MUTED))
	col.add_child(_choice_row(["story", "trial"], func(id: String) -> String: return tr("DIFF_" + id),
		func(id: String) -> void:
			_difficulty = id
			_refresh()))
	_diff_desc = UiKit.label("", UiKit.FONT_SMALL)
	col.add_child(_diff_desc)

	_hint = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	col.add_child(_hint)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	bottom.add_child(UiKit.button(tr("MENU_BACK"), func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	_start = UiKit.button(tr("CREATE_START"), _begin)
	bottom.add_child(_start)
	col.add_child(bottom)

	_fill_spouse_names()
	_refresh()
	UiKit.focus_first(classes)


## Ряд взаимоисключающих кнопок; первая нажата.
func _choice_row(ids: Array, caption: Callable, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var group := ButtonGroup.new()
	for id in ids:
		var b := UiKit.button(caption.call(id))
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size.x = 160
		var sel := StyleBoxFlat.new()
		sel.bg_color = UiKit.PANEL
		sel.set_border_width_all(2)
		sel.border_color = UiKit.ACCENT
		sel.set_corner_radius_all(3)
		b.add_theme_stylebox_override("pressed", sel)
		b.add_theme_color_override("font_pressed_color", UiKit.ACCENT)
		b.pressed.connect(func() -> void: on_pick.call(String(id)))
		row.add_child(b)
	(row.get_child(0) as Button).button_pressed = true
	return row


func _fill_spouse_names() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(StorySession.SPOUSE_PATH))
	_spouse_names.clear()
	# У героя — жена, у героини — муж.
	for n in data["m" if _hero_f else "f"]:
		var forms = n.get(Game.story_language(), n.ru)
		_spouse_names.add_item(forms.nom if forms is Dictionary else String(forms))
		_spouse_names.set_item_metadata(_spouse_names.item_count - 1, String(n.id))
	_spouse_names.add_item(tr("CREATE_SPOUSE_OWN"))
	_spouse_names.set_item_metadata(_spouse_names.item_count - 1, "")
	_spouse_names.select(0)


func _refresh() -> void:
	_class_desc.text = tr("CLASS_%s_DESC" % _class)
	_diff_desc.text = tr("DIFF_%s_DESC" % _difficulty)
	_spouse_label.text = tr("CREATE_SPOUSE_HUSBAND" if _hero_f else "CREATE_SPOUSE_WIFE")
	_spouse_id = String(_spouse_names.get_item_metadata(_spouse_names.selected))
	_spouse_own.visible = _spouse_id == ""
	_hint.text = tr("CREATE_SPOUSE_OWN_NOTE") if _spouse_id == "" else ""
	_start.disabled = setup().is_empty()
	if _start.disabled:
		_hint.text = tr("CREATE_NEED_NAME")


## Выбор игрока для Game.new_game или {} — если не хватает имени.
func setup() -> Dictionary:
	var hero_name := _name.text.strip_edges()
	var spouse := _spouse_names.get_item_text(_spouse_names.selected) if _spouse_id != "" else _spouse_own.text.strip_edges()
	if hero_name == "" or spouse == "":
		return {}
	return {"difficulty": _difficulty, "hero": {"class": _class, "hero_f": _hero_f, "name": hero_name,
		"spouse_f": not _hero_f, "spouse_id": _spouse_id, "spouse_name": spouse,
		"archetype": String(CombatData.archetypes_of(_class)[0])}}


func _begin() -> void:
	var s := setup()
	if s.is_empty():
		return
	Game.new_game(s)
	Game.pending_tail = []
	get_tree().change_scene_to_file(Game.screen_path())
