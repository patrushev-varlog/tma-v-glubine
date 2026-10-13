extends Control
## Главное меню: продолжить, новая игра, загрузка, язык, выход.
## С ключом «-- --selftest» вместо меню прогоняет самопроверку сборки (scripts/ui/selftest.gd).

var _col: VBoxContainer


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		var code := SelfTest.run()
		get_tree().quit(code)
		return
	_build()
	Game.language_changed.connect(func(_l: String) -> void: _rebuild())


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	var col := UiKit.screen(self, 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := UiKit.heading(tr("GAME_TITLE").to_upper(), UiKit.HEAD_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiKit.label(tr("GAME_SUBTITLE"), UiKit.FONT_SMALL, UiKit.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(360, 0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 8)
	col.add_child(buttons)
	if Game.can_resume_battle():
		buttons.add_child(UiKit.button(tr("MENU_CONTINUE"), _resume_battle))
	elif Game.can_continue():
		buttons.add_child(UiKit.button(tr("MENU_CONTINUE"), func() -> void: _load(SaveStore.latest())))
	buttons.add_child(UiKit.button(tr("MENU_NEW"), func() -> void:
		get_tree().change_scene_to_file("res://scenes/hero_creation.tscn")))
	if Game.can_continue():
		buttons.add_child(UiKit.button(tr("MENU_LOAD"), func() -> void: SlotPanel.open(self, "load", _load)))
	var lang_name := tr("LANG_" + Game.language)
	buttons.add_child(UiKit.button(UiKit.fmt("MENU_LANGUAGE", {"lang": lang_name}), _toggle_language))
	if Game.story_language() != Game.language:
		var note := UiKit.label(tr("LANG_STORY_RU_ONLY"), UiKit.FONT_SMALL, UiKit.MUTED)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(note)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		buttons.add_child(UiKit.button(tr("MENU_QUIT"), func() -> void: get_tree().quit()))
	UiKit.focus_first(buttons)


func _toggle_language() -> void:
	Game.set_language("en" if Game.language == "ru" else "ru")


## Бой, прерванный выходом: вернуться в него с начала хода.
func _resume_battle() -> void:
	if Game.resume_battle():
		get_tree().change_scene_to_file(Game.BATTLE_SCENE)


func _load(slot: String) -> void:
	Game.abandon_battle()
	Game.pending_tail = Game.load_from(slot)
	get_tree().change_scene_to_file(Game.screen_path())
