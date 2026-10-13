class_name LocationView
extends Node2D
## Вид карты локации: пол (TileMapLayer), объекты с сортировкой по глубине, отметки (наведение,
## путь, объекты, которые сейчас можно осмотреть) и герой. Правил тут нет: проходимость и пути —
## в LocationMap, связь с историей — в экране локации.

const PATH_COLOR := Color("#f9c22b")
const HOVER_COLOR := Color(1, 1, 1, 0.35)
const ACTIVE_COLOR := Color("#f9c22b")

var map: LocationMap
var ground: TileMapLayer
var props: Node2D
var hero: LocationWalker
## Объекты, которые сейчас можно осмотреть (по тегу #obj: у вариантов выбора): id → подпись.
var active := {}
var hover_cell := Vector2i(-1, -1)
var path_preview: Array[Vector2i] = []

var _decals: Node2D
var _marks: _Marks
var _markers: _Markers
var _tint: CanvasModulate
var _time := 0.0


func build(m: LocationMap, hero_cell: Vector2i, hero_look: Dictionary) -> void:
	map = m
	for c in get_children():
		c.queue_free()
	var types: Array = []
	for c in map.ground:
		if not types.has(map.ground[c]):
			types.append(map.ground[c])
	types.sort()
	var ts := LocationArt.ground_tileset(types)
	ground = TileMapLayer.new()
	ground.tile_set = ts.tileset
	for c in map.ground:
		ground.set_cell(c, 0, ts.coords[map.ground[c]])
	add_child(ground)

	_decals = Node2D.new()
	add_child(_decals)
	_marks = _Marks.new()
	_marks.view = self
	add_child(_marks)
	props = Node2D.new()
	props.y_sort_enabled = true
	add_child(props)
	_markers = _Markers.new()
	_markers.view = self
	_markers.z_index = 10
	add_child(_markers)

	for o in map.objects:
		_add_object(o)
	hero = LocationWalker.new()
	hero.view = self
	hero.body = Color(hero_look.get("body", "#7aa7e8"))
	hero.head = Color(hero_look.get("head", "#e6d6b8"))
	hero.place(hero_cell)
	props.add_child(hero)

	_tint = CanvasModulate.new()
	_tint.color = Color(String(map.variant_data.get("tint", "#ffffff")))
	add_child(_tint)


func cell_center(c: Vector2i) -> Vector2:
	return ground.map_to_local(c)


func cell_at(world_pos: Vector2) -> Vector2i:
	return ground.local_to_map(ground.to_local(world_pos))


## Границы карты в мировых координатах (для камеры).
func bounds() -> Rect2:
	var r := Rect2(cell_center(Vector2i.ZERO), Vector2.ZERO)
	for c in [Vector2i(map.size.x - 1, 0), Vector2i(0, map.size.y - 1), map.size - Vector2i.ONE]:
		r = r.expand(cell_center(c))
	return r.grow_individual(48, 120, 48, 48)


func set_active(objects: Dictionary) -> void:
	active = objects
	_marks.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _marks != null:
		_marks.queue_redraw()
		_markers.queue_redraw()


func _add_object(o: Dictionary) -> void:
	match String(o.kind):
		"box":
			for c in map.cells_of(o):
				var p := _BoxPiece.new()
				p.setup(self, o, c)
				props.add_child(p)
		"decal":
			for c in map.cells_of(o):
				var d := _Decal.new()
				d.setup(self, o, c)
				_decals.add_child(d)
		"fire":
			var f := _Fire.new()
			f.setup(self, o)
			props.add_child(f)
		_:
			var s := _Standing.new()
			s.setup(self, o)
			props.add_child(s)


# --- Отметки на полу: наведение, путь, объекты для осмотра ------------------------

