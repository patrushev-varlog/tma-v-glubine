extends Node
## Экран локации (поток G): сцена истории идёт на изометрической карте. Строки Ink — в панели
## диалога внизу, выбор с тегом #obj:<id> — объект на карте: герой подходит к нему и осматривает.
## Пока на карте ждут только объекты, игрок свободно ходит: клик или тап по клетке, WASD и стрелки,
## стик или крестовина геймпада; осмотр — клик по объекту, Enter или A рядом с ним.
## Бой по тегу # battle: — переход на экран боя и после победы обратно на карту.
## Какие сцены идут на картах — data/locations/index.json; формат карт — docs/LOCATIONS.md.

const FADE_TIME := 0.35
const ZOOM := 2.0

var _map: LocationMap
var _view: LocationView
var _camera: Camera2D
var _scene := ""

var _ui: Control
var _chapter: Label
var _status: Label
var _goals: VBoxContainer
var _prompt: Label
var _panel: PanelContainer
var _speaker: Label
var _prev: Label
var _text: Label
var _buttons: VBoxContainer
var _hints: Label
var _fade: ColorRect
var _overlay: Control = null

## "line" | "choices" | "roam" | "battle" | "end" | "leaving"
var _mode := ""
## Объекты, которые сейчас можно осмотреть: id → индекс варианта выбора.
var _choice_obj := {}
var _choice_text := {}
## Объект, к которому герой идёт по клику: осмотреть по приходу.
var _target_obj := ""
var _last_line := ""
var _visible_ids: Array = []
## Смена экрана (тесты подменяют, чтобы не уходить со сцены GUT).
var change_screen := func(path: String) -> void: get_tree().change_scene_to_file(path)


func _ready() -> void:
	RenderingServer.set_default_clear_color(UiKit.BG)
	var s := Game.session
	_scene = s.scene_name()
	var loc := LocationMap.for_scene(_scene)
	_map = LocationMap.load_location(loc)
	_map.setup_scene(_scene, _check)
	_visible_ids = _object_ids()
	var start := _map.spawn_of(_scene)
	if String(s.map_pos.get("location", "")) == loc:
		var saved := Vector2i(int(s.map_pos.x), int(s.map_pos.y))
		if _map.walkable(saved):
			start = saved

	_view = LocationView.new()
	add_child(_view)
	_view.build(_map, start, _hero_look())
	_attach_hero()

	_build_ui()
	InputSetup.device_changed.connect(func(_k: String) -> void: _refresh_hints())
	_refresh_hints()

	var tail: Array[Dictionary] = Game.pending_tail.duplicate()
	Game.pending_tail = []
	if not tail.is_empty() and String(tail[-1].type) == "line":
		if tail.size() > 1:
			_last_line = String(tail[-2].get("text", ""))
		_show_line(tail[-1])
	else:
		_advance()
	_fade.color.a = 1.0
	create_tween().tween_property(_fade, "color:a", 0.0, FADE_TIME)


## Условия видимости объектов: "имя" — переменная Ink истинна, "won:<бой>" — бой выигран, "!" — не.
func _check(cond: String) -> bool:
	var neg := cond.begins_with("!")
	var c := cond.substr(1) if neg else cond
	var v: bool
	if c.begins_with("won:"):
		v = Game.session.state.battles.has(c.substr(4))
	else:
		v = LocationMap.truthy(Game.session.flag(c))
	return v != neg


func _object_ids() -> Array:
	return _map.objects.map(func(o: Dictionary) -> String: return String(o.id))


## Цвет тела героя-заглушки по классу (как в прототипе боя).
func _hero_look() -> Dictionary:
	var body := {"fighter": "#b33831", "rogue": "#4f6e3f", "cleric": "#e6d6b8", "wizard": "#4d65b4"}
	return {"body": body.get(String(Game.session.state.hero.get("class", "")), "#7aa7e8"), "head": "#f5c8a0"}


