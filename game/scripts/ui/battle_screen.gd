extends Node2D
## Экран боя (B9 плана review/07-next-steps.md): героями и спутниками управляет игрок, врагами — ИИ.
##
## Мышь: наведение показывает путь, шанс и урон, клик выполняет. Двойной клик — по желанию в меню боя
## (первый клик показывает прогноз, второй по той же клетке выполняет); на тач-экране так всегда.
## Клавиатура и геймпад: курсор по клеткам стрелками или крестовиной, подтверждение — Enter или A,
## умения — 1–9 или LB/RB, конец хода — E или Y.
## Сверху полоса инициативы и цель боя, слева отряд, справа журнал, снизу прогноз и панель умений.
## Бой берётся из Game.battle; после победы — Game.finish_battle и возврат в Game.battle_return_scene.

const TAP_SLOP := 12.0
const ZOOM_MIN := 0.6
const ZOOM_MAX := 2.6
const TOP_H := 96.0
const LEFT_W := 262.0
const LOG_W := 290.0
const BOTTOM_H := 132.0
## Клавиши умений по порядку на панели.
const HOTKEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
## Направления курсора на экране → шаг по клетке в изометрии.
const CURSOR_DIRS := {"ui_up": Vector2i(-1, -1), "ui_down": Vector2i(1, 1), "ui_left": Vector2i(-1, 1),
	"ui_right": Vector2i(1, -1)}

var battle: Battle
var board: BoardView
var cam: Camera2D

## Выбранное умение ("" — движение и атака оружием).
var mode := ""
var busy := false
var press_pos := Vector2.ZERO
var dragging := false
var touches := {}
var pinch_dist := 0.0
## Последний клик пришёл с тач-экрана: тогда действие всегда подтверждается вторым тапом.
var touch_mode := false
var log_shown := 0
## Пауза между шагами врагов, сек. (тесты ставят 0).
var enemy_step := 0.4

var _hud: CanvasLayer
var _init_bar: HBoxContainer
var _round_label: Label
var _objective: Label
var _party: VBoxContainer
var _log_panel: PanelContainer
var _log: RichTextLabel
var _preview: Label
var _abilities: HBoxContainer
var _hints: Label
var _overlay: CanvasLayer = null


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1d1f24"))
	battle = Game.battle
	if battle == null and Game.session != null and Game.session.pending_battle != "":
		battle = Game.start_battle()
	if battle == null:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")
		return
	Sound.for_battle()
	board = BoardView.new()
	board.battle = battle
	add_child(board)
	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()
	_build_hud()
	InputSetup.device_changed.connect(func(_k: String) -> void: _refresh_hints())
	_fit_camera.call_deferred()
	_advance.call_deferred()


# --- Ход за ходом --------------------------------------------------------

## Проигрывает ходы врагов, пока не наступит ход отряда или конец боя.
func _advance() -> void:
	busy = true
	_refresh()
	while battle.outcome == "" and battle.current().team == 1:
		var e := battle.current()
		_focus_if_needed(e.cell)
		_refresh()
		if enemy_step > 0.0:
			await get_tree().create_timer(enemy_step).timeout
		CombatAI.take_turn(battle, e)
		_refresh()
		if enemy_step > 0.0:
			await get_tree().create_timer(enemy_step).timeout
		battle.end_turn()
	busy = false
	if battle.outcome != "":
		_refresh()
		_show_result()
		return
	# Начало хода героя: сохранение для продолжения после выхода (DESIGN.md, «Режимы сложности»).
	if Game.session != null:
		Game.save_battle()
	mode = ""
	_focus_if_needed(battle.current().cell)
	if board.cursor_cell.x >= 0:
		board.cursor_cell = battle.current().cell
	_refresh()


func _end_turn() -> void:
	if not _my_turn():
		return
	battle.end_turn()
	_advance()


func _after_action() -> void:
	mode = ""
	_refresh()
	if battle.outcome != "":
		_show_result()


func _my_turn() -> bool:
	return battle != null and not busy and battle.outcome == "" and battle.current().team == 0 and _overlay == null


# --- План действия по клетке -------------------------------------------------

