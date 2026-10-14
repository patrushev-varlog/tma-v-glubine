class_name LocationMap
extends RefCounted
## Карта локации без сцены: клетки, объекты, проходимость и пути (AStarGrid2D).
## Данные — data/locations/<id>.json, формат в docs/LOCATIONS.md. Вид — LocationView,
## управление и связь с историей — экран локации (scripts/location/location_screen.gd).
##
## Клетки в координатах карты изометрии «ромбом вниз»: x растёт вправо-вниз, y — влево-вниз.

const DIR := "res://data/locations/"

var id := ""
var size := Vector2i.ZERO
## Пол: клетка → тип пола ("grass", "road", …); "" — пустота за краем карты.
var ground := {}
## Объекты текущего варианта, видимые сейчас: {"id", "kind", "cell": Vector2i, "size": Vector2i, …}.
var objects: Array[Dictionary] = []
## Вариант карты для текущей сцены ("night", "morning") и его настройки.
var variant := ""
var variant_data := {}
var astar := AStarGrid2D.new()

var _data := {}


## Какая локация у сцены истории: id или "", если сцена идёт без карты.
static func for_scene(scene: String) -> String:
	if scene == "":
		return ""
	var index: Dictionary = _json(DIR + "index.json")
	return String(index.get("scenes", {}).get(scene, ""))


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func load_location(location_id: String) -> LocationMap:
	var m := LocationMap.new()
	m._data = _json(DIR + location_id + ".json")
	assert(not m._data.is_empty(), "Нет локации " + location_id)
	m.id = location_id
	m.size = _vec(m._data.size)
	var legend: Dictionary = m._data.legend
	var rows: Array = m._data.ground
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			var t := String(legend.get(row[x], ""))
			if t != "":
				m.ground[Vector2i(x, y)] = t
	m._add_walls()
	return m


## Стены штреков (поле wall): на каждой клетке со знаком char — куб скалы, рисунок по клетке из sprites.
## Объекты стен идут первыми, чтобы остальные объекты карты были «верхними» при выборе по клетке.
func _add_walls() -> void:
	var wall: Dictionary = _data.get("wall", {})
	if wall.is_empty():
		return
	var sprites: Array = wall.sprites
	var walls: Array = []
	var rows: Array = _data.ground
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row[x] != String(wall.char):
				continue
			var w := {"id": "wall_%d_%d" % [x, y], "kind": "box", "cell": [x, y], "height": 32, "color": "#3e3b4a", "top": "#57536a"}
			# Ближняя к камере стена (пол за ней) — низкий уступ без рисунка, иначе закроет героя и объекты.
			var front := false
			for d in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
				var c: Vector2i = Vector2i(x, y) + d
				front = front or (ground.has(c) and _is_floor(c))
			if front:
				w.height = 8
			else:
				w["sprite"] = String(sprites[(((x * 73856093) ^ (y * 19349663)) & 0xffff) % sprites.size()])
			walls.append(w)
	walls.append_array(_data.objects)
	_data.objects = walls


func _is_floor(c: Vector2i) -> bool:
	return String(_data.ground[c.y])[c.x] != String(_data.wall.char)


## Настройки сцены на этой карте: {"variant", "spawn": [x, y], …}.
func scene_setup(scene: String) -> Dictionary:
	return _data.get("scenes", {}).get(scene, {})


func spawn_of(scene: String) -> Vector2i:
	return _vec(scene_setup(scene).get("spawn", [0, 0]))


