extends Control
## Конец демо (DESIGN.md, раздел 8): титр главы 1, ссылка на страницу в Steam и куда делся прогресс.
## Сюда ведёт Game.screen_path(), когда в демо история входит в главу 1.


func _ready() -> void:
	var col := UiKit.screen(self, 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := UiKit.heading(tr("CHAPTER_1").to_upper(), UiKit.HEAD_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	for key in ["DEMO_END_TEXT", "DEMO_END_SAVE"]:
		var l := UiKit.label(tr(key), UiKit.FONT_BODY)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size = Vector2(420, 0)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 8)
	col.add_child(buttons)
	if Game.steam_url() != "":
		buttons.add_child(UiKit.button(tr("DEMO_WISHLIST"), func() -> void:
			PlaytestLog.event("wishlist_click")
			OS.shell_open(Game.steam_url())))
	else:
		var soon := UiKit.label(tr("DEMO_STEAM_SOON"), UiKit.FONT_SMALL, UiKit.MUTED)
		soon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buttons.add_child(soon)
	buttons.add_child(UiKit.button(tr("STORY_TO_MENU"), func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	# Для плейтеста: какой файл прислать (docs/PLAYTEST.md).
	var log_note := UiKit.label(UiKit.fmt("DEMO_PLAYTEST_LOG", {"path": PlaytestLog.os_path()}), UiKit.FONT_SMALL, UiKit.MUTED)
	log_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(log_note)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		var open := UiKit.button(tr("DEMO_OPEN_FOLDER"), func() -> void:
			OS.shell_show_in_file_manager(PlaytestLog.os_path()), UiKit.FONT_SMALL)
		open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(open)
	Game.pending_tail = []
	Sound.for_demo_end()
	UiKit.focus_first(buttons)