class _Marks extends Node2D:
	var view: LocationView

	func _draw() -> void:
		var pulse := 0.55 + 0.45 * sin(view._time * 4.0)
		for id in view.active:
			var o := view.map.object(id)
			if o.is_empty():
				continue
			for c in view.map.cells_of(o):
				var pts := LocationArt.diamond(view.cell_center(c), 0.0, 0.9)
				pts.append(pts[0])
				draw_polyline(pts, Color(ACTIVE_COLOR, 0.4 + 0.5 * pulse), 2.0)
		for c in view.path_preview:
			draw_circle(view.cell_center(c), 3.0, Color(PATH_COLOR, 0.8))
		if view.map.walkable(view.hover_cell) or not view.map.object_at(view.hover_cell).is_empty():
			var pts := LocationArt.diamond(view.cell_center(view.hover_cell), 0.0, 0.96)
			draw_colored_polygon(pts, Color(HOVER_COLOR, 0.12))
			pts.append(pts[0])
			draw_polyline(pts, HOVER_COLOR, 1.0)


# --- Метки над объектами для осмотра -----------------------------------------------

class _Markers extends Node2D:
	var view: LocationView

	func _draw() -> void:
		for id in view.active:
			var o := view.map.object(id)
			if o.is_empty():
				continue
			var top := view.cell_center(o.cell + (o.size - Vector2i.ONE) / 2)
			top.y -= float(o.get("height", 30)) + 18.0 + 3.0 * sin(view._time * 3.0)
			if o.kind == "decal":
				top.y = view.cell_center(o.cell).y - 26.0 + 3.0 * sin(view._time * 3.0)
			var pts := PackedVector2Array([top + Vector2(-6, -10), top + Vector2(6, -10), top + Vector2(0, 0)])
			draw_colored_polygon(pts, ACTIVE_COLOR)
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#2e222f"), 1.0)


# --- Блок (дом, изгородь, колодец): клетка за клеткой, чтобы глубина сортировалась верно ---

class _BoxPiece extends Node2D:
	var cell: Vector2i
	var h := 30.0
	var top := Color.GRAY
	var side := Color.GRAY
	var east := false
	var south := false
	var mark := Color.TRANSPARENT

	func setup(view: LocationView, o: Dictionary, c: Vector2i) -> void:
		cell = c
		position = view.cell_center(c)
		h = float(o.get("height", 30))
		side = Color(String(o.get("color", "#8a6f4d")))
		top = Color(String(o.get("top", o.get("color", "#8a6f4d"))))
		var far: Vector2i = o.cell + o.size - Vector2i.ONE
		east = c.x == far.x
		south = c.y == far.y
		if o.has("mark") and c == far:
			mark = Color(String(o.mark))

	func _draw() -> void:
		var base := LocationArt.diamond(Vector2.ZERO)
		var raised := LocationArt.diamond(Vector2.ZERO, h)
		# Вершины: 0 — верх, 1 — право, 2 — низ, 3 — лево.
		if east:
			draw_colored_polygon(PackedVector2Array([base[1], base[2], raised[2], raised[1]]), side.darkened(0.25))
		if south:
			draw_colored_polygon(PackedVector2Array([base[2], base[3], raised[3], raised[2]]), side)
		draw_colored_polygon(raised, top)
		if mark.a > 0.0:
			# Знак короны на борту телеги.
			var c := (base[1] + base[2] + raised[1] + raised[2]) / 4.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(-5, 2), c + Vector2(-5, -4), c + Vector2(-2, -1),
				c + Vector2(0, -6), c + Vector2(2, -1), c + Vector2(5, -4), c + Vector2(5, 2)]), mark)


# --- Плоское на земле: люк погреба, бумага, колея, тела, могилы --------------------