## Что случится, если выбрать клетку c: {"text", "path", "area", "act": Callable или пусто}.
func _plan(c: Vector2i) -> Dictionary:
	var u := battle.current()
	if mode != "":
		return _plan_ability(u, c)
	var o := battle.occupant(c)
	var reach := battle.reachable(u)
	if o != null and o.team != u.team and o.conscious() and not o.has_status("bound"):
		if u.action_used:
			return {"text": tr("BATTLE_PV_ACTION_SPENT") + " " + _unit_info(o)}
		if battle.mod_any(u, "no_harm"):
			return {"text": UiKit.fmt("BATTLE_PV_NO_HARM", {"name": u.name})}
		if battle.in_weapon_range(u, o):
			var p := battle.attack_preview(u, o)
			return {"text": UiKit.fmt("BATTLE_PV_ATTACK", _attack_values(o, p)),
				"act": func() -> void: battle.attack(u, o)}
		if not u.is_ranged():
			var spot := _approach_cell(u, o, reach)
			if spot.x >= 0:
				var path := battle.path_to(u, spot, reach)
				var p2 := battle.attack_preview(u, o)
				var go_and_hit := func() -> void:
					battle.move_along(u, path)
					if battle.can_attack(u, o):
						battle.attack(u, o)
				return {"text": UiKit.fmt("BATTLE_PV_APPROACH", _attack_values(o, p2)) + _oa_text(battle.count_opportunity(u, path)),
					"path": path, "act": go_and_hit}
		return {"text": UiKit.fmt("BATTLE_PV_TOO_FAR", {"name": o.name})}
	if o == null and c != u.cell and reach.has(c):
		var path2 := battle.path_to(u, c, reach)
		return {"text": UiKit.fmt("BATTLE_PV_MOVE", {"n": path2.size()}) + _oa_text(battle.count_opportunity(u, path2)),
			"path": path2, "act": func() -> void: battle.move_along(u, path2)}
	if o != null:
		var info := _unit_info(o)
		if o.has_status("bound") and o.team == u.team:
			info += " " + tr("BATTLE_PV_BOUND_HINT")
		return {"text": info}
	return {"text": tr("BATTLE_PV_NO_PATH") if battle.in_bounds(c) and not battle.is_obstacle(c) else ""}


func _plan_ability(u: Combatant, c: Vector2i) -> Dictionary:
	var a := battle.ability(mode)
	if a.target == "self":
		c = u.cell
	if not battle.ability_targets(u, mode).has(c):
		return {"text": tr("ABILITY_" + mode) + ": " + tr("BATTLE_PV_BAD_CELL")}
	var aid := mode
	return {"text": _ability_text(u, aid, c), "area": battle.ability_area(u, aid, c),
		"act": func() -> void: battle.use_ability(u, aid, c)}


func _attack_values(o: Combatant, p: Dictionary) -> Dictionary:
	var extra := ""
	if p.adv > 0:
		extra = " " + tr("BATTLE_PV_ADV")
	elif p.adv < 0:
		extra = " " + tr("BATTLE_PV_DISADV")
	if p.get("sneak", false):
		extra += " " + tr("BATTLE_PV_SNEAK")
	return {"name": o.name, "chance": roundi(p.chance * 100), "min": p.min, "max": p.max, "extra": extra}


## Прогноз умения словами: шанс, урон или лечение, сколько задевает.
func _ability_text(u: Combatant, aid: String, c: Vector2i) -> String:
	var a := battle.ability(aid)
	var p := battle.ability_preview(u, aid, c)
	var parts := PackedStringArray()
	match String(p.kind):
		"weapon":
			var o := battle.occupant(c)
			parts.append(UiKit.fmt("BATTLE_PV_CHANCE_DMG", _attack_values(o, p)))
		"spell_attack":
			var line := UiKit.fmt("BATTLE_PV_CHANCE_DMG", {"chance": roundi(p.chance * 100), "min": p.min, "max": p.max, "extra": ""})
			if int(p.get("times", 1)) > 1:
				line += " ×%d" % int(p.times)
			parts.append(line)
		"save":
			var line2 := UiKit.fmt("BATTLE_PV_SAVE_FAIL", {"chance": roundi(p.chance * 100)})
			if p.has("min"):
				line2 += ", " + UiKit.fmt("BATTLE_PV_DMG", {"min": p.min, "max": p.max})
			if p.get("falls", false):
				line2 += ", " + tr("BATTLE_PV_FALLS")
			parts.append(line2)
		"damage":
			parts.append(UiKit.fmt("BATTLE_PV_DMG", {"min": p.min, "max": p.max}))
		"heal":
			parts.append(UiKit.fmt("BATTLE_PV_HEAL", {"min": p.min, "max": p.max}))
		_:
			parts.append(tr("ABILITY_%s_DESC" % aid))
	if battle.params_of(u, aid).has("radius") and not p.hits.is_empty():
		var own := 0
		for uid in p.hits:
			if battle.get_unit(uid).team == u.team:
				own += 1
		parts.append(UiKit.fmt("BATTLE_PV_HITS", {"n": p.hits.size() - own, "own": own}))
	if a.has("dark"):
		var cost := tr("BATTLE_PV_DARK_SLOT") if String(a.dark) == "slot" else UiKit.fmt("BATTLE_PV_DARK_HP",
			{"hp": battle.dark_hp_cost(u)})
		parts.append(cost)
	return tr("ABILITY_" + aid) + ": " + ", ".join(parts).trim_suffix(".") + "."


