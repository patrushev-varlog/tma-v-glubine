class_name BoardView
extends Node2D
## Поле боя в изометрии: клетки 64×32, подсветка ходов и целей, участники.
## Графика пролога (K3) — тайлы пола и объекты по battles.json "ground", анимированные листы персонажей
## и эффекты (UnitArt). Чего нет в art/, рисуется заглушкой из фигур, как в сером прототипе
## (prototypes/combat/scripts/view/board_view.gd). Анимации идут по событиям боя (feed): шаги, удар
## или заклинание, попадание, выбывание; правила боя от них не зависят.

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
const C_HOVER := Color(1, 1, 1, 0.45)
const C_CURSOR := Color("#f9c22b")
const C_SPAWN := Color(0.95, 0.35, 0.3, 0.55)
const C_SPIKES := Color(0.75, 0.7, 0.65, 0.8)
const C_WEB := Color(0.9, 0.9, 0.95, 0.6)
const C_GREASE := Color(0.85, 0.75, 0.2, 0.55)
## Пол боёв пролога по battles.json "ground": [клетка, соседняя клетка, кромка]. Заглушки до тайлов (поток K3).
const GROUNDS := {
	"yard": [Color("#4a4034"), Color("#453b30"), Color("#5a4e40")],
	"temple": [Color("#46464c"), Color("#404046"), Color("#55555c")],
	"ford": [Color("#3c4a34"), Color("#38452f"), Color("#4a5a40")],
	"camp": [Color("#2f3a30"), Color("#2b352c"), Color("#3b483b")],
	"gate": [Color("#3d3a37"), Color("#38352f"), Color("#4b4743")],
	"flooded": [Color("#363a42"), Color("#31353c"), Color("#454a54")],
	"flooded_shrine": [Color("#363a42"), Color("#31353c"), Color("#454a54")],
	"dwarf": [Color("#4a4640"), Color("#45413b"), Color("#59544c")],
	"dwarf_archive": [Color("#4a4640"), Color("#45413b"), Color("#59544c")],
	"dwarf_seal": [Color("#44424a"), Color("#3f3d44"), Color("#54525c")],
}
## Пол, по которому можно ходить (знаки , : ;).
const FLOOR_DECOR := {"ford": Color("#4b6b78"), "road": Color("#5a5040"), "ash": Color("#2a2826"), "wade": Color("#263a4a")}
## Препятствия по виду: [цвет, высота, отступ от края клетки]. Высота 0 — плоское (вода).
const OBSTACLE_LOOK := {
	"wall": [Color("#5d564c"), 18.0, 3.0], "pillar": [Color("#7a7670"), 30.0, 9.0], "pew": [Color("#6b4f35"), 8.0, 5.0],
	"altar": [Color("#8a8170"), 12.0, 3.0], "rubble": [Color("#5f5a52"), 6.0, 6.0], "tree": [Color("#2f5130"), 26.0, 5.0],
	"fence": [Color("#6e5a3e"), 10.0, 7.0], "cart": [Color("#3a2f28"), 14.0, 4.0], "well": [Color("#6a6a6a"), 12.0, 7.0],
	"fire": [Color("#d0682a"), 6.0, 9.0], "water": [Color("#2c4a5c"), 0.0, 0.0],
}

