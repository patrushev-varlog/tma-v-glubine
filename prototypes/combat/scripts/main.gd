extends Node2D
## Серый прототип боя: управление, камера, интерфейс.
## Первый тап или клик по клетке показывает прогноз, повторный по той же клетке выполняет действие.

const SAVE_TURN := "user://battle_turn.json"
const TAP_SLOP := 12.0
const ZOOM_MIN := 0.6
const ZOOM_MAX := 2.6

var battle: Battle
var board: BoardView
var cam: Camera2D

var hero_class := "fighter"
var level := 1
var archetype := ""
var with_velior := true
var difficulty := "story"

## Пауза между шагами врагов, сек.
var enemy_step := 0.45
var mode := ""
var busy := false
var press_pos := Vector2.ZERO
var dragging := false
var touches := {}
var pinch_dist := 0.0

var hud: CanvasLayer
var round_label: Label
var turn_label: Label
var dark_label: Label
var portraits: VBoxContainer
var log_box: RichTextLabel
var preview_label: Label
var buttons_box: HBoxContainer
var overlay: CanvasLayer
var log_shown := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1d1f24"))
	board = BoardView.new()
	add_child(board)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_build_hud()
	_show_menu()


# --- Меню и запуск ---------------------------------------------------------

func _show_menu() -> void:
	_clear_overlay()
	overlay = CanvasLayer.new()
	overlay.layer = 10
	add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_label("Тьма в глубине — серый прототип боя", 24))
	box.add_child(_label("Пять боёв, по одному на уровень отряда 1–5. Герой, Ирена и Гаррет против врагов своего уровня.", 15, 520))

	var cls := OptionButton.new()
	for id in Content.HERO_CLASSES:
		cls.add_item(Content.HERO_CLASSES[id].name)
		cls.set_item_metadata(cls.item_count - 1, id)
	cls.select(Content.HERO_CLASSES.keys().find(hero_class))
	box.add_child(_row("Класс героя", cls))

	var lvl := OptionButton.new()
	for lv in range(1, Content.MAX_LEVEL + 1):
		lvl.add_item("%d — %s" % [lv, Content.BATTLES[lv].title])
	lvl.select(level - 1)
	box.add_child(_row("Уровень и бой", lvl))

	var arch := OptionButton.new()
	box.add_child(_row("Ветка класса", arch))
	var arch_desc := _label("", 13, 520)
	box.add_child(arch_desc)
	var fill_arch := func() -> void:
		arch.clear()
		var ids := Content.archetypes_of(hero_class)
		if not ids.has(archetype):
			archetype = ids[0]
		for id in ids:
			arch.add_item(Content.HERO_CLASSES[hero_class].archetypes[id].name)
			arch.set_item_metadata(arch.item_count - 1, id)
		arch.select(ids.find(archetype))
		arch.disabled = level < 2
		var info: Dictionary = Content.HERO_CLASSES[hero_class].archetypes[archetype]
		arch_desc.text = "Ветка выбирается со 2 уровня." if level < 2 else "%s %s" % [info.desc, _arch_path(hero_class, archetype)]
	fill_arch.call()
	cls.item_selected.connect(func(i: int) -> void:
		hero_class = cls.get_item_metadata(i)
		fill_arch.call())
	lvl.item_selected.connect(func(i: int) -> void:
		level = i + 1
		fill_arch.call())
	arch.item_selected.connect(func(i: int) -> void:
		archetype = arch.get_item_metadata(i)
		fill_arch.call())

	var diff := OptionButton.new()
	diff.add_item("История")
	diff.add_item("Испытание")
	diff.select(0 if difficulty == "story" else 1)
	diff.item_selected.connect(func(i: int) -> void: difficulty = "story" if i == 0 else "trial")
	box.add_child(_row("Сложность", diff))

	var vel := CheckBox.new()
	vel.text = "Добавить Велиора (бой вчетвером)"
	vel.button_pressed = with_velior
	vel.toggled.connect(func(on: bool) -> void: with_velior = on)
	box.add_child(vel)

	var gear := OptionButton.new()
	gear.add_item("Без экипировки")
	gear.add_item("Гарантированный набор уровня")
	gear.add_item("Набор и всё, что можно найти")
	gear.select(["none", "kit", "full"].find(Items.mode))
	gear.item_selected.connect(func(i: int) -> void: Items.mode = ["none", "kit", "full"][i])
	box.add_child(_row("Экипировка", gear))

	var start := _button("Начать бой", func() -> void: _start_new())
	box.add_child(start)
	var cont := _button("Продолжить с начала последнего хода", func() -> void: _load_turn())
	cont.disabled = not FileAccess.file_exists(SAVE_TURN)
	box.add_child(cont)
	box.add_child(_label("Управление: тап или клик по клетке — прогноз, повторный тап — действие. Колесо или щипок — масштаб, перетаскивание — камера.", 13, 520))


