extends Node
## Автозагрузка Sound: музыка, эмбиент и звуки по данным data/audio.json (DESIGN.md, «Звук»).
## Треки — audio/music/<id>.ogg, петли окружения — audio/ambient/<id>.ogg, звуки — audio/sfx/<id>.ogg.
## Пока файла нет, вместо него тишина: так экраны уже зовут звук, а треки добавляются без правок кода
## (лицензия каждого файла — в audio/LICENSES.md, авторы — в CREDITS.md).

const DATA := "res://data/audio.json"
const FADE := 1.2
const BUSES: Array[String] = ["Music", "Ambient", "Sfx"]
const SETTINGS_PATH := "user://settings.cfg"

## Громкость шин 0–1 (настройки игрока).
var volume := {"Music": 0.7, "Ambient": 0.7, "Sfx": 0.8}

var _data := {}
var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _music_id := ""
var _ambient_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for bus in BUSES:
			volume[bus] = float(cfg.get_value("audio", bus.to_lower(), volume[bus]))
	for bus in BUSES:
		_apply_volume(bus)
	_music = _player("Music")
	_ambient = _player("Ambient")
	if FileAccess.file_exists(DATA):
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))


func _player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


# --- Что играет ---------------------------------------------------------------------

func for_menu() -> void:
	_apply(_data.get("menu", {}))


func for_battle() -> void:
	_apply(_data.get("battle", {}))


func for_demo_end() -> void:
	_apply(_data.get("demo_end", {}))


func for_scene(scene: String) -> void:
	_apply(_data.get("scenes", {}).get(scene, {}))


## {"music": id, "ambient": id}: нет ключа — оставить как есть, "" — затихнуть.
func _apply(entry: Dictionary) -> void:
	if entry.has("music"):
		_music_id = _switch(_music, _music_id, String(entry.music), "music")
	if entry.has("ambient"):
		_ambient_id = _switch(_ambient, _ambient_id, String(entry.ambient), "ambient")


func _switch(p: AudioStreamPlayer, current: String, id: String, kind: String) -> String:
	if id == current:
		return current
	var stream := _stream(kind, id)
	var tw := create_tween()
	if p.playing:
		tw.tween_property(p, "volume_db", -40.0, FADE * 0.5)
	tw.tween_callback(func() -> void:
		p.stop()
		p.stream = stream
		if stream != null:
			p.volume_db = -40.0
			p.play())
	if stream != null:
		tw.tween_property(p, "volume_db", 0.0, FADE)
	return id


## Короткий звук (удар, колокол, щелчок). Нет файла — ничего.
func sfx(id: String) -> void:
	var stream := _stream("sfx", id)
	if stream == null:
		return
	var p := _player("Sfx")
	p.stream = stream
	p.finished.connect(p.queue_free)
	p.play()


func _stream(kind: String, id: String) -> AudioStream:
	if id == "":
		return null
	var path := "res://audio/%s/%s.ogg" % [kind, id]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	if kind != "sfx" and s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s


## Что сейчас должно звучать (для тестов и отладки): {"music", "ambient"}.
func now_playing() -> Dictionary:
	return {"music": _music_id, "ambient": _ambient_id}


# --- Громкость ----------------------------------------------------------------------

func set_volume(bus: String, value: float) -> void:
	volume[bus] = clampf(value, 0.0, 1.0)
	_apply_volume(bus)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", bus.to_lower(), volume[bus])
	cfg.save(SETTINGS_PATH)


func _apply_volume(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(float(volume[bus]), 0.0001)))
	AudioServer.set_bus_mute(i, float(volume[bus]) <= 0.001)
