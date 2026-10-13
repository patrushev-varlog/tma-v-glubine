class_name LocationWalker
extends Node2D
## Герой на карте: идёт по клеткам пути, по одной клетке за шаг. Заглушка вместо спрайта —
## фигура кодом (тень, тело, голова), цвет тела по классу героя.

signal stepped(cell: Vector2i)
signal arrived(cell: Vector2i)

const STEP_TIME := 0.17
const DIAGONAL_TIME := 0.22

var view: LocationView
var cell := Vector2i.ZERO
var body := Color("#7aa7e8")
var head := Color("#e6d6b8")
## Куда смотрит (−1 — влево, 1 — вправо): фигура отражается.
var facing := 1.0

var _path: Array[Vector2i] = []
var _tween: Tween = null


func place(c: Vector2i) -> void:
	cell = c
	_path.clear()
	if _tween != null:
		_tween.kill()
	_tween = null
	if view != null:
		position = view.cell_center(c)


func is_moving() -> bool:
	return _tween != null


## Идти по пути (клетки без текущей). Новый путь заменяет старый после текущего шага.
func walk(path: Array[Vector2i]) -> void:
	_path = path.duplicate()
	if _tween == null:
		_next_step()


func stop() -> void:
	_path.clear()


func _next_step() -> void:
	if _path.is_empty():
		_tween = null
		arrived.emit(cell)
		return
	var to: Vector2i = _path.pop_front()
	var d := to - cell
	var target := view.cell_center(to)
	if absf(target.x - position.x) > 1.0:
		facing = signf(target.x - position.x)
	cell = to
	_tween = create_tween()
	_tween.tween_property(self, "position", target, DIAGONAL_TIME if d.x != 0 and d.y != 0 else STEP_TIME)
	_tween.tween_callback(func() -> void:
		stepped.emit(cell)
		_next_step())
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	draw_person(self, body, head)
	draw_set_transform(Vector2.ZERO)


## Человек-заглушка: тень, тело, голова и тёмный край. Её же рисуют NPC на карте.
static func draw_person(ci: CanvasItem, body_color: Color, head_color: Color) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	ci.draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.3))
	ci.draw_set_transform(Vector2.ZERO)
	var outline := Color("#2e222f")
	ci.draw_rect(Rect2(-8, -30, 16, 30), outline)
	ci.draw_rect(Rect2(-7, -29, 14, 28), body_color)
	ci.draw_rect(Rect2(-7, -10, 14, 2), body_color.darkened(0.3))
	ci.draw_circle(Vector2(0, -37), 7.5, outline)
	ci.draw_circle(Vector2(0, -37), 6.5, head_color)
	ci.draw_rect(Rect2(2, -38, 2, 2), outline)