## Собрать объекты и проходимость для сцены. check(условие) отвечает на условия видимости
## объектов ("buried_neighbors", "!won:prologue_1"); без него видны все объекты варианта.
func setup_scene(scene: String, check: Callable = Callable()) -> void:
	variant = String(scene_setup(scene).get("variant", ""))
	variant_data = _data.get("variants", {}).get(variant, {})
	var swap: Dictionary = variant_data.get("ground_swap", {})
	for c in ground:
		var base := String(_base_ground(c))
		ground[c] = String(swap.get(base, base))
	objects.clear()
	for o in _data.objects:
		var vs: Array = o.get("variants", [])
		if not vs.is_empty() and not vs.has(variant):
			continue
		var cond := String(o.get("if", ""))
		if cond != "" and check.is_valid() and not bool(check.call(cond)):
			continue
		var obj: Dictionary = o.duplicate(true)
		obj["cell"] = _vec(o.cell)
		obj["size"] = _vec(o.get("size", [1, 1]))
		obj["kind"] = String(o.get("kind", "box"))
		obj["solid"] = bool(o.get("solid", obj.kind != "decal"))
		var looks: Dictionary = o.get("looks", {})
		if looks.has(variant):
			obj.merge(looks[variant], true)
		objects.append(obj)
	_build_astar()


func _base_ground(c: Vector2i) -> String:
	var row := String(_data.ground[c.y])
	return String(_data.legend.get(row[c.x], ""))


func _build_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, size)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for x in size.x:
		for y in size.y:
			var c := Vector2i(x, y)
			if not ground.has(c) or String(ground[c]) in variant_data.get("blocked_ground", _data.get("blocked_ground", [])):
				astar.set_point_solid(c, true)
	for o in objects:
		if o.solid:
			for c in cells_of(o):
				if astar.is_in_boundsv(c):
					astar.set_point_solid(c, true)


## Истинна ли переменная Ink для условия: true, не ноль, непустая строка.
static func truthy(v: Variant) -> bool:
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return v != 0
		TYPE_STRING, TYPE_STRING_NAME:
			return String(v) != ""
	return true


static func _vec(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


# --- Запросы ---------------------------------------------------------------------

func cells_of(obj: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in obj.size.x:
		for dy in obj.size.y:
			out.append(obj.cell + Vector2i(dx, dy))
	return out


func object(obj_id: String) -> Dictionary:
	for o in objects:
		if o.id == obj_id:
			return o
	return {}


## Объект, который занимает клетку (верхний по порядку в данных), или {}.
func object_at(c: Vector2i) -> Dictionary:
	for i in range(objects.size() - 1, -1, -1):
		if cells_of(objects[i]).has(c):
			return objects[i]
	return {}


func walkable(c: Vector2i) -> bool:
	return astar.is_in_boundsv(c) and not astar.is_point_solid(c)


## Клетки, с которых объект можно осмотреть: сам объект, если по нему можно ходить, и проходимые
## соседи по восьми направлениям.
func reach_cells(obj: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in cells_of(obj):
		if walkable(c) and not out.has(c):
			out.append(c)
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				var n: Vector2i = c + Vector2i(dx, dy)
				if walkable(n) and not out.has(n):
					out.append(n)
	return out


func can_reach_from(obj: Dictionary, c: Vector2i) -> bool:
	return reach_cells(obj).has(c)


## Путь по клеткам от from до to включительно (без from); пусто, если не дойти.
func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if from == to or not walkable(to) or not astar.is_in_boundsv(from):
		return out
	var was_solid := astar.is_point_solid(from)
	astar.set_point_solid(from, false)
	var pts := astar.get_id_path(from, to)
	astar.set_point_solid(from, was_solid)
	for i in range(1, pts.size()):
		out.append(pts[i])
	return out


## Кратчайший путь к месту, откуда объект можно осмотреть. Если герой уже там — пустой путь и ok.
func path_to_object(from: Vector2i, obj: Dictionary) -> Dictionary:
	var reach := reach_cells(obj)
	if reach.has(from):
		return {"ok": true, "path": [] as Array[Vector2i]}
	var best: Array[Vector2i] = []
	for c in reach:
		var p := path(from, c)
		if not p.is_empty() and (best.is_empty() or p.size() < best.size()):
			best = p
	return {"ok": not best.is_empty(), "path": best}