func _start_new() -> void:
	battle = Battle.new()
	battle.setup(Content.scenario(level, hero_class, archetype, "full" if with_velior else "no_velior", difficulty), -1, difficulty)
	_begin()


func _load_turn() -> void:
	var b := Battle.load_from(SAVE_TURN)
	if b == null:
		return
	battle = b
	battle.log_line("Загружено начало хода.")
	_begin()


func _begin() -> void:
	_clear_overlay()
	log_shown = 0
	log_box.clear()
	board.battle = battle
	_fit_camera()
	_advance()


## Показывает всё поле между панелями: портреты слева, журнал справа, кнопки снизу.
func _fit_camera() -> void:
	var free := _free_rect()
	var w := (battle.width + battle.height) * BoardView.HALF_W
	var h := (battle.width + battle.height) * BoardView.HALF_H + 60.0
	var z := clampf(minf(free.size.x / w, free.size.y / h), ZOOM_MIN, 1.0)
	cam.zoom = Vector2(z, z)
	var center := Vector2((battle.width - battle.height) * BoardView.HALF_W * 0.5,
		(battle.width + battle.height - 2) * BoardView.HALF_H * 0.5 - 30.0)
	cam.position = _cam_pos_for(center)


## «Ур. 2 — Всплеск действий, ур. 3 — Защитник, …» для описания ветки в меню.
func _arch_path(cls: String, arch: String) -> String:
	var parts := []
	var levels: Dictionary = Content.HERO_CLASSES[cls].archetypes[arch].levels
	for lv in levels:
		var gain: String = levels[lv]
		var info: Dictionary = Content.TRAITS[gain] if Content.TRAITS.has(gain) else Content.ABILITIES[gain]
		parts.append("%d — %s" % [lv, info.name])
	return "Уровни: " + ", ".join(parts) + "."


func _clear_overlay() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null


# --- Ход за ходом --------------------------------------------------------

## Проигрывает ходы врагов, пока не наступит ход героя или конец боя.
func _advance() -> void:
	busy = true
	_refresh()
	while battle.outcome == "" and battle.current().team == 1:
		var e := battle.current()
		_focus(e.cell)
		_refresh()
		await get_tree().create_timer(enemy_step).timeout
		CombatAI.take_turn(battle, e)
		_refresh()
		await get_tree().create_timer(enemy_step).timeout
		battle.end_turn()
	busy = false
	if battle.outcome != "":
		_refresh()
		_show_result()
		return
	battle.save_to(SAVE_TURN)
	mode = ""
	_focus(battle.current().cell)
	_refresh()


func _end_turn() -> void:
	if busy or battle == null or battle.outcome != "":
		return
	battle.end_turn()
	_advance()


func _after_action() -> void:
	mode = ""
	_refresh()
	if battle.outcome != "":
		_show_result()


func _show_result() -> void:
	_clear_overlay()
	overlay = CanvasLayer.new()
	overlay.layer = 10
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var won := battle.outcome == "victory"
	box.add_child(_label("Победа" if won else "Поражение", 28))
	var down := 0
	for h in battle.heroes():
		if not h.conscious():
			down += 1
	box.add_child(_label("Раундов: %d. Выбыло героев: %d. Тьма за бой: +%d." % [battle.round_num, down, battle.darkness_gained + battle.item_darkness], 16, 420))
	if not won and battle.difficulty == "story":
		box.add_child(_button("Переиграть с начала хода", func() -> void: _load_turn()))
	box.add_child(_button("Новый бой", func() -> void: _show_menu()))


# --- Ввод ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if overlay != null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touches[event.index] = event.position
		else:
			touches.erase(event.index)
		pinch_dist = 0.0
	elif event is InputEventScreenDrag:
		touches[event.index] = event.position
		if touches.size() >= 2:
			var pts: Array = touches.values()
			var dd: float = (pts[0] as Vector2).distance_to(pts[1])
			if pinch_dist > 0.0:
				_zoom_by(dd / pinch_dist)
			pinch_dist = dd
			dragging = true
	elif event is InputEventMagnifyGesture:
		_zoom_by(event.factor)
	elif event is InputEventPanGesture:
		cam.position += event.delta * 8.0 / cam.zoom.x
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.0 / 1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_pos = event.position
				dragging = false
			elif not dragging and touches.size() < 2:
				_tap(BoardView.world_to_cell(board.get_global_mouse_position()))
	elif event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			if touches.size() >= 2:
				return
			if not dragging and event.position.distance_to(press_pos) > TAP_SLOP:
				dragging = true
			if dragging or not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
				cam.position -= event.relative / cam.zoom.x


