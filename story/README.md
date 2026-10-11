# Сюжет и диалоги

- [prologue-plan.md](prologue-plan.md) — поэтапный план 8 сцен пролога: ход, выборы, флаги, Тьма, эхо в главах.
- `ink/` — диалоги на Ink. Точка входа пролога `ink/prologue.ink`, общие переменные и функции форм по полу `ink/common.ink`, сцены в `ink/prologue/`.

Проверка без Godot: Ink компилируется `inkjs` (`npx inkjs-compiler story/ink/prologue.ink -o /tmp/prologue.json`).

Каждая сцена — туннель Ink: заканчивается `->->`, а `prologue.ink` вызывает их по порядку. Бой запускается тегом `# battle:<id>` на последней строке перед ним.
