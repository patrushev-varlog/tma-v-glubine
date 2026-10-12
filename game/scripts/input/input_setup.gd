extends Node
## Автозагрузка: раскладка ввода для клавиатуры, мыши и геймпада + какое устройство сейчас в руках.
## Godot 4.7 по умолчанию не вешает кнопки геймпада на ui_accept и ui_cancel (только D-pad и левый
## стик на стрелки), поэтому добавляем их сами. Steam Deck через Steam Input виден как геймпад Xbox.
## Перенесено из prototypes/stack-slice (проверено на Mac, Android и геймпаде).

signal device_changed(kind: String)

## "keyboard" (клавиатура и мышь) или "xbox" / "playstation" / "nintendo" / "deck".
var device := "keyboard"

const ACTIONS := {
	# действие: клавиши и кнопки геймпада
	"ui_accept": {"joy": [JOY_BUTTON_A]},
	"ui_cancel": {"joy": [JOY_BUTTON_B]},
	"ui_up": {"keys": [KEY_W]},
	"ui_down": {"keys": [KEY_S]},
	"ui_left": {"keys": [KEY_A]},
	"ui_right": {"keys": [KEY_D]},
	"game_menu": {"keys": [KEY_ESCAPE], "joy": [JOY_BUTTON_START]},
	"game_journal": {"keys": [KEY_J], "joy": [JOY_BUTTON_BACK]},
	"game_quicksave": {"keys": [KEY_F5]},
	"game_quickload": {"keys": [KEY_F9]},
}


func _ready() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
		for code in ACTIONS[action].get("keys", []):
			var key := InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
		for code in ACTIONS[action].get("joy", []):
			var button := InputEventJoypadButton.new()
			button.button_index = code
			button.device = -1  # любой геймпад
			InputMap.action_add_event(action, button)


func _input(event: InputEvent) -> void:
	var kind := device
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.4):
		kind = joy_kind(Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		kind = "keyboard"
	if kind != device:
		device = kind
		device_changed.emit(kind)


static func joy_kind(name: String) -> String:
	var n := name.to_lower()
	if n.contains("steam deck") or n.contains("steam virtual") or n.contains("valve"):
		return "deck"
	if n.contains("ps3") or n.contains("ps4") or n.contains("ps5") or n.contains("dualsense") or n.contains("dualshock") or n.contains("playstation") or n.contains("sony"):
		return "playstation"
	if n.contains("nintendo") or n.contains("switch") or n.contains("joy-con"):
		return "nintendo"
	return "xbox"


## Подпись кнопки для подсказок на экране под текущее устройство.
func glyph(action: String) -> String:
	if device == "keyboard":
		return {
			"ui_accept": "Enter", "ui_cancel": "Esc", "game_menu": "Esc", "game_journal": "J",
			"game_quicksave": "F5", "game_quickload": "F9",
		}.get(action, action)
	var face: Dictionary = {
		"xbox": {"a": "A", "b": "B", "back": "View", "start": "Menu"},
		"deck": {"a": "A", "b": "B", "back": "View", "start": "Menu"},
		"playstation": {"a": "✕", "b": "○", "back": "Share", "start": "Options"},
		# У Nintendo нижняя кнопка подписана B: SDL отдаёт её как JOY_BUTTON_A (позиция, не буква).
		"nintendo": {"a": "B", "b": "A", "back": "−", "start": "+"},
	}[device]
	return {
		"ui_accept": face["a"], "ui_cancel": face["b"], "game_menu": face["start"], "game_journal": face["back"],
	}.get(action, action)
