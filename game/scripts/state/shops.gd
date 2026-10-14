class_name Shops
extends RefCounted
## Торговцы в лагерях (data/story/shops.json): что продают, почём и кому вещь подходит.

const PATH := "res://data/story/shops.json"

static var _data := {}


static func table() -> Dictionary:
	if _data.is_empty():
		_data = JSON.parse_string(FileAccess.get_file_as_string(PATH)).shops
	return _data


static func has_shop(shop_id: String) -> bool:
	return table().has(shop_id)


## Товары: [{"id", "price", "for"}] с ценой после скидки.
static func stock(shop_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not has_shop(shop_id):
		return out
	for s in table()[shop_id].stock:
		out.append({"id": String(s.id), "price": price(shop_id, String(s.id)), "for": s.get("for", [])})
	return out


## Цена с учётом скидки, до 5 серебра; −1 — торговец этого не продаёт.
static func price(shop_id: String, item_id: String) -> int:
	if not has_shop(shop_id):
		return -1
	var sh: Dictionary = table()[shop_id]
	for s in sh.stock:
		if String(s.id) == item_id:
			var p := float(s.price) * (100.0 - float(sh.get("discount", 0))) / 100.0
			return int(round(p / 5.0)) * 5
	return -1


## Подходит ли вещь участнику отряда (hero, irena, garret, velior).
static func fits(shop_id: String, item_id: String, owner: String) -> bool:
	for s in stock(shop_id):
		if s.id == item_id:
			return (s["for"] as Array).is_empty() or (s["for"] as Array).has(owner)
	return false


## Плата «услугой» (контрабандисты главы 2): вещи без серебра.
static func is_favor(shop_id: String) -> bool:
	return has_shop(shop_id) and bool(table()[shop_id].get("favor", false))


## Сколько вещей можно взять за один заход; 0 — без ограничения.
static func limit(shop_id: String) -> int:
	return int(table()[shop_id].get("limit", 0)) if has_shop(shop_id) else 0


## Кузница Молчащих (глава 3): переносит свойство, а не продаёт.
static func is_forge(shop_id: String) -> bool:
	return has_shop(shop_id) and table()[shop_id].has("forge")


## Цена переноса в серебре; flags — переменные Ink (кузнец из Эшмура у горна берёт дешевле), до 5 серебра.
static func forge_price(shop_id: String, flags: Dictionary) -> int:
	var fg: Dictionary = table()[shop_id].forge
	var p := float(fg.price)
	var kv := String(fg.get("flag", "")).split("=", true, 1)
	if kv.size() == 2 and str(flags.get(kv[0], "")) == kv[1]:
		p *= (100.0 - float(fg.get("discount", 0))) / 100.0
	return int(round(p / 5.0)) * 5


## Материал переноса: слиток дварфийской стали.
static func forge_steel(shop_id: String) -> String:
	return String(table()[shop_id].forge.get("steel", "dwarf_steel"))
