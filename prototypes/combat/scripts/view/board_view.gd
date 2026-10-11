class_name BoardView
extends Node2D
## Рисует изометрическое поле, подсветку и участников серыми фигурами.

const HALF_W := 32.0
const HALF_H := 16.0

const C_FLOOR := Color("#3a3d44")
const C_FLOOR_ALT := Color("#34373d")
const C_EDGE := Color("#4b4f58")
const C_OBSTACLE := Color("#5d564c")
const C_OBSTACLE_TOP := Color("#776e61")
const C_REACH := Color(0.35, 0.6, 0.95, 0.28)
const C_TARGET := Color(0.95, 0.4, 0.35, 0.35)
const C_ALLY_TARGET := Color(0.45, 0.9, 0.5, 0.35)
const C_AREA := Color(1.0, 0.75, 0.3, 0.4)
const C_PATH := Color(0.85, 0.92, 1.0, 0.9)
const C_PENDING := Color(1, 1, 1, 0.9)
const C_SPIKES := Color(0.75, 0.7, 0.65, 0.8)
const C_WEB := Color(0.9, 0.9, 0.95, 0.6)
const C_GREASE := Color(0.85, 0.75, 0.2, 0.55)

var battle: Battle
var reach_cells: Array[Vector2i] = []
var target_cells: Array[Vector2i] = []
var target_is_ally := false
var area_cells: Array[Vector2i] = []
var path: Array[Vector2i] = []
var pending_cell := Vector2i(-1, -1)


static func cell_to_world(c: Vector2i) -> Vector2:
	return Vector2((c.x - c.y) * HALF_W, (c.x + c.y) * HALF_H)


static func world_to_cell(p: Vector2) -> Vector2i:
	var a := p.x / HALF_W
	var b := p.y / HALF_H
	return Vector2i(roundi((a + b) / 2.0), roundi((b - a) / 2.0))


func clear_marks() -> void:
	reach_cells.clear()
	target_cells.clear()
	area_cells.clear()
	path.clear()
	pending_cell = Vector2i(-1, -1)
	queue_redraw()


func _diamond(c: Vector2i, inset := 0.0) -> PackedVector2Array:
	var p := cell_to_world(c)
	var w := HALF_W - inset * 2.0
	var h := HALF_H - inset
	return PackedVector2Array([p + Vector2(0, -h), p + Vector2(w, 0), p + Vector2(0, h), p + Vector2(-w, 0)])


func _draw() -> void:
	if battle == null:
		return
	for x in battle.width:
		for y in battle.height:
			var c := Vector2i(x, y)
			draw_colored_polygon(_diamond(c), C_FLOOR if (x + y) % 2 == 0 else C_FLOOR_ALT)
			var d := _diamond(c)
			d.append(d[0])
			draw_polyline(d, C_EDGE, 1.0)
	for c in battle.grease:
		draw_colored_polygon(_diamond(c, 1), C_GREASE)
	for c in battle.spikes:
		var p0 := cell_to_world(c)
		for k in 3:
			var x := -10.0 + k * 10.0
			draw_line(p0 + Vector2(x - 3, 3), p0 + Vector2(x, -5), C_SPIKES, 1.5)
			draw_line(p0 + Vector2(x, -5), p0 + Vector2(x + 3, 3), C_SPIKES, 1.5)
	for c in battle.webs:
		var w := _diamond(c, 3)
		draw_line(w[0], w[2], C_WEB, 1.5)
		draw_line(w[1], w[3], C_WEB, 1.5)
		w.append(w[0])
		draw_polyline(w, C_WEB, 1.5)
	for c in reach_cells:
		draw_colored_polygon(_diamond(c, 2), C_REACH)
	for c in target_cells:
		draw_colored_polygon(_diamond(c, 2), C_ALLY_TARGET if target_is_ally else C_TARGET)
	for c in area_cells:
		draw_colored_polygon(_diamond(c, 4), C_AREA)
	for t in battle.traps:
		var p := cell_to_world(t)
		draw_line(p + Vector2(-8, -4), p + Vector2(8, 4), Color("#d9c36a"), 2.0)
		draw_line(p + Vector2(-8, 4), p + Vector2(8, -4), Color("#d9c36a"), 2.0)
	if not path.is_empty():
		var pts := PackedVector2Array()
		var cur := battle.current()
		pts.append(cell_to_world(cur.cell))
		for c in path:
			pts.append(cell_to_world(c))
		draw_polyline(pts, C_PATH, 3.0)
	if pending_cell.x >= 0:
		var d2 := _diamond(pending_cell, 1)
		d2.append(d2[0])
		draw_polyline(d2, C_PENDING, 2.5)
	# Препятствия и участники — по глубине, чтобы ближние перекрывали дальних.
	var by_depth := {}
	for o in battle.obstacles:
		by_depth.get_or_add(o.x + o.y, []).append(o)
	for u in battle.units:
		if not u.dead:
			by_depth.get_or_add(u.cell.x + u.cell.y, []).append(u)
	var depths := by_depth.keys()
	depths.sort()
	for depth in depths:
		for item in by_depth[depth]:
			if item is Vector2i:
				_draw_obstacle(item)
			else:
				_draw_unit(item)


