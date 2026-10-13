# Игра: проект Godot

Игровой проект «Тьмы в глубине» на Godot 4.7.2 .NET с GodotInk (выбор — `review/07-next-steps.md`,
поток F). Правила боя перенесены из серого прототипа `prototypes/combat` и стали данными
(`docs/COMBAT_DATA.md`). Сюжет — Ink из `story/`, собранный в `game/story/*.json`.

## Запуск

Нужны Godot 4.7.2 .NET (mono), .NET SDK 8 и Node 22 (только для сборки сюжета).

```sh
cd game/tools && npm ci && node ink_tool.mjs build   # story/ink → game/story/game.ru.json, scenes.json
cd .. && dotnet build                                # GodotInk и загрузчик историй на C#
godot --path .                                       # или открыть game/project.godot в редакторе
```

`node ink_tool.mjs check` говорит, устарели ли собранные JSON после правок в `story/`.

## Проверки

```sh
godot --headless --path game -s addons/gut/gut_cmdln.gd              # все тесты GUT
godot --headless --path game -s addons/gut/gut_cmdln.gd -gselect=test_abilities
godot --headless --path game -- --selftest                             # самопроверка, её же гоняет CI на сборках
godot --headless --path game -s tools/simulate.gd -- level=3 class=wizard   # вин-рейты, ключи в начале simulate.gd
```

Самопроверка (`scripts/ui/selftest.gd`) проходит переводы и данные, проводит бой, проигрывает всю
историю и проверяет сохранение в середине. В конце печатает `SELFTEST OK` или `SELFTEST FAIL`.

## Сборки

`export_presets.cfg` — Windows, macOS (universal) и Linux. Сборки кладутся в `build/game/<ос>/`.

```sh
godot --headless --path game --export-release "Linux" ../build/game/linux/TmaVGlubine.x86_64
```

CI (`.github/workflows/ci.yml`):

- `game-tests` — сборка сюжета, `dotnet build`, тесты GUT и самопроверка.
- `export` — три сборки на Linux, самопроверка сборки Linux.
- `smoke` — запуск сборки Windows (на каждом PR) и macOS (на main и вручную).

Готовые сборки лежат в артефактах прогона: `game-windows`, `game-macos`, `game-linux`.

## Устройство

| Папка | Что в ней |
| --- | --- |
| `scripts/combat/` | Бой без сцен: `battle.gd` (исполнитель правил), `combatant.gd`, `combat_data.gd`, `combat_ai.gd`, `items.gd`, `dice.gd`, `simulator.gd`. |
| `scripts/story/` | `story_runner.gd` над GodotInk; `InkLoader.cs` — загрузка JSON истории и текущий путь Ink. |
| `scripts/state/` | `story_session.gd` (прохождение, журнал событий, сохранения), `game_state.gd` (герой, серебро, вещи, журнал), `quest_journal.gd`, `save_store.gd`, автозагрузка `game.gd`. |
| `scripts/ui/` | Экраны: главное меню, создание героя, история с журналом и меню. Вёрстка кодом в `ui_kit.gd`. |
| `scripts/input/` | Действия ввода для клавиатуры, мыши и геймпада. |
| `data/` | `combat/` — правила боя, `story/quests.json` — задания журнала, `hero/spouse_names.json` — имена супруга с падежами. |
| `i18n/` | `ui.csv`, `combat.csv` — русский и английский. |
| `story/` | Собранные `game.<язык>.json` и `scenes.json` — генерируются `ink_tool.mjs`, вручную не правятся. |
| `tests/` | GUT: правила боя, тест на каждое умение и приём, предметы, прохождение и сохранения. |

### Сохранения

Сюжетные флаги и шкала Тьмы — переменные Ink. Всё, что вносит игрок (выбор, исход боя, осмотр на
карте), пишется в журнал событий. Сохранение — это родное состояние Ink и состояние партии на входе в
текущую сцену плюс весь журнал. Если язык и версия истории те же, игра грузит состояние сцены и
доигрывает её события. Если текст правился или язык другой, журнал проигрывается с начала: полная
игра — около 70 событий, это меньше секунды. Автосохранение — на входе в каждую сцену; ещё есть
быстрое (F5/F9) и шесть слотов.

### Чего пока нет

- Экрана боя (поток I): бой по тегу `# battle:` проводит ИИ за обе стороны. Сюжетных карт боёв ещё
  нет, поэтому берётся тестовый бой уровня отряда.
- Экрана повышения уровня: ветка героя — первая из двух.
- Английского текста истории: при английском языке интерфейс английский, сюжет русский.
