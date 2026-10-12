# Сюжет и диалоги

- [prologue-plan.md](prologue-plan.md) — поэтапный план 8 сцен пролога: ход, выборы, флаги, Тьма, эхо в главах.
- [chapter1-plan.md](chapter1-plan.md) — план 7 сцен главы 1 «Верхние шахты».
- [chapter2-plan.md](chapter2-plan.md) — план 7 сцен главы 2 «Затопленные выработки».
- [chapter3-plan.md](chapter3-plan.md) — план 8 сцен главы 3 «Дварфийские залы».
- [chapter4-plan.md](chapter4-plan.md) — план 6 сцен главы 4 «Кузницы плоти».
- [chapter5-plan.md](chapter5-plan.md) — план главы 5 «Дно» и четырёх концовок.
- [exploration-plan.md](exploration-plan.md) — исследование локаций и охоты за скрытыми легендарками по главам.
- `ink/` — диалоги на Ink. Точка входа всей истории `ink/game.ink`, общие переменные и функции форм по полу `ink/common.ink`, сцены в `ink/prologue/`, `ink/chapter1/`, `ink/chapter2/`, `ink/chapter3/`, `ink/chapter4/` и `ink/chapter5/`.

Проверка без Godot: Ink компилируется `inkjs` (`npx inkjs-compiler story/ink/game.ink -o /tmp/game.json`).

Каждая сцена — туннель Ink: заканчивается `->->`, а `game.ink` вызывает их по порядку из узла главы (`prologue`, `chapter1`, `chapter2`, `chapter3`, `chapter4`, `chapter5`). Бой запускается тегом `# battle:<id>` на последней строке перед ним. Тег `# unlock:dark_gifts` в конце пролога открывает тёмные дары в бою; `# silver:<N>` с отрицательным N списывает серебро.

Исследование локаций (тайники, закоулки, охоты за легендарками) — в `ink/chapterN/explore.ink`; правила вызова и теги описаны в `ink/explore_common.ink`.