## Тайлы карт пролога по "ground": пол (варианты по клеткам), пол по знакам , : ; и вода,
## объекты по виду препятствия. spans — виды, которые рисуются одним объектом на всю связную группу клеток
## (дом, телега, скамья); у остальных объект на каждой клетке.
const GROUND_ART := {
	"yard": {"floor": ["village_night/floor_grass"], "road": "village_night/floor_path",
		"ash": "village_morning/floor_ash",
		"objects": {"wall": "village_night/house_burning", "fence": "village_night/fence", "tree": "ford/bushes",
			"cart": "village_morning/cart_abandoned", "well": "village_night/well", "fire": "ford/campfire"},
		"spans": ["wall", "cart"]},
	"temple": {"floor": ["temple/floor_flagstone", "temple/floor_flagstone", "temple/floor_flagstone",
			"temple/floor_flagstone", "temple/floor_flagstone", "temple/floor_debris"],
		"objects": {"pillar": "temple/column", "pew": "temple/pew", "altar": "temple/altar", "rubble": "temple/roof_debris"},
		"spans": ["pew"]},
	"ford": {"floor": ["ford/floor_grass"], "ford": "ford/water_shallow", "water": "ford/water_deep",
		"objects": {"tree": "ford/bushes", "fire": "ford/campfire", "rubble": "ford/boulder"}, "tall_tree": "ford/willow"},
	"camp": {"floor": ["gate/floor_mud", "gate/floor_mud", "gate/floor_mud", "gate/floor_straw"], "road": "gate/floor_cobble",
		"objects": {"tree": "ford/bushes", "cart": "gate/prison_cart", "fire": "gate/campfire", "rubble": "gate/crates"},
		"spans": ["cart", "fire"]},
	"gate": {"floor": ["gate/floor_mud", "gate/floor_mud", "gate/floor_mud", "gate/floor_mud", "gate/floor_puddle"],
		"road": "gate/floor_cobble",
		"objects": {"wall": "gate/palisade", "pillar": "gate/gatepost", "cart": "gate/prison_cart", "rubble": "gate/boulder",
			"tree": "ford/bushes"},
		"spans": ["cart"]},
	# Шахты главы 1: рельсы по знаку дороги (вдоль x — floor_rails, вдоль y — road_b), нары — знак скамьи.
	"mine": {"floor": ["mines/floor_stone", "mines/floor_stone", "mines/floor_stone", "mines/floor_gravel", "mines/floor_ore"],
		"road": "mines/floor_rails", "road_b": "mines/floor_rails_b",
		"objects": {"wall": "mines/rock_block", "pillar": "mines/timber_support", "rubble": "mines/rockfall", "cart": "mines/minecart", "fence": "mines/bars",
			"pew": "mines/bunk", "altar": "mines/winch", "well": "mines/shaft", "tree": "mines/ore_heap"}},
	# Затопленные выработки главы 2: пол шахты и мокрый камень, вода по пояс — знак -, глубокая — ~.
	# Помост насосной — знак дороги, трубы — забор, ящики — обломки, конторка Ренны — алтарь.
	"flooded": {"floor": ["mines/floor_stone", "mines/floor_stone", "flooded/floor_wet", "mines/floor_gravel"],
		"wade": "flooded/floor_wade", "water": "flooded/floor_deep", "road": "mines/floor_planks",
		"objects": {"wall": "mines/rock_block", "pillar": "mines/timber_support", "rubble": "flooded/crates", "cart": "flooded/pump_wheel",
			"fence": "flooded/pipes", "pew": "mines/bunk", "altar": "flooded/smuggler_desk", "well": "flooded/sluice_gate", "tree": "mines/rockfall"},
		"spans": ["cart"]},
	# Затопленная часовня охоты главы 2: скамьи и алтарь из храма пролога.
	"flooded_shrine": {"floor": ["flooded/floor_wet", "flooded/floor_wet", "mines/floor_stone"], "wade": "flooded/floor_wade",
		"objects": {"wall": "mines/rock_block", "pillar": "mines/timber_support", "pew": "temple/pew", "altar": "flooded/shrine_altar",
			"rubble": "mines/rockfall"},
		"spans": ["pew"]},
}
## Верх ромба у тайла пола 64×64: центр клетки приходится на (32, 38).
const FLOOR_OFFSET := Vector2(-32, -38)
## Ноги персонажа — чуть ниже центра клетки, как на пробных сценах графики (art/tools/scene_preview.py).
const FOOT_Y := 4.0
const STEP_TIME := 0.14
## Насколько скрыт в воде по пояс персонаж: столько пикселей рисунка над ступнями не видно.
const WADE_SINK := 13.0
const IMPACT_AT := 0.28
const FX_FPS := 12.0
## Эффекты умений: proj — снаряд от применившего к клетке, hit — на клетке цели, self — на себе,
## cell — на выбранной клетке, ground_self — у земли вокруг применившего.
const ABILITY_FX := {
	"fire_bolt": {"proj": "fire_bolt", "hit": "fire_hit"}, "magic_missile": {"proj": "magic_missile", "hit": "hit_spark"},
	"sacred_flame": {"hit": "sacred_flame"}, "healing_word": {"hit": "healing_word"},
	"shield_of_faith": {"hit": "shield_of_faith"}, "thunderwave": {"ground_self": "thunderwave"},
	"hallowed_ground": {"cell": "hallowed_ground"}, "second_wind": {"self": "second_wind"}, "taunt": {"self": "taunt"},
	"disengage": {"self": "dust_trail"}, "shove": {"hit": "dust_puff"}, "trip": {"hit": "dust_puff"},
}
## Стрелки: чем стреляют на расстоянии.
const RANGED_PROJ := {"crossbowman": "bolt", "skeleton_archer": "arrow", "bone_archer": "arrow"}