## Ближайшая достижимая клетка рядом с целью для ближней атаки.
func _approach_cell(u: Combatant, target: Combatant, reach: Dictionary) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_cost := 1_000_000
	for c in reach:
		if not c is Vector2i or battle.occupant(c) != null and c != u.cell:
			continue
		if Battle.dist(c, target.cell) <= u.reach() and int(reach[c].cost) < best_cost:
			best_cost = int(reach[c].cost)
			best = c
	return best


func _oa_text(n: int) -> String:
	return "" if n == 0 else " " + UiKit.fmt("BATTLE_PV_PROVOKES", {"n": n})


func _unit_info(o: Combatant) -> String:
	var s := UiKit.fmt("BATTLE_UNIT_INFO", {"name": o.name, "hp": o.hp, "max": o.max_hp, "ac": battle.ac_of(o)})
	var marks := PackedStringArray()
	for sid in o.statuses:
		marks.append(tr("STATUS_" + sid))
	if not marks.is_empty():
		s += " (" + ", ".join(marks) + ")"
	return s


## Показать прогноз по клетке; pending — ждать подтверждения на этой клетке.
func _show_plan(c: Vector2i, pending := false) -> void:
	board.path.clear()
	board.area_cells.clear()
	board.pending_cell = c if pending else Vector2i(-1, -1)
	if not _my_turn() or not battle.in_bounds(c):
		board.queue_redraw()
		return
	var plan := _plan(c)
	if plan.has("path"):
		board.path = plan.path
	if plan.has("area"):
		board.area_cells = plan.area
	_preview.text = String(plan.get("text", "")) if String(plan.get("text", "")) != "" else _turn_hint()
	board.queue_redraw()


## Выбор клетки: клик, тап или подтверждение с клавиатуры и геймпада.
func _select_cell(c: Vector2i, from_pointer: bool) -> void:
	if not _my_turn() or not battle.in_bounds(c):
		return
	var confirm_first := from_pointer and (touch_mode or Game.battle_double_click)
	if confirm_first and board.pending_cell != c:
		_show_plan(c, true)
		return
	var plan := _plan(c)
	var act: Callable = plan.get("act", Callable())
	if not act.is_valid():
		_show_plan(c, false)
		return
	act.call()
	_after_action()


func _select_mode(aid: String) -> void:
	if not _my_turn():
		return
	var u := battle.current()
	if aid != "" and mode == aid and battle.ability(aid).target == "self":
		# Повторное нажатие умения на себя применяет его.
		_select_cell(u.cell, false)
		return
	mode = "" if aid == mode else aid
	_refresh()
	if mode != "" and battle.ability(mode).target == "self":
		_show_plan(u.cell, false)
		_preview.text += " " + tr("BATTLE_PV_SELF_AGAIN")
	elif mode != "":
		_preview.text = tr("ABILITY_" + mode) + ": " + tr("ABILITY_%s_DESC" % mode) + " " + tr("BATTLE_PV_PICK_TARGET")


func _cycle_mode(step: int) -> void:
	if not _my_turn():
		return
	var list: Array[String] = [""]
	for aid in _shown_abilities(battle.current()):
		if battle.can_use(battle.current(), aid):
			list.append(aid)
	var i := (list.find(mode) + step + list.size()) % list.size()
	if list[i] == "":
		mode = ""
		_refresh()
	else:
		_select_mode(list[i])


