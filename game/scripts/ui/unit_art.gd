class_name UnitArt
extends RefCounted
## Листы анимаций персонажей и эффектов (собирает tools/import_art.py из art/): res://art/units/<id>.png
## с описанием в units.json, эффекты — res://art/fx/<id>.png и fx.json. Нет листа — поле боя рисует заглушку.

const UNITS_DIR := "res://art/units/"
const FX_DIR := "res://art/fx/"
const TILES_DIR := "res://art/tiles/"
const STATUS_ICON := "res://art/icons/status/%s.png"

static var _units := {}
static var _fx := {}
static var _tiles := {}
static var _tex := {}


static func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


## Описание листа: {"size": [w, h], "foot": [x, y], "anims": {имя: {"row", "frames", "fps"}}}; {} — листа нет.
static func unit(sprite: String) -> Dictionary:
	if _units.is_empty():
		_units = _json(UNITS_DIR + "units.json")
	if not _units.has(sprite) or texture(UNITS_DIR + sprite + ".png") == null:
		return {}
	return _units[sprite]


static func unit_texture(sprite: String) -> Texture2D:
	return texture(UNITS_DIR + sprite + ".png")


## Какой лист у участника боя. Герой — по классу и полу созданного героя, прихожане чередуются.
static func sprite_for(u: Combatant, hero := {}) -> String:
	if u.is_hero:
		var id := "hero_%s_%s" % [u.kind, "f" if bool(hero.get("hero_f", false)) else "m"]
		return id if not unit(id).is_empty() else "hero_%s_m" % u.kind
	if (u.kind == "raised" or u.kind == "prisoner") and u.id.get_slice("_", u.id.get_slice_count("_") - 1).to_int() % 2 == 0:
		return u.kind + "_f"
	return String(SPRITE_ALIAS.get(u.kind, u.kind))


## Враги без своего листа, у которых есть похожий: лучник у клети главы 1 — арбалетчик пролога.
const SPRITE_ALIAS := {"archer": "crossbowman"}


## Анимация, которая есть у листа: заклинание без своей анимации играется ударом и наоборот.
static func pick_anim(info: Dictionary, anim: String) -> String:
	var anims: Dictionary = info.get("anims", {})
	if anims.has(anim):
		return anim
	match anim:
		"cast":
			return "attack" if anims.has("attack") else "idle"
		"attack":
			return "cast" if anims.has("cast") else "idle"
	return "idle"


static func anim_length(info: Dictionary, anim: String) -> float:
	var a: Dictionary = info.anims.get(pick_anim(info, anim), {})
	return float(a.get("frames", 1)) / float(a.get("fps", 10)) if not a.is_empty() else 0.0


## Эффект: {"size": [w, h], "frames": n}; {} — нет.
static func fx(id: String) -> Dictionary:
	if _fx.is_empty():
		_fx = _json(FX_DIR + "fx.json")
	if not _fx.has(id) or texture(FX_DIR + id + ".png") == null:
		return {}
	return _fx[id]


static func fx_texture(id: String) -> Texture2D:
	return texture(FX_DIR + id + ".png")


## Тайл набора: пол 64×64 (верх ромба с 22-й строки) или объект, обрезанный по рисунку.
static func tile(name: String) -> Texture2D:
	return texture(TILES_DIR + name + ".png")


## Точка опоры объекта: [x центра клетки от левого края, высота до низа рисунка]; [] — нет.
static func tile_anchor(name: String) -> Array:
	if _tiles.is_empty():
		_tiles = _json(TILES_DIR + "tiles.json")
	return _tiles.get(name, [])


static func status_icon(sid: String) -> Texture2D:
	return texture(STATUS_ICON % sid)