var battle: Battle
## Созданный герой (класс и пол) — по нему выбирается лист героя.
var hero := {}
var reach_cells: Array[Vector2i] = []
var target_cells: Array[Vector2i] = []
var target_is_ally := false
var area_cells: Array[Vector2i] = []
var path: Array[Vector2i] = []
## Клетка, выбранная первым тапом (ждёт подтверждения).
var pending_cell := Vector2i(-1, -1)
## Клетка под мышью.
var hover_cell := Vector2i(-1, -1)
## Курсор клавиатуры и геймпада; (-1, -1) — скрыт.
var cursor_cell := Vector2i(-1, -1)
## Выходы ближайшего подкрепления: где через раунд появятся враги.
var spawn_cells: Array[Vector2i] = []
## Часы анимаций (секунды с начала боя на экране).
var _clock := 0.0
## Анимации участников: id → {"steps": [{from, to, t0, push}], "anim", "t0", "busy", "face", "hit_t", "down_t"}.
var _anim := {}
## Эффекты на поле: [{id, from, to, t0, dur, proj}].
var _fx: Array[Dictionary] = []
## Отложенные всплывающие надписи: [{t, cell, text, color}].
var _popups: Array[Dictionary] = []
## Отложенные звуки (Sound.sfx), в такт анимациям: [{t, id}].
var _sounds: Array[Dictionary] = []
## Объекты на группу клеток: передняя клетка группы → [тайл, нижняя точка в мире]; прочие клетки группы — в _span_skip.
var _spans := {}
var _span_skip := {}
var _art_ground := "-"


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


func _outline(c: Vector2i, color: Color, width: float, inset := 1.0) -> void:
	var d := _diamond(c, inset)
	d.append(d[0])
	draw_polyline(d, color, width)


func _draw() -> void:
	if battle == null:
		return
	var floor: Array = GROUNDS.get(battle.ground, [C_FLOOR, C_FLOOR_ALT, C_EDGE])
	if _art_ground != battle.ground:
		_build_spans()
	# Тайлы пола — от дальних к ближним: у тайла есть боковина, ближний перекрывает её у дальнего.
	for s in battle.width + battle.height - 1:
		for x in range(maxi(0, s - battle.height + 1), mini(s, battle.width - 1) + 1):
			var c := Vector2i(x, s - x)
			var tile := _floor_tile(c)
			if tile != null:
				draw_texture(tile, cell_to_world(c) + FLOOR_OFFSET)
				continue
			var kind := String(battle.decor.get(c, ""))
			var col: Color = floor[0] if (c.x + c.y) % 2 == 0 else floor[1]
			if FLOOR_DECOR.has(kind):
				col = FLOOR_DECOR[kind]
			elif kind == "water":
				col = OBSTACLE_LOOK.water[0]
			draw_colored_polygon(_diamond(c), col)
	# Сетка поверх пола: на тайлах тонко, чтобы клетки читались, но не спорили с рисунком.
	var grid: Color = Color(0, 0, 0, 0.16) if GROUND_ART.has(battle.ground) else floor[2]
	for x in battle.width:
		for y in battle.height:
			_outline(Vector2i(x, y), grid, 1.0, 0.0)
	for c in battle.decor:
		if battle.decor[c] == "fire":
			var flicker := 1.0 + 0.06 * sin(_clock * 9.0 + c.x * 1.7)
			draw_set_transform(cell_to_world(c), 0.0, Vector2(1.0, 0.5) * flicker)
			draw_circle(Vector2.ZERO, 52.0, Color(1.0, 0.55, 0.2, 0.08))
			draw_circle(Vector2.ZERO, 32.0, Color(1.0, 0.6, 0.25, 0.10))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for c in battle.zones.grease:
		draw_colored_polygon(_diamond(c, 1), C_GREASE)
	for c in battle.zones.spikes:
		var p0 := cell_to_world(c)
		for k in 3:
			var x := -10.0 + k * 10.0
			draw_line(p0 + Vector2(x - 3, 3), p0 + Vector2(x, -5), C_SPIKES, 1.5)
			draw_line(p0 + Vector2(x, -5), p0 + Vector2(x + 3, 3), C_SPIKES, 1.5)
	for c in battle.zones.web:
		var w := _diamond(c, 3)
		draw_line(w[0], w[2], C_WEB, 1.5)
		draw_line(w[1], w[3], C_WEB, 1.5)
		w.append(w[0])
		draw_polyline(w, C_WEB, 1.5)
	for c in spawn_cells:
		_outline(c, C_SPAWN, 2.0, 3.0)
	for c in reach_cells:
		draw_colored_polygon(_diamond(c, 2), C_REACH)
	for c in target_cells:
		draw_colored_polygon(_diamond(c, 2), C_ALLY_TARGET if target_is_ally else C_TARGET)
	for c in area_cells:
		draw_colored_polygon(_diamond(c, 4), C_AREA)
	for t in battle.zones.trap:
		var p := cell_to_world(t)
		draw_line(p + Vector2(-8, -4), p + Vector2(8, 4), Color("#d9c36a"), 2.0)
		draw_line(p + Vector2(-8, 4), p + Vector2(8, -4), Color("#d9c36a"), 2.0)
	if not path.is_empty() and battle.outcome == "":
		var pts := PackedVector2Array([cell_to_world(battle.current().cell)])
		for c in path:
			pts.append(cell_to_world(c))
		draw_polyline(pts, C_PATH, 3.0)
	if battle.in_bounds(hover_cell):
		_outline(hover_cell, C_HOVER, 1.5)
	if battle.in_bounds(cursor_cell):
		_outline(cursor_cell, C_CURSOR, 2.5)
	if pending_cell.x >= 0:
		_outline(pending_cell, C_PENDING, 2.5)
	# Препятствия и участники — по глубине, чтобы ближние перекрывали дальних.
	var by_depth := {}
	for o in battle.obstacles:
		if battle.decor.get(o, "") != "water" and not _span_skip.has(o):
			by_depth.get_or_add(o.x + o.y, []).append(o)
	for u in battle.units:
		# Павший враг ещё немного виден: падает и тает.
		if not u.dead or _clock < float(_anim.get(u.id, {}).get("down_t", -10.0)) + 1.6:
			var dc := _draw_cell(u)
			by_depth.get_or_add(dc.x + dc.y, []).append(u)
	var depths := by_depth.keys()
	depths.sort()
	for depth in depths:
		for item in by_depth[depth]:
			if item is Vector2i:
				_draw_obstacle(item)
			else:
				_draw_unit(item)
	_draw_fx()