# --- Ввод ----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _overlay != null:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("game_menu"):
			if battle.outcome == "":
				_close_overlay()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("game_menu"):
		_open_menu()
	elif event.is_action_pressed("battle_end_turn"):
		_end_turn()
	elif event.is_action_pressed("battle_next_ability"):
		_cycle_mode(1)
	elif event.is_action_pressed("battle_prev_ability"):
		_cycle_mode(-1)
	elif event.is_action_pressed("battle_focus") and battle.outcome == "":
		_focus(battle.current().cell)
	elif event.is_action_pressed("ui_cancel") and mode != "":
		mode = ""
		_refresh()
	elif event.is_action_pressed("ui_accept") and _my_turn():
		if board.cursor_cell.x >= 0:
			_select_cell(board.cursor_cell, false)
		else:
			_move_cursor(Vector2i.ZERO)
	elif event is InputEventKey and event.pressed and not event.echo and HOTKEYS.has(event.physical_keycode):
		var list := _shown_abilities(battle.current()) if _my_turn() else ([] as Array[String])
		var i: int = HOTKEYS.find(event.physical_keycode)
		if i < list.size():
			_select_mode(list[i])
	else:
		for action in CURSOR_DIRS:
			if event.is_action_pressed(action, true):
				_move_cursor(CURSOR_DIRS[action])
				get_viewport().set_input_as_handled()
				return
		_pointer_input(event)


func _move_cursor(step: Vector2i) -> void:
	if battle.outcome != "":
		return
	var c := board.cursor_cell if board.cursor_cell.x >= 0 else battle.current().cell
	c = Vector2i(clampi(c.x + step.x, 0, battle.width - 1), clampi(c.y + step.y, 0, battle.height - 1))
	if board.cursor_cell.x < 0:
		c = battle.current().cell
	board.cursor_cell = c
	board.hover_cell = Vector2i(-1, -1)
	_show_plan(c)
	# Камера идёт за курсором, когда он уходит к краю свободной области.
	_focus_if_needed(c)


func _pointer_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touch_mode = true
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
		# Мышь, которую Godot изображает из касания, приходит с устройства эмуляции.
		touch_mode = event.device == InputEvent.DEVICE_ID_EMULATION
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.0 / 1.1)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and mode != "":
			mode = ""
			_refresh()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_pos = event.position
				dragging = false
			elif not dragging and touches.size() < 2:
				board.cursor_cell = Vector2i(-1, -1)
				_select_cell(BoardView.world_to_cell(board.get_global_mouse_position()), true)
	elif event is InputEventMouseMotion:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE):
			if touches.size() >= 2:
				return
			if not dragging and event.position.distance_to(press_pos) > TAP_SLOP:
				dragging = true
			if dragging or not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
				cam.position -= event.relative / cam.zoom.x
			return
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		# Превью по наведению: путь, шанс и урон без клика.
		var c := BoardView.world_to_cell(board.get_global_mouse_position())
		if c != board.hover_cell:
			board.hover_cell = c
			board.cursor_cell = Vector2i(-1, -1)
			if board.pending_cell.x < 0:
				_show_plan(c)
			else:
				board.queue_redraw()


func _zoom_by(f: float) -> void:
	var z := clampf(cam.zoom.x * f, ZOOM_MIN, ZOOM_MAX)
	cam.zoom = Vector2(z, z)


## Сдвинуть камеру, только если клетка у края или за панелями: поле не дёргается на каждом ходу.
func _focus_if_needed(c: Vector2i) -> void:
	var screen := get_viewport().get_canvas_transform() * BoardView.cell_to_world(c)
	if not _free_rect().grow(-70).has_point(screen):
		_focus(c)


func _focus(c: Vector2i) -> void:
	var tw := create_tween()
	tw.tween_property(cam, "position", _cam_pos_for(BoardView.cell_to_world(c)), 0.25)


## Всё поле между панелями.
func _fit_camera() -> void:
	var free := _free_rect()
	var w := (battle.width + battle.height) * BoardView.HALF_W
	var h := (battle.width + battle.height) * BoardView.HALF_H + 60.0
	var z := clampf(minf(free.size.x / w, free.size.y / h), ZOOM_MIN, 1.4)
	cam.zoom = Vector2(z, z)
	var center := Vector2((battle.width - battle.height) * BoardView.HALF_W * 0.5,
		(battle.width + battle.height - 2) * BoardView.HALF_H * 0.5 - 30.0)
	cam.position = _cam_pos_for(center)


## Позиция камеры, при которой точка поля оказывается в середине свободной от панелей области.
func _cam_pos_for(world: Vector2) -> Vector2:
	var view := get_viewport_rect().size
	return world - (_free_rect().get_center() - view * 0.5) / cam.zoom.x


func _free_rect() -> Rect2:
	var view := get_viewport_rect().size
	var right := LOG_W if _log_panel != null and _log_panel.visible else 0.0
	return Rect2(Vector2(LEFT_W, TOP_H), view - Vector2(LEFT_W + right, TOP_H + BOTTOM_H))


# --- Интерфейс -----------------------------------------------------------

