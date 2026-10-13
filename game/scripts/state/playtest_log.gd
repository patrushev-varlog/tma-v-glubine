class_name PlaytestLog
extends RefCounted
## Журнал прохождения для плейтеста (docs/PLAYTEST.md): одна строка JSON на событие в user://playtest.jsonl.
## Только локальный файл, в сеть ничего не уходит. Тестер присылает файл после игры, а
## tools/playtest_report.py сводит файлы в таблицу: сколько длилась каждая сцена, сколько раз проигран
## каждый бой, где игрок вышел из игры. Так видно, где застревают, даже если тестер об этом не сказал.

const PATH := "user://playtest.jsonl"
## Больше этого файл не растёт: старый уходит в playtest.old.jsonl.
const MAX_BYTES := 2_000_000

## Выключается в тестах GUT и в самопроверке, чтобы не писать в журнал тестера.
static var enabled := true
## Номер запуска игры: события одного запуска в отчёте идут вместе.
static var _run := ""


static func event(kind: String, data := {}) -> void:
	if not enabled:
		return
	if _run == "":
		_run = "%d-%d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
		_write({"ev": "launch", "version": String(ProjectSettings.get_setting("application/config/version", "")),
			"demo": Game.is_demo(), "os": OS.get_name(), "lang": TranslationServer.get_locale()})
	var row := data.duplicate()
	row["ev"] = kind
	_write(row)


static func _write(row: Dictionary) -> void:
	row["run"] = _run
	row["t"] = int(Time.get_unix_time_from_system())
	row["ms"] = Time.get_ticks_msec()
	if FileAccess.file_exists(PATH):
		var size := FileAccess.open(PATH, FileAccess.READ).get_length()
		if size > MAX_BYTES:
			DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH),
				ProjectSettings.globalize_path("user://playtest.old.jsonl"))
	var f := FileAccess.open(PATH, FileAccess.READ_WRITE if FileAccess.file_exists(PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line(JSON.stringify(row))


## Полный путь к журналу — показать тестеру, какой файл прислать.
static func os_path() -> String:
	return ProjectSettings.globalize_path(PATH)
