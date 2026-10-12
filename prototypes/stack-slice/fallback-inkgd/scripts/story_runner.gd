class_name StoryRunner
extends RefCounted
## Запасной рантайм Ink: inkgd (ветка godot4, fea9098), чистый GDScript, .NET не нужен.
## Те же методы, что у основного scripts/story/story_runner.gd (GodotInk), без журнала выборов —
## его логика от рантайма не зависит и переносится как есть.

const InkRuntimeScript := preload("res://addons/inkgd/ink_runtime.gd")

var _story: InkStory


static func backend_name() -> String:
	return "inkgd 0.6 (GDScript)"


static func _runtime() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null("__InkRuntime")
	if node == null:
		node = InkRuntimeScript.new()
		tree.root.add_child(node)
	return node


func load_json_text(json: String) -> void:
	_story = InkStory.new(json, _runtime())


func can_continue() -> bool:
	return _story.can_continue


func next_line() -> Dictionary:
	var text: String = _story.continue_story()
	return {"text": text, "tags": PackedStringArray(_story.current_tags)}


func choices() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _story.current_choices:
		out.append(c.text)
	return out


func choose(index: int) -> void:
	_story.choose_choice_index(index)


func get_var(name: String) -> Variant:
	return _story.variables_state.get_variable(name)


func set_var(name: String, value: Variant) -> void:
	_story.variables_state.set_variable(name, value)


func save_state() -> String:
	return _story.state.to_json()


func load_state(state_json: String) -> void:
	_story.state.load_json(state_json)