func _refresh() -> void:
	if battle == null:
		return
	for ev in battle.take_events():
		var target := battle.get_unit(String(ev.unit))
		if target == null:
			continue
		match String(ev.type):
			"damage":
				board.popup(target.cell, "-%d" % int(ev.amount), Color("#ff6b5a"))
			"heal":
				board.popup(target.cell, "+%d" % int(ev.amount), Color("#6bff8a"))
			"miss":
				board.popup(target.cell, tr("BATTLE_MISS"), Color("#cccccc"))
			"spawn":
				board.popup(target.cell, "!", Color("#ff6b5a"))
	while log_shown < battle.log_lines.size():
		_log.append_text(battle.log_lines[log_shown] + "\n")
		log_shown += 1
	_refresh_top()
	_refresh_party()
	_refresh_abilities()
	board.clear_marks()
	board.spawn_cells.clear()
	var wave := battle.next_wave_round()
	if wave > 0 and wave <= battle.round_num + 1:
		for w in battle.stage.get("waves", []):
			if int(w.round) == wave:
				for c in w.cells:
					board.spawn_cells.append(Vector2i(int(c[0]), int(c[1])))
	_preview.text = ""
	if not _my_turn():
		board.queue_redraw()
		return
	var u := battle.current()
	if mode == "":
		for c in battle.reachable(u):
			if c is Vector2i and c != u.cell and battle.occupant(c) == null:
				board.reach_cells.append(c)
		if not u.action_used and not battle.mod_any(u, "no_harm"):
			for f in battle.foes_of(u):
				if battle.in_weapon_range(u, f):
					board.target_cells.append(f.cell)
		board.target_is_ally = false
		_preview.text = _turn_hint()
	else:
		var a := battle.ability(mode)
		if a.target == "cell" or a.target == "empty_cell":
			board.reach_cells = battle.ability_targets(u, mode)
		else:
			board.target_cells = battle.ability_targets(u, mode)
			board.target_is_ally = a.target == "ally" or a.target == "self"
	board.queue_redraw()


func _turn_hint() -> String:
	var u := battle.current()
	var hint := UiKit.fmt("BATTLE_TURN_HINT", {"name": u.name, "n": u.speed_left})
	if battle.mod_any(u, "no_harm"):
		return hint + " " + UiKit.fmt("BATTLE_PV_NO_HARM", {"name": u.name})
	return hint + ("" if u.action_used else " " + tr("BATTLE_TURN_HINT_ACTION"))


func _refresh_top() -> void:
	_round_label.text = UiKit.fmt("BATTLE_ROUND", {"n": battle.round_num})
	var obj: Dictionary = battle.stage.get("objective", {})
	var text := tr("BATTLE_OBJ_KILL_ALL")
	if String(obj.get("type", "")) == "survive":
		text = UiKit.fmt(String(obj.get("key", "BATTLE_OBJ_SURVIVE")), {"rounds": obj.rounds}) + " " + \
			UiKit.fmt("BATTLE_OBJ_PROGRESS", {"n": mini(battle.round_num, int(obj.rounds)), "max": obj.rounds})
	var wave := battle.next_wave_round()
	if wave > 0:
		text += " · " + UiKit.fmt("BATTLE_WAVE_AT", {"n": wave})
	_objective.text = text
	for ch in _init_bar.get_children():
		_init_bar.remove_child(ch)
		ch.queue_free()
	# Очередь с текущего хода: кто ходит сейчас, кто следом; черта — начало следующего раунда.
	var n := battle.order.size()
	for k in n:
		var i := (battle.turn_index + k) % n
		if k > 0 and i == 0:
			var sep := UiKit.label("|", UiKit.FONT_SMALL, UiKit.MUTED)
			sep.tooltip_text = UiKit.fmt("BATTLE_ROUND", {"n": battle.round_num + 1})
			sep.mouse_filter = Control.MOUSE_FILTER_PASS
			_init_bar.add_child(sep)
		var u := battle.get_unit(battle.order[i])
		if u.dead:
			continue
		_init_bar.add_child(_token(u, k == 0 and battle.outcome == ""))


