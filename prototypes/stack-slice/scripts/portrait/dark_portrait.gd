class_name DarkPortrait
extends Control
## Портрет героя по стадиям Тьмы как композит: базовый портрет + слои поверх + замена тонов кожи.
## Один базовый портрет на внешность, три слоя на стадии — вместо 4 отдельных портретов
## на каждую эмоцию (review/02-design-and-product.md, п. 5 про комбинаторику портретов).
## Файлы в art/portrait/: hero_base.png и dark_1_dusk / dark_2_gloom / dark_3_abyss.png (слои
## добавляются накопительно). Сейчас там заглушки из tools/make_placeholder_portrait.py.

const STAGES := ["DARK_SHADOW", "DARK_DUSK", "DARK_GLOOM", "DARK_ABYSS"]
const LAYERS := ["res://art/portrait/dark_1_dusk.png", "res://art/portrait/dark_2_gloom.png", "res://art/portrait/dark_3_abyss.png"]
# Рампы кожи по стадиям: светлый, основной, тень — только цвета Resurrect 64.
const SKIN := [
	["#fdcbb0", "#fca790", "#cd683d"],
	["#fdcbb0", "#ab947a", "#966c6c"],
	["#c7dcd0", "#9babb2", "#7f708a"],
	["#ffffff", "#c7dcd0", "#9babb2"],
]
const SCALE := 2

var stage := 0
var _base: TextureRect
var _layers: Array[TextureRect] = []


func _ready() -> void:
	custom_minimum_size = Vector2(128, 128) * SCALE
	_base = _rect(load("res://art/portrait/hero_base.png"))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/portrait/skin_swap.gdshader")
	_base.material = mat
	for path in LAYERS:
		_layers.append(_rect(load(path)))
	set_stage(0)


func _rect(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func set_stage(s: int) -> void:
	stage = clampi(s, 0, 3)
	for i in _layers.size():
		_layers[i].visible = i < stage
	var mat := _base.material as ShaderMaterial
	mat.set_shader_parameter("to_hi", Color(SKIN[stage][0]))
	mat.set_shader_parameter("to_mid", Color(SKIN[stage][1]))
	mat.set_shader_parameter("to_sh", Color(SKIN[stage][2]))


func stage_name() -> String:
	return STAGES[stage]


## Стадия по шкале Тьмы 0–100: Тень < 25 ≤ Сумрак < 50 ≤ Мрак < 75 ≤ Бездна.
static func stage_for(darkness: int) -> int:
	return clampi(darkness / 25, 0, 3)
