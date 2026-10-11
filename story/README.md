# Сюжет и диалоги

- [prologue-plan.md](prologue-plan.md) — поэтапный план 8 сцен пролога: ход, выборы, флаги, Тьма, эхо в главах.
- [chapter1-plan.md](chapter1-plan.md) — план 7 сцен главы 1 «Верхние шахты».
- [chapter2-plan.md](chapter2-plan.md) — план 7 сцен главы 2 «Затопленные выработки».
- [chapter3-plan.md](chapter3-plan.md) — план 8 сцен главы 3 «Дварфийские залы».
- `ink/` — диалоги на Ink. Точка входа всей истории `ink/game.ink`, общие переменные и функции форм по полу `ink/common.ink`, сцены в `ink/prologue/`, `ink/chapter1/`, `ink/chapter2/` и `ink/chapter3/`.

Проверка без Godot: Ink компилируется `inkjs` (`npx inkjs-compiler story/ink/game.ink -o /tmp/game.json`).

Каждая сцена — туннель Ink: заканчивается `->->`, а `game.ink` вызывает их по порядку из узла главы (`prologue`, `chapter1`, `chapter2`, `chapter3`). Бой запускается тегом `# battle:<id>` на последней строке перед ним.