func _draw_obstacle(c: Vector2i) -> void:
	if _spans.has(c):
		var sp: Array = _spans[c]
		_draw_object(sp[0], sp[1])
		return
	var obj := _object_tile(c)
	if obj != "" and UnitArt.tile(obj) != null:
		_draw_object(obj, cell_to_world(c) + Vector2(0, 2))
		return
	var look: Array = OBSTACLE_LOOK.get(String(battle.decor.get(c, "wall")), OBSTACLE_LOOK.wall)
	var base: Color = look[0]
	var top := _diamond(c, look[2])
	var lift := Vector2(0, -float(look[1]))
	var left := PackedVector2Array([top[3], top[2], top[2] + lift, top[3] + lift])
	var right := PackedVector2Array([top[2], top[1], top[1] + lift, top[2] + lift])
	draw_colored_polygon(left, base.darkened(0.2))
	draw_colored_polygon(right, base)
	var lifted := PackedVector2Array()
	for v in top:
		lifted.append(v + lift)
	draw_colored_polygon(lifted, base.lightened(0.18) if battle.decor.has(c) else C_OBSTACLE_TOP)


func _process(delta: float) -> void:
	_clock += delta
	var i := 0
	while i < _popups.size():
		var p: Dictionary = _popups[i]
		if p.t <= _clock:
			popup(p.cell, p.text, p.color)
			_popups.remove_at(i)
		else:
			i += 1
	i = 0
	while i < _sounds.size():
		if float(_sounds[i].t) <= _clock:
			Sound.sfx(String(_sounds[i].id))
			_sounds.remove_at(i)
		else:
			i += 1
	_fx = _fx.filter(func(f: Dictionary) -> bool: return _clock < float(f.t0) + float(f.dur))
	for st in _anim.values():
		while not st.steps.is_empty() and _clock >= float(st.steps[0].t0) + STEP_TIME:
			st.steps.pop_front()
	queue_redraw()


# --- Анимации по событиям боя ---------------------------------------------