func _zoom_by(f: float) -> void:
	var z := clampf(cam.zoom.x * f, ZOOM_MIN, ZOOM_MAX)
	cam.zoom = Vector2(z, z)


func _focus(c: Vector2i) -> void:
	var tw := create_tween()
	tw.tween_property(cam, "position", _cam_pos_for(BoardView.cell_to_world(c)), 0.25)


## Позиция камеры, при которой точка поля оказывается в середине свободной от панелей области.
func _cam_pos_for(world: Vector2) -> Vector2:
	var view := get_viewport_rect().size
	return world - (_free_rect().get_center() - view * 0.5) / cam.zoom.x


func _free_rect() -> Rect2:
	var view := get_viewport_rect().size
	return Rect2(Vector2(230, 50), view - Vector2(230 + 300, 50 + 170))


## Тап по клетке поля в ход героя.
func _tap(c: Vector2i) -> void:
	if busy or battle == null or battle.outcome != "" or not battle.in_bounds(c):
		return
	var u := battle.current()
	if u.team != 0:
		return
	var confirm := board.pending_cell == c
	board.path.clear()
	board.area_cells.clear()
	if mode != "":
		_tap_ability(u, c, confirm)
	else:
		_tap_default(u, c, confirm)


func _tap_default(u: Combatant, c: Vector2i, confirm: bool) -> void:
	var o := battle.occupant(c)
	var reach := battle.reachable(u)
	if o != null and o.team != u.team and o.conscious():
		if u.action_used:
			_set_preview("Действие на этот ход уже потрачено.", c)
			return
		if battle.in_weapon_range(u, o):
			if confirm:
				battle.attack(u, o)
				_after_action()
			else:
				var p := battle.attack_preview(u, o)
				_set_preview("Атака: %s → %s. Шанс %d%%, урон %d–%d.%s" % [u.weapon.name, o.name,
					roundi(p.chance * 100), p.min, p.max, _adv_text(p.adv)], c)
			return
		if not u.is_ranged():
			var spot := _approach_cell(u, o, reach)
			if spot.x >= 0:
				var path := battle.path_to(u, spot, reach)
				if confirm:
					battle.move_along(u, path)
					if battle.can_attack(u, o):
						battle.attack(u, o)
					_after_action()
				else:
					var p2 := battle.attack_preview(u, o)
					var oa := battle.count_opportunity(u, path)
					board.path = path
					_set_preview("Подойти и атаковать %s. Шанс %d%%, урон %d–%d.%s" % [o.name,
						roundi(p2.chance * 100), p2.min, p2.max, _oa_text(oa)], c)
				return
		_set_preview("Не достать: %s слишком далеко." % o.name, c)
		return
	if o == null and reach.has(c) and c != u.cell:
		var path2 := battle.path_to(u, c, reach)
		if confirm:
			battle.move_along(u, path2)
			_after_action()
		else:
			board.path = path2
			_set_preview("Пройти %d кл.%s" % [path2.size(), _oa_text(battle.count_opportunity(u, path2))], c)
		return
	if o != null:
		_set_preview("%s: %d/%d хитов, КД %d." % [o.name, o.hp, o.max_hp, o.total_ac()], Vector2i(-1, -1))
		return
	_set_preview("Сюда не дойти.", Vector2i(-1, -1))


