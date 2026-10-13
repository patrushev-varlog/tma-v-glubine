class_name Portraits
extends RefCounted
## Портреты из art/portraits (копирует tools/import_art.py): кто говорит по тегу # spk:, какая эмоция по # mood:,
## имя говорящего и портрет героя со слоями Тьмы (art/PROMPTS.md, 8.5).

const PATH := "res://art/portraits/%s/%s.png"
## Слои Тьмы героя: накопительно, с Сумрака (25). За пролог Тьма не выше 20, поэтому в демо их не видно.
const DARK_LAYERS: Array[String] = ["dark_1_dusk", "dark_2_gloom", "dark_3_abyss"]
## Говорящие, у которых есть свой портрет; остальные (охотник, соседка, мальчик) показываются только именем.
const OWN := ["irena", "garret", "brandt", "oldrik", "velior"]

static var _cache := {}


## Портрет по тегам строки: hero и spouse зависят от созданного героя. "" — портрета нет.
static func id_for(speaker: String, mood := "", hero := {}) -> String:
	var base := ""
	match speaker:
		"hero":
			base = hero_id(hero)
		"spouse":
			base = "spouse_f" if bool(hero.get("spouse_f", true)) else "spouse_m"
		_:
			if OWN.has(speaker):
				base = speaker
	if base == "":
		return ""
	if mood != "" and has(base + "_" + mood):
		return base + "_" + mood
	return base if has(base) else ""


static func hero_id(hero: Dictionary) -> String:
	return "hero_%s_%s" % [String(hero.get("class", "fighter")), "f" if bool(hero.get("hero_f", false)) else "m"]


static func has(id: String) -> bool:
	return ResourceLoader.exists(PATH % [id, "base_128"])


## size 128 — диалог, 64 — панель боя.
static func texture(id: String, size := 128) -> Texture2D:
	var key := "%s/%d" % [id, size]
	if not _cache.has(key):
		var p := PATH % [id, "base_%d" % size]
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]


static func dark_layer(id: String, i: int) -> Texture2D:
	var key := "%s/%s" % [id, DARK_LAYERS[i]]
	if not _cache.has(key):
		var p := PATH % [id, DARK_LAYERS[i]]
		_cache[key] = load(p) if ResourceLoader.exists(p) else null
	return _cache[key]


## Стадия Тьмы по шкале 0–100: Тень < 25 ≤ Сумрак < 50 ≤ Мрак < 75 ≤ Бездна.
static func dark_stage(darkness: int) -> int:
	return clampi(darkness / 25, 0, 3)


## Имя над репликой. Герой и супруг — как ввёл игрок; для остальных ключ SPEAKER_<id> в i18n/ui.csv (как на экране локации).
static func speaker_name(speaker: String, hero := {}, spouse_name := "") -> String:
	match speaker:
		"":
			return ""
		"hero":
			return String(hero.get("name", ""))
		"spouse":
			return spouse_name
	var key := "SPEAKER_" + speaker
	var t := TranslationServer.translate(key)
	return "" if t == key else t


## Портрет с рамкой: базовый кадр и слои Тьмы поверх (только у героя). Масштаб целый, без сглаживания.
static func view(id: String, size := 128, scale := 2, darkness := 0) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(size, size) * scale
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if id == "":
		return box
	box.add_child(_rect(texture(id, size)))
	if size == 128 and id.begins_with("hero_"):
		for i in dark_stage(darkness):
			var layer := dark_layer(id, i)
			if layer != null:
				box.add_child(_rect(layer))
	return box


static func _rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