func _attach_hero() -> void:
	_camera = Camera2D.new()
	_camera.zoom = Vector2(ZOOM, ZOOM)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	_camera.offset = Vector2(0, 40)
	var b := _view.bounds()
	_camera.limit_left = int(b.position.x)
	_camera.limit_top = int(b.position.y)
	_camera.limit_right = int(b.end.x)
	_camera.limit_bottom = int(b.end.y) + 120
	_view.hero.add_child(_camera)
	_camera.make_current()
	_view.hero.stepped.connect(_on_step)
	_view.hero.arrived.connect(_on_arrived)


# --- Интерфейс ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	# Тема окна не доходит до интерфейса внутри CanvasLayer: ставим её сюда же.
	_ui.theme = get_tree().root.theme
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	var margin := UiKit.margins(18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	_chapter = UiKit.heading("", UiKit.HEAD_SMALL)
	_chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_chapter)
	_status = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	top.add_child(_status)
	top.add_child(UiKit.button(tr("STORY_JOURNAL"), _open_journal, UiKit.FONT_SMALL))
	top.add_child(UiKit.button(tr("STORY_MENU"), _open_menu, UiKit.FONT_SMALL))
	col.add_child(top)

	_goals = VBoxContainer.new()
	_goals.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_goals)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)

	_prompt = UiKit.heading("", UiKit.HEAD_BODY, UiKit.TEXT)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_prompt)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiKit.BG, 0.92)
	sb.border_color = UiKit.PANEL.lightened(0.15)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", sb)
	col.add_child(_panel)
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 6)
	_panel.add_child(pcol)
	_speaker = UiKit.heading("", UiKit.HEAD_SMALL)
	pcol.add_child(_speaker)
	_prev = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	pcol.add_child(_prev)
	_text = UiKit.label("", UiKit.FONT_BODY)
	pcol.add_child(_text)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 4)
	pcol.add_child(_buttons)

	_hints = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	col.add_child(_hints)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fade)


func _refresh_hints() -> void:
	var move := tr("LOC_MOVE_KEYS") if InputSetup.device == "keyboard" else tr("LOC_MOVE_PAD")
	_hints.text = UiKit.fmt("LOC_HINTS", {"move": move, "act": InputSetup.glyph("ui_accept"),
		"journal": InputSetup.glyph("game_journal"), "menu": InputSetup.glyph("game_menu")})
	_chapter.text = tr("CHAPTER_%d" % Game.session.state.chapter).to_upper()
	_update_prompt()


func _clear_buttons() -> void:
	for c in _buttons.get_children():
		_buttons.remove_child(c)
		c.queue_free()


func _speaker_name(spk: String) -> String:
	match spk:
		"":
			return ""
		"hero":
			return String(Game.session.state.hero.get("name", ""))
		"spouse":
			return String(Game.session.flag("spouse_name"))
	var key := "SPEAKER_" + spk
	return tr(key) if tr(key) != key else ""


# --- Ход истории -------------------------------------------------------------------

func _advance() -> void:
	if _mode == "leaving":
		return
	_refresh_objects()
	var item := Game.session.next()
	match String(item.type):
		"line":
			if item.has("scene") and String(item.scene) != _scene:
				_leave([item])
				return
			_show_line(item)
		"choices":
			_show_choices(item)
		"battle":
			_show_battle(String(item.id))
		"explore_end":
			_advance()
		"end":
			_mode = "end"
			_set_active({})
			_speaker.text = ""
			_text.text = tr("STORY_END")
			_clear_buttons()
			_buttons.add_child(UiKit.button(tr("STORY_TO_MENU"), _to_menu))
			_panel.show()
			UiKit.focus_first(_buttons)


func _show_line(item: Dictionary) -> void:
	_mode = "line"
	_set_active({})
	var who := String(item.get("speaker", ""))
	_speaker.text = _speaker_name(who).to_upper()
	_speaker.visible = _speaker.text != ""
	_prev.text = _last_line
	_prev.visible = _last_line != ""
	_text.text = String(item.text)
	_text.add_theme_color_override("font_color", UiKit.HERO if who == "hero" else (UiKit.SPEAKER if who != "" else UiKit.TEXT))
	_last_line = String(item.text)
	_clear_buttons()
	_buttons.add_child(UiKit.button(tr("STORY_NEXT"), _advance))
	_panel.show()
	UiKit.focus_first(_buttons)