func _draw_obstacle(c: Vector2i) -> void:
	var top := _diamond(c, 3)
	var lift := Vector2(0, -18)
	var left := PackedVector2Array([top[3], top[2], top[2] + lift, top[3] + lift])
	var right := PackedVector2Array([top[2], top[1], top[1] + lift, top[2] + lift])
	draw_colored_polygon(left, C_OBSTACLE.darkened(0.2))
	draw_colored_polygon(right, C_OBSTACLE)
	var lifted := PackedVector2Array()
	for v in top:
		lifted.append(v + lift)
	draw_colored_polygon(lifted, C_OBSTACLE_TOP)


func _draw_unit(u: Combatant) -> void:
	var font := ThemeDB.fallback_font
	var base := cell_to_world(u.cell)
	var active := battle.outcome == "" and battle.current() == u
	draw_set_transform(base, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.35))
	if active:
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color("#ffd75e"), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var col := u.color
	if u.down:
		draw_rect(Rect2(base + Vector2(-16, -8), Vector2(32, 10)), Color("#6b6b6b"))
		draw_string(font, base + Vector2(-20, -12), u.letter, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color("#bbbbbb"))
		return
	if u.hidden:
		col.a = 0.5
	var body := Rect2(base + Vector2(-11, -36), Vector2(22, 32))
	if u.prone:
		body = Rect2(base + Vector2(-17, -14), Vector2(34, 12))
	draw_rect(body, col)
	draw_rect(body, col.darkened(0.45), false, 2.0)
	if not u.prone:
		draw_circle(base + Vector2(0, -42), 8.0, col.lightened(0.15))
	draw_string(font, base + Vector2(-20, body.position.y - base.y + body.size.y - 9), u.letter,
		HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.BLACK)
	var bar := Rect2(base + Vector2(-18, -60), Vector2(36, 5))
	draw_rect(bar, Color(0, 0, 0, 0.6))
	var frac := float(u.hp) / u.max_hp
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)),
		Color("#5fcf6b") if frac > 0.5 else (Color("#e0b44a") if frac > 0.25 else Color("#e05a4a")))
	if u.ac_bonus > 0:
		draw_string(font, base + Vector2(14, -44), "+2", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8d27a"))
	if u.taunted_by != "":
		draw_string(font, base + Vector2(-26, -44), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ff7a5a"))
	# Состояния значками над полоской хитов.
	var marks := []
	if u.dodging:
		marks.append("уклон")
	if u.turned:
		marks.append("бежит")
	if u.guided_by != "":
		marks.append("метка")
	if u.slowed_by != "" or u.slow_spell:
		marks.append("медл.")
	if u.restrained:
		marks.append("опутан")
	if u.stunned:
		marks.append("паралич")
	if u.raging:
		marks.append("ярость")
	if u.poisoned:
		marks.append("яд")

	if not marks.is_empty():
		draw_string(font, base + Vector2(-40, -64), " ".join(marks), HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color("#bfe3ff"))


## Всплывающий текст над клеткой: урон, лечение, промах.
func popup(c: Vector2i, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", 18)
	l.position = cell_to_world(c) + Vector2(-20, -90)
	l.z_index = 10
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 30, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)