## События из Battle.take_events(): шаги, удары и заклинания, попадания, промахи, лечение, выбывание.
## Всё раскладывается по времени: сначала шаги, потом замах, на середине замаха — попадание и цифры.
func feed(events: Array) -> void:
	var impact := -1.0
	var weapon_blow := false
	var hit_sound := ""
	for ev in events:
		var u := battle.get_unit(String(ev.unit))
		if u == null:
			continue
		var st := _state(u)
		var now := maxf(_clock, float(st.busy))
		match String(ev.type):
			"step":
				st.steps.append({"from": ev.from, "to": ev.to, "t0": now, "push": ev.get("push", false)})
				st.busy = now + STEP_TIME
				if not ev.get("push", false):
					st.face = Vector2i(ev.to) - Vector2i(ev.from)
			"act":
				var info := UnitArt.unit(UnitArt.sprite_for(u, hero))
				var anim := String(ev.anim)
				if ev.get("self", false) and not info.is_empty() and not info.anims.has("cast"):
					anim = ""
				var cell := Vector2i(ev.cell)
				if cell != u.cell:
					st.face = cell - u.cell
				st.anim = anim
				st.t0 = now
				st.busy = now + maxf(UnitArt.anim_length(info, anim) if not info.is_empty() and anim != "" else 0.3, 0.3)
				impact = now + IMPACT_AT
				var aid := String(ev.aid)
				weapon_blow = aid == ""
				var wid := String(u.weapon.get("id", ""))
				if weapon_blow and Battle.dist(u.cell, cell) > 1 and not u.ranged_weapon.is_empty():
					wid = String(u.ranged_weapon.get("id", wid))
				var table := "weapons" if weapon_blow else "abilities"
				var key := wid if weapon_blow else aid
				_sound(Sound.sfx_id(table, key, 0), now)
				hit_sound = Sound.sfx_id(table, key, 1)
				if weapon_blow and u.undead and u.kind in ["zombie", "raised", "drowned", "ghoul"] and randf() < 0.4:
					_sound("undead_groan", now)
				var fxd: Dictionary = ABILITY_FX.get(aid, {})
				var proj := String(fxd.get("proj", ""))
				if proj == "" and weapon_blow and RANGED_PROJ.has(u.kind) and Battle.dist(u.cell, cell) > 1:
					proj = RANGED_PROJ[u.kind]
				if proj != "":
					var a := cell_to_world(u.cell) + Vector2(0, -26)
					var b := cell_to_world(cell) + Vector2(0, -26)
					var flight := clampf(a.distance_to(b) / 420.0, 0.12, 0.45)
					_fx.append({"id": proj, "from": a, "to": b, "t0": impact, "dur": flight, "proj": true})
					impact += flight
				if fxd.has("hit"):
					_add_fx(String(fxd.hit), cell_to_world(cell) + Vector2(0, -24), impact)
				if fxd.has("cell"):
					_add_fx(String(fxd.cell), cell_to_world(cell) + Vector2(0, -12), impact)
				if fxd.has("self"):
					_add_fx(String(fxd.self), cell_to_world(u.cell) + Vector2(0, -28), now + 0.1)
				if fxd.has("ground_self"):
					_add_fx(String(fxd.ground_self), cell_to_world(u.cell) + Vector2(0, -16), impact)
			"damage", "miss", "heal":
				var t := maxf(impact, _clock)
				match String(ev.type):
					"damage":
						_popups.append({"t": t, "cell": u.cell, "text": "-%d" % int(ev.amount), "color": Color("#ff6b5a")})
						st.hit_t = t
						_sound(hit_sound, t)
						if weapon_blow and (u.kind.begins_with("skeleton") or u.kind == "bone_archer"):
							_sound("hit_bone", t)
						if weapon_blow:
							_add_fx("hit_spark", cell_to_world(u.cell) + Vector2(0, -26), t)
							_add_fx("bone_hit" if u.kind.begins_with("skeleton") or u.kind == "bone_archer" else "blood",
								cell_to_world(u.cell) + Vector2(0, -22), t + 0.05)
					"heal":
						_popups.append({"t": t, "cell": u.cell, "text": "+%d" % int(ev.amount), "color": Color("#6bff8a")})
						if weapon_blow:
							_sound("heal", t)
					"miss":
						_popups.append({"t": t, "cell": u.cell, "text": tr("BATTLE_MISS"), "color": Color("#cccccc")})
						_add_fx("miss", cell_to_world(u.cell) + Vector2(0, -30), t)
						_sound("miss", t)
			"down":
				st.down_t = maxf(impact, _clock) + 0.15
				var bony: bool = u.kind.begins_with("skeleton") or u.kind == "bone_archer"
				_sound("bones_collapse" if bony else "body_fall", float(st.down_t))
				if u.dead and u.undead and not bony:
					_sound("undead_death", float(st.down_t))
				if u.dead and u.undead:
					_add_fx("undead_death", cell_to_world(u.cell) + Vector2(0, -20), float(st.down_t) + 0.5)
			"spawn":
				_popups.append({"t": _clock, "cell": u.cell, "text": "!", "color": Color("#ff6b5a")})
				_sound("spawn", _clock)


func _sound(id: String, t: float) -> void:
	if id == "":
		return
	for s in _sounds:
		if s.id == id and absf(float(s.t) - t) < 0.05:
			return
	_sounds.append({"t": t, "id": id})


## Сколько ещё идут начатые анимации: экран боя ждёт их перед следующим ходом врага.
func busy_left() -> float:
	var t := _clock
	for st in _anim.values():
		t = maxf(t, maxf(float(st.busy), float(st.get("hit_t", -1.0)) + 0.35))
	for f in _fx:
		t = maxf(t, float(f.t0) + float(f.dur))
	for p in _popups:
		t = maxf(t, float(p.t))
	return t - _clock


func _state(u: Combatant) -> Dictionary:
	if not _anim.has(u.id):
		_anim[u.id] = {"steps": [], "anim": "", "t0": -10.0, "busy": 0.0, "face": Vector2i.ZERO,
			"phase": float(u.id.hash() % 100) / 37.0}
	return _anim[u.id]