func _show_choices(item: Dictionary) -> void:
	var objects: Array = item.get("objects", [])
	var on_map := {}
	var texts := {}
	var plain := false
	for i in item.options.size():
		var obj := String(objects[i]) if i < objects.size() else ""
		if obj != "" and not _map.object(obj).is_empty():
			on_map[obj] = i
			texts[obj] = String(item.options[i])
		else:
			plain = true
	if plain or on_map.is_empty():
		# Обычный выбор (или смешанный — тогда все варианты кнопками): ходить по карте нельзя.
		_mode = "choices"
		_set_active({})
		_clear_buttons()
		for i in item.options.size():
			_buttons.add_child(UiKit.button(String(item.options[i]), _choose.bind(i)))
		_speaker.hide()
		_prev.hide()
		_text.text = _last_line
		_panel.show()
		UiKit.focus_first(_buttons)
		return
	_mode = "roam"
	_choice_obj = on_map
	_choice_text = texts
	_set_active(texts)
	_panel.hide()
	get_viewport().gui_release_focus()
	_update_prompt()


func _choose(i: int) -> void:
	var text := (_buttons.get_child(i) as Button).text
	_last_line = "› " + text
	Game.session.choose(i)
	_advance()


## Осмотреть объект: выбрать вариант истории, привязанный к нему.
func _interact(obj_id: String) -> void:
	if _mode != "roam" or not _choice_obj.has(obj_id):
		return
	_view.hero.stop()
	_target_obj = ""
	_last_line = "› " + String(_choice_text[obj_id])
	var i := int(_choice_obj[obj_id])
	_set_active({})
	Game.session.choose(i)
	_advance()


func _set_active(texts: Dictionary) -> void:
	if texts.is_empty():
		_choice_obj = {}
		_choice_text = {}
		_view.path_preview.clear()
	_view.set_active(texts)
	for c in _goals.get_children():
		c.queue_free()
	if not texts.is_empty():
		_goals.add_child(UiKit.heading(tr("LOC_GOALS"), UiKit.HEAD_SMALL, UiKit.MUTED))
		for id in texts:
			_goals.add_child(UiKit.label("• " + String(texts[id]), UiKit.FONT_SMALL, UiKit.ACCENT))
	_update_prompt()


## Видимость объектов зависит от истории (могилы после похорон, мертвецы до боя): пересобрать вид,
## если набор поменялся.
func _refresh_objects() -> void:
	_map.setup_scene(_scene, _check)
	var ids := _object_ids()
	if ids == _visible_ids:
		return
	_visible_ids = ids
	var at := _view.hero.cell
	_view.build(_map, at, _hero_look())
	_attach_hero()
	_camera.reset_smoothing()


func _leave(tail: Array[Dictionary]) -> void:
	_mode = "leaving"
	Game.pending_tail = tail
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	tw.tween_callback(func() -> void: change_screen.call(Game.screen_path()))