## Фишка участника в полосе инициативы: цвет, буква, полоска хитов.
func _token(u: Combatant, active: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = u.color.darkened(0.5) if not u.down else Color("#2a2a2a")
	sb.border_color = UiKit.ACCENT if active else (u.color if u.team == 0 else Color("#6b3a3a"))
	sb.set_border_width_all(3 if active else 1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(40, 46)
	p.tooltip_text = _unit_info(u)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(box)
	var l := UiKit.label(u.letter + ("⛓" if u.has_status("bound") else ""), 18, Color.WHITE if not u.down else UiKit.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	box.add_child(_hp_bar(u, 5))
	var cell := u.cell
	p.mouse_entered.connect(func() -> void:
		board.hover_cell = cell
		_preview.text = _unit_info(u)
		board.queue_redraw())
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_focus(cell))
	return p


func _hp_bar(u: Combatant, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = u.max_hp
	bar.value = u.hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = BoardView.hp_color(float(u.hp) / u.max_hp)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bar.add_theme_stylebox_override("background", bg)
	return bar


func _refresh_party() -> void:
	for ch in _party.get_children():
		_party.remove_child(ch)
		ch.queue_free()
	for h in battle.heroes():
		var panel := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		var active := battle.outcome == "" and battle.current() == h
		sb.bg_color = UiKit.PANEL if not active else UiKit.PANEL.lightened(0.12)
		sb.border_color = UiKit.ACCENT if active else h.color.darkened(0.3)
		sb.set_border_width_all(2 if active else 1)
		sb.set_corner_radius_all(4)
		sb.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", sb)
		panel.custom_minimum_size = Vector2(LEFT_W - 16, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(row)
		row.add_child(_face(h))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(box)
		var name_text := h.name
		if h.down:
			name_text += " — " + tr("BATTLE_DOWN")
		box.add_child(_small(name_text, 15, Color.WHITE))
		box.add_child(_hp_bar(h, 8))
		var res := UiKit.fmt("BATTLE_HP_AC", {"hp": h.hp, "max": h.max_hp, "ac": battle.ac_of(h)})
		if h.max_slots > 0:
			res += " · " + UiKit.fmt("BATTLE_SLOTS", {"n": h.slots, "max": h.max_slots})
		box.add_child(_small(res, 12, UiKit.TEXT))
		var marks := PackedStringArray()
		for sid in h.statuses:
			if sid != "prone" or not h.down:
				marks.append(tr("STATUS_" + sid))
		if not marks.is_empty():
			box.add_child(_small(" · ".join(marks), 12, Color("#bfe3ff")))
		if not h.items.is_empty():
			panel.tooltip_text = UiKit.fmt("BATTLE_GEAR", {"items": ", ".join(Items.names_of(h))})
		var cell := h.cell
		panel.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_focus(cell))
		_party.add_child(panel)


## Портрет 64 px (art/portraits); у кого портрета нет — цветная плашка. Выбывший — серый.
func _face(h: Combatant) -> Control:
	var hero: Dictionary = Game.session.state.hero if Game.session != null else {"class": h.kind}
	var id := Portraits.id_for("hero" if h.is_hero else h.kind, "", hero)
	if id == "":
		var plate := ColorRect.new()
		plate.color = h.color if h.conscious() else Color("#555555")
		plate.custom_minimum_size = Vector2(36, 44)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return plate
	var face := Portraits.view(id, 64, 1)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if not h.conscious():
		face.modulate = Color(0.45, 0.45, 0.45)
	return face


func _small(text: String, size: int, color: Color) -> Label:
	var l := UiKit.label(text, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Умения на панели: базовые действия и умения участника; тёмные дары — только когда они открыты сюжетом.
func _shown_abilities(u: Combatant) -> Array[String]:
	var out: Array[String] = []
	var gifts := Game.session != null and Game.dark_gifts_open()
	for aid in u.abilities:
		if battle.ability(aid).has("dark") and not gifts:
			continue
		out.append(aid)
	return out


func _refresh_abilities() -> void:
	for ch in _abilities.get_children():
		_abilities.remove_child(ch)
		ch.queue_free()
	var mine := _my_turn()
	var base := AbilityIcon.make("", "action", "⚔", "", "")
	base.selected = mine and mode == ""
	base.disabled = not mine
	base.tooltip_text = tr("BATTLE_MOVE_ATTACK")
	base.pressed.connect(func() -> void:
		mode = ""
		_refresh())
	_abilities.add_child(base)
	if mine:
		var u := battle.current()
		var list := _shown_abilities(u)
		for i in list.size():
			var aid := list[i]
			var a := battle.ability(aid)
			var kind := String(a.cost)
			var badge := ""
			if a.has("dark"):
				kind = "dark"
				badge = "✦%d" % battle.dark_gifts_left()
			elif a.get("resource", "none") == "slot":
				kind = "spell"
				badge = "●%d" % u.slots
			elif a.get("resource", "none") == "use":
				badge = "×%d" % u.uses_left(aid)
			var hot := OS.get_keycode_string(HOTKEYS[i]) if i < HOTKEYS.size() and InputSetup.device == "keyboard" else ""
			var icon := AbilityIcon.make(aid, kind, AbilityIcon.abbreviate(tr("ABILITY_" + aid)), hot, badge)
			icon.selected = mode == aid
			icon.disabled = not battle.can_use(u, aid)
			icon.tooltip_text = "%s (%s)\n%s" % [tr("ABILITY_" + aid), tr("BATTLE_COST_" + String(a.cost)),
				tr("ABILITY_%s_DESC" % aid)]
			icon.pressed.connect(_select_mode.bind(aid))
			icon.mouse_entered.connect(func() -> void:
				_preview.text = "%s: %s" % [tr("ABILITY_" + aid), tr("ABILITY_%s_DESC" % aid)])
			_abilities.add_child(icon)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(12, 0)
	_abilities.add_child(spacer)
	var end := UiKit.button(tr("BATTLE_END_TURN"), _end_turn, UiKit.FONT_SMALL)
	end.disabled = not mine
	end.focus_mode = Control.FOCUS_NONE
	end.custom_minimum_size = Vector2(130, 60)
	_abilities.add_child(end)


func _refresh_hints() -> void:
	if _hints == null:
		return
	if InputSetup.device == "keyboard":
		_hints.text = tr("BATTLE_HINTS_KEYBOARD")
	else:
		_hints.text = UiKit.fmt("BATTLE_HINTS_PAD", {"a": InputSetup.glyph("ui_accept"), "b": InputSetup.glyph("ui_cancel"),
			"y": InputSetup.glyph("battle_end_turn"), "x": InputSetup.glyph("battle_focus"), "menu": InputSetup.glyph("game_menu")})


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Тема окна (шрифты из UiKit) не доходит до интерфейса внутри CanvasLayer: ставим её сюда же.
	root.theme = get_tree().root.theme
	_hud.add_child(root)

	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_H - 6
	top.add_theme_stylebox_override("panel", _panel_style(0.92))
	root.add_child(top)
	var top_col := VBoxContainer.new()
	top_col.add_theme_constant_override("separation", 2)
	top.add_child(top_col)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	top_col.add_child(top_row)
	_round_label = UiKit.label("", UiKit.FONT_SMALL, UiKit.ACCENT)
	_round_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_round_label.custom_minimum_size = Vector2(90, 0)
	top_row.add_child(_round_label)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 52)
	top_row.add_child(scroll)
	_init_bar = HBoxContainer.new()
	_init_bar.add_theme_constant_override("separation", 4)
	scroll.add_child(_init_bar)
	var log_btn := UiKit.button(tr("BATTLE_LOG"), func() -> void:
		_log_panel.visible = not _log_panel.visible, UiKit.FONT_SMALL)
	log_btn.focus_mode = Control.FOCUS_NONE
	top_row.add_child(log_btn)
	var menu_btn := UiKit.button(tr("STORY_MENU"), _open_menu, UiKit.FONT_SMALL)
	menu_btn.focus_mode = Control.FOCUS_NONE
	top_row.add_child(menu_btn)
	_objective = UiKit.label("", UiKit.FONT_SMALL, UiKit.SPEAKER)
	_objective.autowrap_mode = TextServer.AUTOWRAP_OFF
	_objective.clip_text = true
	top_col.add_child(_objective)

	_party = VBoxContainer.new()
	_party.position = Vector2(8, TOP_H)
	_party.add_theme_constant_override("separation", 6)
	root.add_child(_party)

	_log_panel = PanelContainer.new()
	_log_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_log_panel.offset_left = -LOG_W
	_log_panel.offset_top = TOP_H
	_log_panel.offset_bottom = -BOTTOM_H - 4
	_log_panel.add_theme_stylebox_override("panel", _panel_style(0.8))
	root.add_child(_log_panel)
	_log = RichTextLabel.new()
	_log.scroll_following = true
	_log.add_theme_font_size_override("normal_font_size", 13)
	_log_panel.add_child(_log)
	_log_panel.visible = get_viewport_rect().size.x >= 1100

	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -BOTTOM_H
	bottom.add_theme_stylebox_override("panel", _panel_style(0.92))
	root.add_child(bottom)
	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 4)
	bottom.add_child(bottom_box)
	_preview = UiKit.label("", 16, UiKit.TEXT)
	_preview.custom_minimum_size = Vector2(0, 22)
	_preview.autowrap_mode = TextServer.AUTOWRAP_OFF
	_preview.clip_text = true
	bottom_box.add_child(_preview)
	var bar_scroll := ScrollContainer.new()
	bar_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bar_scroll.custom_minimum_size = Vector2(0, 64)
	bottom_box.add_child(bar_scroll)
	_abilities = HBoxContainer.new()
	_abilities.add_theme_constant_override("separation", 6)
	bar_scroll.add_child(_abilities)
	_hints = UiKit.label("", 12, UiKit.MUTED)
	_hints.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hints.clip_text = true
	bottom_box.add_child(_hints)
	_refresh_hints()


func _panel_style(alpha: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UiKit.BG, alpha)
	sb.set_content_margin_all(6)
	return sb


# --- Итог боя и меню ---------------------------------------------------------

func _overlay_column() -> VBoxContainer:
	_close_overlay()
	_overlay = CanvasLayer.new()
	_overlay.layer = 10
	add_child(_overlay)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = get_tree().root.theme
	_overlay.add_child(root)
	return UiKit.overlay(root)


func _close_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


func _show_result() -> void:
	var col := _overlay_column()
	var won := battle.outcome == "victory"
	col.add_child(UiKit.heading((tr("BATTLE_VICTORY") if won else tr("BATTLE_DEFEAT")).to_upper(), UiKit.HEAD_TITLE,
		UiKit.ACCENT if won else UiKit.DANGER))
	var down := 0
	for h in battle.heroes():
		if not h.conscious():
			down += 1
	col.add_child(UiKit.label(UiKit.fmt("BATTLE_RESULT_STATS", {"rounds": battle.round_num, "down": down}), UiKit.FONT_SMALL))
	if not won:
		PlaytestLog.event("battle_lost", {"battle": battle.id, "rounds": battle.round_num, "difficulty": battle.difficulty})
	if won and battle.stage.get("rescued", false):
		col.add_child(UiKit.label(tr("BATTLE_RESCUED_NOTE"), UiKit.FONT_SMALL, UiKit.MUTED))
	if won:
		col.add_child(UiKit.button(tr("BATTLE_CONTINUE"), _leave_victory))
	elif battle.difficulty == "story":
		col.add_child(UiKit.label(tr("BATTLE_STORY_DEFEAT"), UiKit.FONT_SMALL, UiKit.MUTED))
		col.add_child(UiKit.button(tr("BATTLE_RETRY"), _retry))
	else:
		# «Испытание»: переигровки нет, только загрузка сюжетного сохранения (DESIGN.md, «Режимы сложности»).
		col.add_child(UiKit.label(tr("BATTLE_TRIAL_DEFEAT"), UiKit.FONT_SMALL, UiKit.MUTED))
		col.add_child(UiKit.button(tr("BATTLE_LOAD_LAST"), _load_last.bind(false)))
		col.add_child(UiKit.button(tr("BATTLE_LOAD_AS_STORY"), _load_last.bind(true)))
	UiKit.focus_first(col)


func _leave_victory() -> void:
	finish()
	get_tree().change_scene_to_file(Game.battle_return_scene)


## Победа засчитана: история идёт дальше, боевое сохранение удалено, Тьма боя ушла в шкалу.
func finish() -> void:
	if Game.session != null and Game.session.pending_battle != "":
		Game.finish_battle(battle.darkness)
	else:
		Game.abandon_battle()


func _retry() -> void:
	Game.start_battle()
	get_tree().reload_current_scene()


func _load_last(as_story: bool) -> void:
	Game.abandon_battle()
	var slot := SaveStore.latest()
	if slot == "":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	Game.pending_tail = Game.load_from(slot)
	if as_story:
		Game.session.state.difficulty = "story"
	get_tree().change_scene_to_file(Game.screen_path())


func _open_menu() -> void:
	if busy and battle.outcome == "":
		return
	var col := _overlay_column()
	col.add_child(UiKit.heading(tr("BATTLE_MENU"), UiKit.HEAD_BODY))
	col.add_child(UiKit.button(tr("BATTLE_RESUME"), _close_overlay))
	var dbl := CheckButton.new()
	dbl.text = tr("BATTLE_DOUBLE_CLICK")
	dbl.button_pressed = Game.battle_double_click
	dbl.add_theme_font_size_override("font_size", UiKit.FONT_SMALL)
	dbl.toggled.connect(func(on: bool) -> void: Game.set_battle_double_click(on))
	col.add_child(dbl)
	col.add_child(UiKit.label(tr("BATTLE_DOUBLE_CLICK_NOTE"), UiKit.FONT_SMALL, UiKit.MUTED))
	GameMenus.volume_sliders(col)
	col.add_child(UiKit.button(tr("BATTLE_TO_MENU"), func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")))
	UiKit.focus_first(col)