func _add_fx(id: String, pos: Vector2, t0: float) -> void:
	var info := UnitArt.fx(id)
	if info.is_empty():
		return
	_fx.append({"id": id, "from": pos, "to": pos, "t0": t0, "dur": float(info.frames) / FX_FPS})


## Где участник сейчас на экране: во время шагов — между клетками.
func _unit_pos(u: Combatant) -> Vector2:
	var st: Dictionary = _anim.get(u.id, {})
	for step in st.get("steps", []):
		if _clock < float(step.t0):
			return cell_to_world(step.from)
		if _clock < float(step.t0) + STEP_TIME:
			return cell_to_world(step.from).lerp(cell_to_world(step.to), (_clock - float(step.t0)) / STEP_TIME)
	return cell_to_world(u.cell)


## Клетка для порядка отрисовки (ближние перекрывают дальних).
func _draw_cell(u: Combatant) -> Vector2i:
	var p := _unit_pos(u)
	return world_to_cell(p)


func _facing(u: Combatant) -> Vector2i:
	var st: Dictionary = _anim.get(u.id, {})
	for step in st.get("steps", []):
		if _clock < float(step.t0) + STEP_TIME and not step.push:
			return Vector2i(step.to) - Vector2i(step.from)
	var f: Vector2i = st.get("face", Vector2i.ZERO)
	if f != Vector2i.ZERO:
		return f
	var best: Combatant = null
	for o in battle.foes_of(u):
		if best == null or Battle.dist(u.cell, o.cell) < Battle.dist(u.cell, best.cell):
			best = o
	if best != null:
		return best.cell - u.cell
	return Vector2i(1, 0) if u.team == 0 else Vector2i(-1, 0)


# --- Карта -----------------------------------------------------------------

func _hash(c: Vector2i) -> int:
	return ((c.x * 73856093) ^ (c.y * 19349663)) & 0xffff


func _floor_tile(c: Vector2i) -> Texture2D:
	var ga: Dictionary = GROUND_ART.get(battle.ground, {})
	if ga.is_empty():
		return null
	var name := ""
	match String(battle.decor.get(c, "")):
		"ford":
			name = String(ga.get("ford", ""))
		"road":
			name = String(ga.get("road", ""))
			# Рельсы во второй оси: соседи-дороги только сверху или снизу по y.
			if ga.has("road_b") and battle.decor.get(c + Vector2i(1, 0), "") != "road" and battle.decor.get(c - Vector2i(1, 0), "") != "road":
				name = String(ga.road_b)
		"ash":
			name = String(ga.get("ash", ""))
		"wade":
			name = String(ga.get("wade", ""))
		"water":
			name = String(ga.get("water", ""))
			if name == "":
				return null
	if name == "":
		var floors: Array = ga.floor
		name = floors[_hash(c) % floors.size()]
	return UnitArt.tile(name)


func _object_tile(c: Vector2i) -> String:
	var ga: Dictionary = GROUND_ART.get(battle.ground, {})
	var kind := String(battle.decor.get(c, "wall"))
	var obj := String(ga.get("objects", {}).get(kind, ""))
	if obj == "":
		return ""
	if kind == "fence" and (battle.decor.get(c + Vector2i(1, 0), "") == "fence" or battle.decor.get(c - Vector2i(1, 0), "") == "fence"):
		obj += "_b"
	# Алтарь в ряд: по краям подсвечники.
	if kind == "altar" and battle.ground == "temple" and (battle.decor.get(c + Vector2i(1, 0), "") != "altar" or battle.decor.get(c - Vector2i(1, 0), "") != "altar"):
		obj = "temple/candelabrum"
	if kind == "tree" and ga.has("tall_tree") and _hash(c) % 3 == 0:
		obj = String(ga.tall_tree)
	return obj


## Объекты на несколько клеток (дом, телега, скамья): один рисунок на связную группу.
func _build_spans() -> void:
	_art_ground = battle.ground
	_spans.clear()
	_span_skip.clear()
	var ga: Dictionary = GROUND_ART.get(battle.ground, {})
	var kinds: Array = ga.get("spans", [])
	var seen := {}
	for c0 in battle.obstacles:
		var kind := String(battle.decor.get(c0, "wall"))
		if seen.has(c0) or not kinds.has(kind):
			continue
		var obj := String(ga.objects.get(kind, ""))
		if obj == "" or UnitArt.tile(obj) == null:
			continue
		var group: Array[Vector2i] = []
		var todo: Array[Vector2i] = [c0]
		seen[c0] = true
		while not todo.is_empty():
			var c: Vector2i = todo.pop_back()
			group.append(c)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if not seen.has(n) and battle.obstacles.has(n) and String(battle.decor.get(n, "wall")) == kind:
					seen[n] = true
					todo.append(n)
		var front := group[0]
		var center := Vector2.ZERO
		var bottom := -1e9
		for c in group:
			if c.x + c.y > front.x + front.y:
				front = c
			center += cell_to_world(c)
			bottom = maxf(bottom, cell_to_world(c).y + HALF_H)
		center /= group.size()
		var y := center.y + 2.0 if kind == "fire" else bottom - 4.0
		_spans[front] = [obj, Vector2(center.x, y)]
		for c in group:
			if c != front:
				_span_skip[c] = true