## Ближайшая достижимая клетка рядом с целью для ближней атаки.
func _approach_cell(u: Combatant, target: Combatant, reach: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_cost := 1_000_000
	for c in reach:
		if c is String:
			continue
		if Battle.dist(c, target.cell) <= u.reach() and int(reach[c].cost) < best_cost:
			best_cost = int(reach[c].cost)
			best = c
	return best


func _tap_ability(u: Combatant, c: Vector2i, confirm: bool) -> void:
	if not battle.ability_targets(u, mode).has(c):
		_set_preview("Здесь нельзя: выбери подсвеченную клетку.", Vector2i(-1, -1))
		return
	if confirm:
		battle.use_ability(u, mode, c)
		_after_action()
		return
	board.area_cells = battle.ability_area(u, mode, c)
	_set_preview(battle.ability_preview(u, mode, c), c)


func _select_mode(aid: String) -> void:
	if busy or battle == null:
		return
	var u := battle.current()
	if aid == "" or mode == aid:
		mode = ""
		_refresh()
		return
	var a := battle.ability(aid)
	if a.target == "self":
		# Способности на себя: первое нажатие — прогноз, второе — применить.
		mode = aid
		_refresh()
		board.area_cells = battle.ability_area(u, aid, u.cell)
		_set_preview(battle.ability_preview(u, aid, u.cell) + " Тапни героя ещё раз, чтобы применить.", u.cell)
		return
	mode = aid
	_refresh()
	_set_preview("%s: %s Выбери цель." % [a.name, a.desc], Vector2i(-1, -1))


func _set_preview(text: String, pending: Vector2i) -> void:
	preview_label.text = text
	board.pending_cell = pending
	board.queue_redraw()


func _adv_text(adv: int) -> String:
	if adv > 0:
		return " Преимущество."
	if adv < 0:
		return " Помеха."
	return ""


func _oa_text(n: int) -> String:
	return "" if n == 0 else " Спровоцирует атак при возможности: %d." % n


# --- Интерфейс -----------------------------------------------------------

func _refresh() -> void:
	if battle == null:
		return
	for ev in battle.take_events():
		var target := battle.get_unit(ev.unit)
		if target == null:
			continue
		match String(ev.type):
			"damage":
				board.popup(target.cell, "-%d" % ev.amount, Color("#ff6b5a"))
			"heal":
				board.popup(target.cell, "+%d" % ev.amount, Color("#6bff8a"))
			"miss":
				board.popup(target.cell, "промах", Color("#cccccc"))
	while log_shown < battle.log_lines.size():
		log_box.append_text(battle.log_lines[log_shown] + "\n")
		log_shown += 1
	var u := battle.current()
	round_label.text = "Раунд %d" % battle.round_num
	turn_label.text = "Ход: %s" % u.name
	dark_label.text = "Тьма (видна только в прототипе): %d · %s" % [battle.darkness, Battle.darkness_level(battle.darkness)]
	_refresh_portraits()
	_refresh_buttons(u)
	board.clear_marks()
	preview_label.text = ""
	if busy or u.team != 0 or battle.outcome != "":
		return
	if mode == "":
		for c in battle.reachable(u):
			if c is Vector2i and c != u.cell:
				board.reach_cells.append(c)
		if not u.action_used:
			for f in battle.foes_of(u):
				if battle.in_weapon_range(u, f):
					board.target_cells.append(f.cell)
		board.target_is_ally = false
		preview_label.text = "Двигайся (%d кл.)%s. Тап — прогноз, второй тап — действие." % [u.speed_left,
			"" if u.action_used else ", атакуй или выбери способность"]
	else:
		var a := battle.ability(mode)
		if a.target == "cell" or a.target == "empty_cell":
			# Зона по клетке: дальность — мягкой подсветкой, сама зона — под тапом.
			board.reach_cells = battle.ability_targets(u, mode)
		else:
			board.target_cells = battle.ability_targets(u, mode)
			board.target_is_ally = a.target == "ally" or a.target == "self"
	board.queue_redraw()


func _refresh_portraits() -> void:
	for ch in portraits.get_children():
		ch.queue_free()
	for h in battle.heroes():
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(216, 0)
		var box := VBoxContainer.new()
		panel.add_child(box)
		var active := battle.outcome == "" and battle.current() == h
		var name_l := _label(("▶ " if active else "") + h.name + (" — выбыл" if h.down else ""), 15, 200)
		box.add_child(name_l)
		var bar := ProgressBar.new()
		bar.max_value = h.max_hp
		bar.value = h.hp
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		var fill := StyleBoxFlat.new()
		var frac := float(h.hp) / h.max_hp
		fill.bg_color = Color("#5fcf6b") if frac > 0.5 else (Color("#e0b44a") if frac > 0.25 else Color("#e05a4a"))
		bar.add_theme_stylebox_override("fill", fill)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.5)
		bar.add_theme_stylebox_override("background", bg)
		box.add_child(bar)
		var res := "Хиты %d/%d · КД %d" % [h.hp, h.max_hp, h.total_ac()]
		if h.max_slots > 0:
			res += " · Ячейки %d/%d" % [h.slots, h.max_slots]
		for k in h.uses:
			res += " · %s %d" % [Content.ABILITIES[k].name, h.uses[k]]
		var res_l := _label(res, 12, 200)
		box.add_child(res_l)
		var marks := []
		for tr in h.traits:
			marks.append(Content.TRAITS[tr].name)
		if h.dodging:
			marks.append("уклоняется")
		if h.raging:
			marks.append("в ярости")
		if h.stunned:
			marks.append("парализован")
		if h.restrained:
			marks.append("опутан")
		if h.spirit_weapon:
			marks.append("духовное оружие")
		if h.guardians:
			marks.append("духовные стражи")
		if h.hidden:
			marks.append("спрятан")
		if h.prone and not h.down:
			marks.append("лежит")
		if not marks.is_empty():
			box.add_child(_label(" · ".join(marks), 12, 200))
		if not h.items.is_empty():
			panel.tooltip_text = "Экипировка: " + ", ".join(Items.names_of(h))
		var cell := h.cell
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed:
				_focus(cell))
		portraits.add_child(panel)


