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