func _draw_object(name: String, bottom: Vector2) -> void:
	var tex := UnitArt.tile(name)
	var a := UnitArt.tile_anchor(name)
	var ox: float = float(a[0]) if a.size() == 2 else tex.get_width() * 0.5
	var h: float = float(a[1]) if a.size() == 2 else float(tex.get_height())
	draw_texture(tex, (bottom - Vector2(ox, h)).round())
	if name.ends_with("house_burning"):
		_draw_loop("roof_fire", bottom + Vector2(-14, -h * 0.62))
		_draw_loop("roof_fire", bottom + Vector2(22, -h * 0.5), 0.4)


## Петля эффекта на месте (огонь на крыше).
func _draw_loop(id: String, center: Vector2, phase := 0.0) -> void:
	var info := UnitArt.fx(id)
	if info.is_empty():
		return
	var size := Vector2(info.size[0], info.size[1])
	var frame := int((_clock + phase) * FX_FPS * 0.8) % int(info.frames)
	draw_texture_rect_region(UnitArt.fx_texture(id), Rect2(center - size * 0.5, size),
		Rect2(Vector2(frame * size.x, 0), size))


func _draw_fx() -> void:
	for f in _fx:
		var t := _clock - float(f.t0)
		if t < 0.0:
			continue
		var info := UnitArt.fx(String(f.id))
		var size := Vector2(info.size[0], info.size[1])
		var n := int(info.frames)
		var tex := UnitArt.fx_texture(String(f.id))
		if f.get("proj", false):
			var a: Vector2 = f.from
			var b: Vector2 = f.to
			var p := a.lerp(b, clampf(t / float(f.dur), 0.0, 1.0))
			draw_set_transform(p, (b - a).angle(), Vector2.ONE)
			draw_texture_rect_region(tex, Rect2(-size * 0.5, size), Rect2(Vector2((int(t * FX_FPS) % n) * size.x, 0), size))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var frame := mini(int(t * FX_FPS), n - 1)
			draw_texture_rect_region(tex, Rect2(Vector2(f.from) - size * 0.5, size), Rect2(Vector2(frame * size.x, 0), size))


# --- Участники ---------------------------------------------------------------

func _draw_unit(u: Combatant) -> void:
	var font := ThemeDB.fallback_font
	var base := _unit_pos(u)
	var active := battle.outcome == "" and battle.current() == u
	var st := _state(u)
	var info := UnitArt.unit(UnitArt.sprite_for(u, hero))
	var down_t := float(st.get("down_t", -10.0))
	var fallen := (u.down or u.dead) and _clock >= down_t
	var alpha := 1.0
	if u.dead:
		alpha = clampf(1.0 - (_clock - down_t - 0.9) / 0.7, 0.0, 1.0)
	draw_set_transform(base, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 14.0, Color(0, 0, 0, 0.35 * alpha))
	if active:
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 32, Color("#ffd75e"), 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var col := u.color
	if info.is_empty() and u.down:
		draw_rect(Rect2(base + Vector2(-16, -8), Vector2(32, 10)), Color("#6b6b6b"))
		draw_string(font, base + Vector2(-20, -12), u.letter, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color("#bbbbbb"))
		return
	if battle.is_hidden(u) or u.has_status("bound"):
		col.a = 0.55
	var prone := u.has_status("prone")
	var top := -60.0
	if not info.is_empty():
		top = minf(-60.0, FOOT_Y - float(info.foot[1]) + 2.0)
		_draw_sprite(u, info, st, base, fallen, prone, Color(1, 1, 1, col.a * alpha))
		if fallen:
			return
	else:
		var body := Rect2(base + Vector2(-11, -36), Vector2(22, 32))
		if prone:
			body = Rect2(base + Vector2(-17, -14), Vector2(34, 12))
		draw_rect(body, col)
		draw_rect(body, col.darkened(0.45), false, 2.0)
		if not prone:
			draw_circle(base + Vector2(0, -42), 8.0, col.lightened(0.15))
		draw_string(font, base + Vector2(-20, body.position.y - base.y + body.size.y - 9), u.letter,
			HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.BLACK)
	if u.has_status("bound"):
		draw_line(base + Vector2(-13, -24), base + Vector2(13, -16), Color("#c9b48a"), 2.0)
		draw_line(base + Vector2(-13, -16), base + Vector2(13, -24), Color("#c9b48a"), 2.0)
	var bar := Rect2(base + Vector2(-18, top), Vector2(36, 5))
	draw_rect(bar, Color(0, 0, 0, 0.6))
	var frac := float(u.hp) / u.max_hp
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), hp_color(frac))
	# Состояния — значками над полоской хитов, у кого значка нет — короткой подписью.
	var marks := PackedStringArray()
	var x := base.x - 18.0
	for sid in u.statuses:
		if sid == "bound":
			continue
		var icon := UnitArt.status_icon(sid)
		if icon != null:
			draw_texture(icon, Vector2(x, base.y + top - 18.0))
			x += 17.0
		elif sid != "prone":
			marks.append(TranslationServer.translate("STATUS_" + sid))
	if not marks.is_empty():
		var y := top - 6.0 if x == base.x - 18.0 else top - 22.0
		draw_string(font, base + Vector2(-60, y), " · ".join(marks), HORIZONTAL_ALIGNMENT_CENTER, 120, 11, Color("#bfe3ff"))


