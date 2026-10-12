class_name IsoBoard
extends Control
## Кусок поля боя в изометрии 64×32 из якорей стиля: пол, крепь и Гаррет.
## Управление: курсор — крестовина, стик, стрелки/WASD или мышь; A / Enter / клик — шаг Гаррета.
## Наборы графики переключаются, чтобы сравнить генераторы на одном экране (стиль-тест).

signal moved(cell: Vector2i)

const W := 6
const H := 4
const SCALE := 2
const OBSTACLES := [Vector2i(2, 0), Vector2i(4, 2), Vector2i(1, 3)]

# Наборы графики. anchor — точка картинки, которая встаёт в центр клетки.
const ART_SETS := [
	{
		"name": "ART_PIXELLAB",
		"floor": {"path": "res://art/pixellab/floor.png", "anchor": Vector2(32, 38)},
		"timber": {"path": "res://art/pixellab/timber.png", "anchor": Vector2(32, 80)},
		"hero": {"dir": "res://art/pixellab/garret/", "anchor": Vector2(32, 56)},
	},
	{
		"name": "ART_RD",
		"floor": {"path": "res://art/rd/floor.png", "anchor": Vector2(32, 32)},
		"timber": {"path": "res://art/rd/timber.png", "anchor": Vector2(32, 84)},
		"hero": {"path": "res://art/rd/garret.png", "anchor": Vector2(37, 62)},
	},
	{
		"name": "ART_MIXED",
		"floor": {"path": "res://art/rd/floor.png", "anchor": Vector2(32, 32)},
		"timber": {"path": "res://art/rd/timber.png", "anchor": Vector2(32, 84)},
		"hero": {"dir": "res://art/pixellab/garret/", "anchor": Vector2(32, 56)},
	},
]

var art_index := 0
var cursor := Vector2i(1, 1)
var hero := Vector2i(0, 1)
var facing := "south-east"
var _hero_draw_pos := Vector2.ZERO
var _tex := {}


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Высокие предметы верхнего ряда могут заходить за верх области: обрезку не включаем.
	custom_minimum_size = Vector2((W + H) * 32 * SCALE, (W + H) * 16 * SCALE + 24 * SCALE)
	_hero_draw_pos = cell_to_local(hero)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(_on_resized)


func _on_resized() -> void:
	_hero_draw_pos = cell_to_local(hero)
	queue_redraw()


func art_name() -> String:
	return ART_SETS[art_index]["name"]


func next_art() -> void:
	art_index = (art_index + 1) % ART_SETS.size()
	queue_redraw()


func origin() -> Vector2:
	# Сетка по центру области, чуть ниже середины: сверху место под высокие предметы.
	var grid_w := (W + H) * 32 * SCALE
	var grid_h := (W + H) * 16 * SCALE
	return Vector2((size.x - grid_w) / 2.0 + H * 32 * SCALE, maxf((size.y - grid_h) / 2.0 + 20.0 * SCALE, 24.0 * SCALE))


func cell_to_local(c: Vector2i) -> Vector2:
	return origin() + Vector2((c.x - c.y) * 32, (c.x + c.y) * 16 + 16) * SCALE


func local_to_cell(p: Vector2) -> Vector2i:
	var q := (p - origin()) / SCALE - Vector2(0, 16)
	var fx := (q.x / 32.0 + q.y / 16.0) / 2.0
	var fy := (q.y / 16.0 - q.x / 32.0) / 2.0
	return Vector2i(roundi(fx), roundi(fy))


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func is_free(c: Vector2i) -> bool:
	return in_bounds(c) and not OBSTACLES.has(c) and c != hero


func _texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


func _draw_sprite(spec: Dictionary, path: String, at: Vector2, flip := false) -> void:
	var tex := _texture(path)
	if tex == null:
		return
	var pos: Vector2 = at - spec["anchor"] * SCALE
	var rect := Rect2(pos, tex.get_size() * SCALE)
	if flip:
		draw_set_transform(Vector2(rect.position.x * 2 + rect.size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(tex, rect, false)
	if flip:
		draw_set_transform(Vector2.ZERO)


func _hero_path(spec: Dictionary) -> Array:
	if spec.has("path"):
		# У Retro Diffusion один ракурс: отражаем для взгляда влево.
		return [spec["path"], facing.ends_with("west")]
	return [spec["dir"] + facing + ".png", false]


func _draw() -> void:
	var art: Dictionary = ART_SETS[art_index]
	for y in H:
		for x in W:
			_draw_sprite(art["floor"], art["floor"]["path"], cell_to_local(Vector2i(x, y)))
	# Курсор: контур ромба поверх пола.
	var c := cell_to_local(cursor)
	var pts := PackedVector2Array([c + Vector2(0, -16) * SCALE, c + Vector2(32, 0) * SCALE, c + Vector2(0, 16) * SCALE, c + Vector2(-32, 0) * SCALE, c + Vector2(0, -16) * SCALE])
	var col := Color("#f9c22b") if has_focus() else Color("#9babb2")
	draw_polyline(pts, col, 2.0 * SCALE)
	if not is_free(cursor) and cursor != hero:
		draw_line(c + Vector2(-8, -4) * SCALE, c + Vector2(8, 4) * SCALE, Color("#e83b3b"), 2.0 * SCALE)
	# Предметы по глубине x + y.
	var items := []
	for o in OBSTACLES:
		items.append([o.x + o.y, "timber", cell_to_local(o)])
	items.append([hero.x + hero.y + 0.5, "hero", _hero_draw_pos])
	items.sort_custom(func(a, b): return a[0] < b[0])
	for it in items:
		if it[1] == "timber":
			_draw_sprite(art["timber"], art["timber"]["path"], it[2])
		else:
			var hp := _hero_path(art["hero"])
			_draw_sprite(art["hero"], hp[0], it[2], hp[1])


func move_cursor(d: Vector2i) -> void:
	var n := cursor + d
	if in_bounds(n):
		cursor = n
		queue_redraw()


func step_hero_to_cursor() -> bool:
	if not is_free(cursor):
		return false
	var d := cursor - hero
	facing = _dir_name(Vector2(d))
	hero = cursor
	var tw := create_tween()
	tw.tween_method(func(p: Vector2): _hero_draw_pos = p; queue_redraw(), _hero_draw_pos, cell_to_local(hero), 0.18)
	moved.emit(hero)
	return true


static func _dir_name(d: Vector2) -> String:
	# Направление в экранных осях: +x клетки — вниз-вправо, +y — вниз-влево.
	var screen := Vector2(d.x - d.y, (d.x + d.y) * 0.5)
	var names := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
	var a := fposmod(screen.angle(), TAU)
	return names[int(round(a / (TAU / 8))) % 8]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var c := local_to_cell(event.position)
		if in_bounds(c) and c != cursor:
			cursor = c
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		var c := local_to_cell(event.position)
		if in_bounds(c):
			cursor = c
			step_hero_to_cursor()
		accept_event()
	elif event.is_action_pressed("ui_up", true):
		move_cursor(Vector2i(0, -1)); accept_event()
	elif event.is_action_pressed("ui_down", true):
		move_cursor(Vector2i(0, 1)); accept_event()
	elif event.is_action_pressed("ui_left", true):
		move_cursor(Vector2i(-1, 0)); accept_event()
	elif event.is_action_pressed("ui_right", true):
		move_cursor(Vector2i(1, 0)); accept_event()
	elif event.is_action_pressed("ui_accept"):
		step_hero_to_cursor(); accept_event()
