class_name LocationArt
extends RefCounted
## Графика локации. Пока ассетов нет (поток K3), всё рисуется заглушками кодом: ромбы пола
## 64×32 с шумом, блоки домов, фигуры людей. Когда появятся тайлы, их кладут в
## res://art/locations/tiles/<тип пола>.png (64×32, центр ромба (32, 16)) — заглушка заменится сама.
## Палитра — Resurrect 64 (art/PROMPTS.md).

const TILE := Vector2i(64, 32)
const TILES_DIR := "res://art/locations/tiles/"

## Тип пола → основной цвет и цвет крапа.
const GROUND := {
	"grass": ["#4f6e3f", "#3d5c3a"],
	"grass_scorch": ["#4f6e3f", "#3d5c3a"],
	"mud": ["#6e5a3c", "#5b4030"],
	"road": ["#8a7552", "#6e5a3c"],
	"yard": ["#7a6a55", "#665844"],
	"ash": ["#4a4446", "#2e2a2a"],
	"dwarf_hall": ["#5e564c", "#4e463e"],
	"dwarf_rune": ["#5e564c", "#7a8fa0"],
	"dwarf_chasm": ["#0e0d14", "#3a4a3c"],
}


## TileSet изометрии «ромбом вниз» с тайлом на каждый тип пола. Возвращает
## {"tileset": TileSet, "coords": {тип: Vector2i в атласе}}.
static func ground_tileset(types: Array) -> Dictionary:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = TILE
	var atlas := Image.create(TILE.x * maxi(types.size(), 1), TILE.y, false, Image.FORMAT_RGBA8)
	var coords := {}
	for i in types.size():
		var t := String(types[i])
		atlas.blit_rect(_tile_image(t), Rect2i(Vector2i.ZERO, TILE), Vector2i(i * TILE.x, 0))
		coords[t] = Vector2i(i, 0)
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(atlas)
	src.texture_region_size = TILE
	for t in coords:
		src.create_tile(coords[t])
	ts.add_source(src, 0)
	return {"tileset": ts, "coords": coords}


static func _tile_image(type: String) -> Image:
	var path := TILES_DIR + type + ".png"
	if ResourceLoader.exists(path):
		var img: Image = (load(path) as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		return img
	var cols: Array = GROUND.get(type, ["#ff00ff", "#000000"])
	var base := Color(cols[0])
	var speck := Color(cols[1])
	var img := Image.create(TILE.x, TILE.y, false, Image.FORMAT_RGBA8)
	var h := type.hash()
	for y in TILE.y:
		for x in TILE.x:
			var d := absf(x - 31.5) / 32.0 + absf(y - 15.5) / 16.0
			if d > 1.0:
				continue
			var n := (x * 73856093 ^ y * 19349663 ^ h) & 0xff
			var c := base
			if n < 34:
				c = speck
			elif n > 236:
				c = base.lightened(0.08)
			# Нижние кромки ромба чуть темнее: сетка читается, но не лезет в глаза.
			if d > 0.93 and y > 15:
				c = c.darkened(0.18)
			img.set_pixel(x, y, c)
	return img


## Вершины ромба клетки вокруг центра, поднятые на lift пикселей.
static func diamond(center: Vector2, lift := 0.0, scale := 1.0) -> PackedVector2Array:
	var hx := TILE.x * 0.5 * scale
	var hy := TILE.y * 0.5 * scale
	var up := Vector2(0, -lift)
	return PackedVector2Array([center + Vector2(0, -hy) + up, center + Vector2(hx, 0) + up,
		center + Vector2(0, hy) + up, center + Vector2(-hx, 0) + up])