func _draw_sprite(u: Combatant, info: Dictionary, st: Dictionary, base: Vector2, fallen: bool, prone: bool,
		tint: Color) -> void:
	var anim := "idle"
	var frame := 0
	var steps: Array = st.steps
	var moving := not steps.is_empty() and _clock >= float(steps[0].t0)
	var act_len := UnitArt.anim_length(info, String(st.anim)) if String(st.anim) != "" else 0.0
	var hit_t := float(st.get("hit_t", -10.0))
	if moving:
		anim = "walk"
		frame = int((_clock - float(steps[0].t0)) * float(info.anims.walk.fps))
	elif String(st.anim) != "" and _clock >= float(st.t0) and _clock < float(st.t0) + act_len:
		anim = UnitArt.pick_anim(info, String(st.anim))
		frame = int((_clock - float(st.t0)) * float(info.anims[anim].fps))
	elif fallen or prone:
		anim = "down"
		var down_t := float(st.get("down_t", -10.0))
		frame = int((_clock - down_t) * float(info.anims.down.fps)) if fallen and down_t > 0.0 else 99
	elif _clock >= hit_t and _clock < hit_t + UnitArt.anim_length(info, "hit"):
		anim = "hit"
		frame = int((_clock - hit_t) * float(info.anims.hit.fps))
	else:
		frame = int((_clock + float(st.phase)) * float(info.anims.idle.fps))
	var a: Dictionary = info.anims[anim]
	var n := int(a.frames)
	frame = frame % n if anim == "idle" or anim == "walk" else mini(frame, n - 1)
	var f := _facing(u)
	var sx := f.x - f.y
	var sy := f.x + f.y
	var size := Vector2(info.size[0], info.size[1])
	var row := int(a.row) + (1 if sy < 0 else 0)
	var foot := Vector2(info.foot[0], info.foot[1])
	# В воде по пояс (глава 2) ноги скрыты: рисунок обрезан снизу, по линии воды — рябь.
	var sink := WADE_SINK if not fallen and not prone and String(battle.decor.get(_draw_cell(u), "")) == "wade" else 0.0
	var shown := Vector2(size.x, size.y if sink == 0.0 else foot.y - sink)
	draw_set_transform(base.round(), 0.0, Vector2(-1.0 if sx < 0 else 1.0, 1.0))
	draw_texture_rect_region(UnitArt.unit_texture(UnitArt.sprite_for(u, hero)),
		Rect2(Vector2(0, FOOT_Y) - foot, shown), Rect2(Vector2(frame * size.x, row * size.y), shown), tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if sink > 0.0:
		var wl := base.round() + Vector2(0, FOOT_Y - sink)
		var wobble := 1.0 + 0.08 * sin(_clock * 3.0 + float(u.cell.x))
		draw_set_transform(wl, 0.0, Vector2(1.0, 0.4) * wobble)
		draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 24, Color(0.75, 0.85, 0.95, 0.45 * tint.a), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func hp_color(frac: float) -> Color:
	return Color("#5fcf6b") if frac > 0.5 else (Color("#e0b44a") if frac > 0.25 else Color("#e05a4a"))


## Всплывающий текст над клеткой: урон, лечение, промах.
func popup(c: Vector2i, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_override("font", UiKit.heading_font())
	l.add_theme_font_size_override("font_size", 18)
	l.position = cell_to_world(c) + Vector2(-20, -90)
	l.z_index = 10
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 30, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)
