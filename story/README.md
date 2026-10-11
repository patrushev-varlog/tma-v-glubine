# Сюжет и диалоги

- [prologue-plan.md](prologue-plan.md) — поэтапный план 8 сцен пролога: ход, выборы, флаги, Тьма, эхо в главах.
- [chapter1-plan.md](chapter1-plan.md) — план 7 сцен главы 1 «Верхние шахты».
- [chapter2-plan.md](chapter2-plan.md) — план 7 сцен главы 2 «Затопленные выработки».
- `ink/` — диалоги на Ink. Точка входа всей истории `ink/game.ink`, общие переменные и функции форм по полу `ink/common.ink`, сцены в `ink/prologue/`, `ink/chapter1/` и `ink/chapter2/`.

Проверка без Godot: Ink компилируется `inkjs` (`npx inkjs-compiler story/ink/game.ink -o /tmp/game.json`).

Каждая сцена — туннель Ink: заканчивается `->->`, а `game.ink` вызывает их по порядку из узла главы (`prologue`, `chapter1`, `chapter2`). Бой запускается тегом `# battle:<id>` на последней строке перед ним.
