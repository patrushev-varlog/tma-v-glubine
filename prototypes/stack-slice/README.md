# Срез стека

Технический срез «Тьмы в глубине»: Ink через GodotInk, английский текст, геймпад и Steam Deck, стиль-тест графики, портрет по Тьме, экспорт на четыре платформы. Решения и результаты — в [STACK.md](STACK.md).

Нужны **Godot 4.7.2 .NET** и **.NET SDK 8**; для сборки под Android — ещё .NET SDK 9 или новее, JDK 17 и Android SDK. Пересобирать историю из `.ink` — Node 18+.

## Запуск

В редакторе: открыть `project.godot`, нажать Build, затем F5.

Из командной строки:

```sh
cd prototypes/stack-slice
dotnet build StackSlice.csproj
godot --headless --path . --import
godot --path .                                   # экран среза
godot --headless --path . -s res://tests/run_tests.gd   # тесты: Ink против inkjs, смена языка, геймпад
```

`SLICE_TESTS=ink` или `SLICE_TESTS=ui` запускают часть тестов, `SLICE_RUNS=4` — меньше прогонов истории.

Запасной рантайм (обычный Godot 4.7.2, без .NET):

```sh
cd prototypes/stack-slice/fallback-inkgd
godot --headless --path . --import
SLICE_RUNS=4 godot --headless --path . -s res://tests/run_tests.gd
godot --headless --path . -s res://tests/bench.gd       # замер скорости
```

## После правки `.ink`

```sh
cd prototypes/stack-slice/tools
npm install                    # один раз
node ink_tool.mjs build        # story/ink → story/*.json
node ink_tool.mjs reference    # эталон inkjs для тестов (около минуты)
node ink_tool.mjs check        # JSON свежий, русский и английский ведут себя одинаково
```

## Сборки

Пресеты в `export_presets.cfg`, сборки кладутся в `build/stack-slice/` в корне репозитория:

```sh
godot --headless --path . --export-release macOS      # "Windows Desktop", Linux
godot --headless --path . --export-debug Android ../../build/stack-slice/android/TmaStackSlice.apk
../../build/stack-slice/linux/TmaStackSlice.x86_64 --headless -- --selftest
```

То же самое на каждый PR делает CI (`.github/workflows/stack-slice.yml`) и выкладывает сборки артефактами.

## Что где

| Путь | Что |
|---|---|
| `main.tscn`, `scripts/main.gd` | Экран: диалог, поле, портрет, подсказки |
| `scripts/story/story_runner.gd` | Обёртка над рантаймом Ink: весь доступ игры к истории |
| `scripts/story/InkLoader.cs` | Единственный свой C#: загрузка JSON в GodotInk |
| `scripts/story/transcript.gd` | Прогон истории для сверки с inkjs |
| `scripts/input/input_setup.gd` | Раскладка ввода и подписи кнопок под устройство |
| `scripts/board/iso_board.gd` | Поле 6×4 из якорей стиля, курсор и шаг Гаррета |
| `scripts/portrait/` | Портрет из слоёв и шейдер замены тонов кожи |
| `ink/slice.*.ink` | Точки входа сцены на русском и английском |
| `story/*.json` | Скомпилированная история (собирается `ink_tool.mjs build`) |
| `i18n/ui.csv` | Строки интерфейса RU/EN |
| `art/` | Копии якорей стиля из `art/anchors` и заглушки портрета |
| `tests/` | Тесты и эталон `reference.json` |
| `tools/` | `ink_tool.mjs`, снимки экрана, генератор заглушек портрета |
| `fallback-inkgd/` | Запасной путь: отдельный проект на inkgd |
| `addons/GodotInk/` | Плагин GodotInk (MIT), master `49e35b5` |
| `docs/` | Снимки экрана для STACK.md |