# --- Движение ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null and is_instance_valid(_overlay):
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_menu"):
			_close_overlay()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("game_journal"):
		_open_journal()
		return
	if event.is_action_pressed("game_menu"):
		_open_menu()
		return
	if event.is_action_pressed("game_quicksave"):
		_save("quick")
		return
	if event.is_action_pressed("game_quickload") and SaveStore.exists("quick"):
		Game.pending_tail = Game.load_from("quick")
		change_screen.call(Game.screen_path())
		return
	if _mode != "roam":
		return
	if event is InputEventMouseMotion:
		_hover(_view.cell_at(_view.get_global_mouse_position()))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(_view.cell_at(_view.get_global_mouse_position()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		var near := _reachable_active()
		if near != "":
			_interact(near)
		get_viewport().set_input_as_handled()


func _hover(c: Vector2i) -> void:
	_view.hover_cell = c
	var obj := _map.object_at(c)
	if not obj.is_empty() and _choice_obj.has(obj.id):
		_view.path_preview = _map.path_to_object(_view.hero.cell, obj).path
	elif _map.walkable(c):
		_view.path_preview = _map.path(_view.hero.cell, c)
	else:
		_view.path_preview.clear()


## Клик или тап: по объекту для осмотра — подойти и осмотреть, по клетке — идти туда.
func _click(c: Vector2i) -> void:
	var obj := _map.object_at(c)
	if not obj.is_empty() and _choice_obj.has(obj.id):
		var r := _map.path_to_object(_view.hero.cell, obj)
		if not r.ok:
			return
		if r.path.is_empty():
			_interact(obj.id)
			return
		_target_obj = obj.id
		_view.hero.walk(r.path)
		return
	_target_obj = ""
	if _map.walkable(c):
		var p := _map.path(_view.hero.cell, c)
		if not p.is_empty():
			_view.hero.walk(p)


## Клавиатура и геймпад: шаг на соседнюю клетку в сторону, куда наклонён стик (в экранных
## координатах, поэтому «вверх» на стике — вверх по экрану, а не вдоль оси карты).
func _process(_delta: float) -> void:
	if _mode != "roam" or (_overlay != null and is_instance_valid(_overlay)):
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir.length() < 0.5 or _view.hero.is_moving():
		return
	_target_obj = ""
	var from := _view.hero.cell
	var best := from
	var best_dot := 0.5
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var n: Vector2i = from + Vector2i(dx, dy)
			if n == from or _map.path(from, n).size() != 1:
				continue
			var dot := (_view.cell_center(n) - _view.cell_center(from)).normalized().dot(dir.normalized())
			if dot > best_dot:
				best_dot = dot
				best = n
	if best != from:
		_view.hero.walk([best] as Array[Vector2i])


func _on_step(c: Vector2i) -> void:
	Game.session.map_pos = {"location": _map.id, "x": c.x, "y": c.y}
	_update_prompt()


func _on_arrived(_c: Vector2i) -> void:
	if _target_obj != "":
		var id := _target_obj
		_target_obj = ""
		if _map.can_reach_from(_map.object(id), _view.hero.cell):
			_interact(id)
	_update_prompt()


## Ближайший объект для осмотра, до которого герой уже дотянется, или "".
func _reachable_active() -> String:
	for id in _choice_obj:
		if _map.can_reach_from(_map.object(id), _view.hero.cell):
			return String(id)
	return ""


func _update_prompt() -> void:
	if _prompt == null:
		return
	var id := _reachable_active() if _mode == "roam" else ""
	_prompt.text = UiKit.fmt("LOC_PROMPT", {"key": InputSetup.glyph("ui_accept"), "action": _choice_text[id]}) if id != "" else ""


# --- Бой --------------------------------------------------------------------------------

func _show_battle(_battle_id: String) -> void:
	_mode = "battle"
	_set_active({})
	_speaker.hide()
	_prev.text = _last_line
	_prev.visible = _last_line != ""
	_text.text = tr("BATTLE_AHEAD")
	_clear_buttons()
	_buttons.add_child(UiKit.button(tr("LOC_BATTLE_BEGIN"), _start_battle))
	_panel.show()
	UiKit.focus_first(_buttons)


## Переход на экран боя: затемнение и смена сцены. Экран боя после победы вызывает
## Game.finish_battle и возвращается на Game.screen_path() — сюда же, история идёт дальше на карте.
func _start_battle() -> void:
	_mode = "leaving"
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, FADE_TIME)
	tw.tween_callback(func() -> void:
		Game.start_battle()
		change_screen.call(Game.BATTLE_SCENE))


# --- Журнал, меню, сохранения -------------------------------------------------------

func _open_journal() -> void:
	_close_overlay()
	_overlay = GameMenus.journal(_ui, _close_overlay)


func _open_menu() -> void:
	_close_overlay()
	_overlay = GameMenus.pause_menu(_ui, {
		"quicksave": func() -> void:
			_close_overlay()
			_save("quick"),
		"save": func() -> void:
			_close_overlay()
			_overlay = SlotPanel.open(_ui, "save", _save),
		"to_menu": _to_menu,
		"close": _close_overlay,
	})


func _close_overlay() -> void:
	if _overlay != null and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	if _panel.visible:
		UiKit.focus_first(_buttons)


func _save(slot: String) -> void:
	if Game.save_to(slot) == OK:
		_status.text = UiKit.fmt("STORY_SAVED", {"slot": SlotPanel.slot_name(slot)})


func _to_menu() -> void:
	change_screen.call("res://scenes/main_menu.tscn")