class _Decal extends Node2D:
	var shape := ""
	var color := Color.GRAY
	var seed_value := 0

	func setup(view: LocationView, o: Dictionary, c: Vector2i) -> void:
		position = view.cell_center(c)
		shape = String(o.get("shape", ""))
		color = Color(String(o.get("color", "#4d3a2a")))
		seed_value = c.x * 31 + c.y * 17

	func _draw() -> void:
		match shape:
			"paper":
				draw_colored_polygon(PackedVector2Array([Vector2(-7, -2), Vector2(3, -6), Vector2(8, 1), Vector2(-2, 5)]), color)
				draw_line(Vector2(-3, -1), Vector2(4, -3), Color("#5b4030"), 1.0)
				draw_line(Vector2(-1, 2), Vector2(5, 0), Color("#5b4030"), 1.0)
			"ruts":
				draw_line(Vector2(-22, -5), Vector2(10, 11), color, 3.0)
				draw_line(Vector2(-10, -11), Vector2(22, 5), color, 3.0)
			"bodies":
				var a := float(seed_value % 5) * 0.3
				draw_set_transform(Vector2(-6, 0), a, Vector2(1.0, 0.45))
				draw_circle(Vector2.ZERO, 11.0, color)
				draw_set_transform(Vector2(12, 4), -a, Vector2(1.0, 0.4))
				draw_circle(Vector2.ZERO, 9.0, color.darkened(0.2))
				draw_set_transform(Vector2.ZERO)
			"graves":
				draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.5))
				draw_circle(Vector2.ZERO, 14.0, color)
				draw_set_transform(Vector2.ZERO)
				draw_line(Vector2(0, -2), Vector2(0, -16), Color("#8a7552"), 2.0)
				draw_line(Vector2(-4, -12), Vector2(4, -12), Color("#8a7552"), 2.0)
			_:
				draw_colored_polygon(LocationArt.diamond(Vector2.ZERO, 0.0, 0.6), color)
				var pts := LocationArt.diamond(Vector2.ZERO, 0.0, 0.6)
				pts.append(pts[0])
				draw_polyline(pts, color.darkened(0.4), 1.0)


# --- Стоящие: люди, мертвецы, деревья ----------------------------------------------

class _Standing extends Node2D:
	var kind := ""
	var body := Color.GRAY
	var head := Color.GRAY
	var h := 46.0

	func setup(view: LocationView, o: Dictionary) -> void:
		position = view.cell_center(o.cell)
		kind = String(o.kind)
		body = Color(String(o.get("color", "#9babb2")))
		head = Color(String(o.get("head", o.get("top", "#d8c8b0"))))
		h = float(o.get("height", 46))

	func _draw() -> void:
		if kind == "tree":
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.25))
			draw_set_transform(Vector2.ZERO)
			draw_rect(Rect2(-3, -h * 0.5, 6, h * 0.5), Color("#5b4030"))
			draw_circle(Vector2(0, -h * 0.62), 16.0, body)
			draw_circle(Vector2(-4, -h * 0.72), 9.0, head)
			return
		LocationWalker.draw_person(self, body, head)


# --- Огонь: пламя и свет ------------------------------------------------------------

class _Fire extends Node2D:
	var lift := 0.0
	var small := false
	var _t := 0.0

	func setup(view: LocationView, o: Dictionary) -> void:
		position = view.cell_center(o.cell)
		lift = float(o.get("lift", 0))
		small = bool(o.get("small", false))
		var light := PointLight2D.new()
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		g.width = 256
		g.height = 256
		g.gradient = Gradient.new()
		g.gradient.set_color(0, Color(1, 1, 1, 1))
		g.gradient.set_color(1, Color(1, 1, 1, 0))
		light.texture = g
		light.color = Color("#fb6b1d")
		light.energy = 0.9 if small else 1.4
		light.texture_scale = 0.9 if small else 2.0
		light.position = Vector2(0, -lift)
		add_child(light)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var s := 0.5 if small else 1.0
		var base := Vector2(0, -lift)
		if small:
			draw_line(Vector2.ZERO, base, Color("#5b4030"), 2.0)
		for i in 3:
			var k := float(i)
			var w := (12.0 - k * 3.0) * s
			var hh := (26.0 - k * 6.0 + 4.0 * sin(_t * 9.0 + k * 2.1)) * s
			var col: Color = [Color("#e83b3b"), Color("#fb6b1d"), Color("#f9c22b")][i]
			draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, -hh), base + Vector2(w, 0)]), col)