func _refresh_buttons(u: Combatant) -> void:
	for ch in buttons_box.get_children():
		ch.queue_free()
	var mine := u.team == 0 and not busy and battle.outcome == ""
	var base := _button("Движение\nи атака", func() -> void: _select_mode(""))
	base.toggle_mode = true
	base.button_pressed = mode == ""
	base.disabled = not mine
	buttons_box.add_child(base)
	if mine:
		for aid in u.abilities:
			var a := battle.ability(aid)
			var text: String = a.name
			if a.get("dark", false):
				text += "\nдаров за бой: %d" % battle.dark_gifts_left()
			elif a.resource == "slot":
				text += "\nячейка (%d)" % u.slots
			elif a.resource == "use":
				text += "\nосталось %d" % u.uses_left(aid)
			else:
				text += "\n" + {"bonus": "бонусное", "free": "без действия"}.get(a.cost, "действие")
			var b := _button(text, func() -> void: _select_mode(aid))
			b.toggle_mode = true
			b.button_pressed = mode == aid
			b.disabled = not battle.can_use(u, aid)
			b.tooltip_text = a.desc
			if a.get("dark", false):
				b.add_theme_color_override("font_color", Color("#c9a0ff"))
				b.add_theme_color_override("font_pressed_color", Color("#e2ccff"))
			buttons_box.add_child(b)
	var end := _button("Конец\nхода", func() -> void: _end_turn())
	end.disabled = not mine
	buttons_box.add_child(end)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 40
	root.add_child(top)
	var top_box := HBoxContainer.new()
	top_box.add_theme_constant_override("separation", 24)
	top.add_child(top_box)
	round_label = _label("", 16)
	turn_label = _label("", 16)
	dark_label = _label("", 14)
	dark_label.add_theme_color_override("font_color", Color("#c9a0ff"))
	top_box.add_child(round_label)
	top_box.add_child(turn_label)
	top_box.add_child(dark_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_box.add_child(spacer)
	top_box.add_child(_button("Меню", func() -> void:
		if not busy:
			_show_menu()))

	portraits = VBoxContainer.new()
	portraits.position = Vector2(8, 50)
	portraits.add_theme_constant_override("separation", 6)
	root.add_child(portraits)

	var log_panel := PanelContainer.new()
	log_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	log_panel.offset_left = -300
	log_panel.offset_top = 50
	log_panel.offset_bottom = -150
	log_panel.modulate = Color(1, 1, 1, 0.85)
	root.add_child(log_panel)
	log_box = RichTextLabel.new()
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 13)
	log_panel.add_child(log_box)

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -140
	root.add_child(bottom)
	var bottom_box := VBoxContainer.new()
	bottom.add_child(bottom_box)
	preview_label = _label("", 16, 600)
	preview_label.custom_minimum_size = Vector2(600, 44)
	bottom_box.add_child(preview_label)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 76)
	bottom_box.add_child(scroll)
	buttons_box = HBoxContainer.new()
	buttons_box.add_theme_constant_override("separation", 8)
	scroll.add_child(buttons_box)


func _label(text: String, size: int, wrap_width := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_width > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(wrap_width, 0)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 64)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(on_press)
	return b


func _row(caption: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := _label(caption, 16)
	l.custom_minimum_size = Vector2(160, 0)
	row.add_child(l)
	control.custom_minimum_size = Vector2(220, 40)
	row.add_child(control)
	return row
