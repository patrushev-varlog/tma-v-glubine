# Тьма в глубине

*Where the Sleeper Lies* — пошаговая сюжетная RPG в жанре тёмного фэнтези для ПК (Steam), второй релиз на Android. Отряд из четырёх героев, бой на основе SRD 5.2, скрытая шкала Тьмы и четыре концовки. 7,5–8 часов, русский и английский.

Пролог выйдет бесплатным демо в Steam; полная игра — разовая покупка без внутриигровых покупок и рекламы.

## Что где

- [DESIGN.md](DESIGN.md) — дизайн-документ и источник правды: правила, Тьма, экипировка, сюжет, продукт.
- [story/](story/) — планы глав и сценарий на Ink.
- [game/](game/) — проект игры на Godot 4.7.2 .NET: бой на данных, сюжет на Ink, сохранения, сборки.
- [prototypes/combat/](prototypes/combat/) — серый прототип боя на Godot 4 с тестами и симуляцией баланса.
- [review/](review/) — критический разбор октября 2026, план доработок и план следующих шагов (`07-next-steps.md`).
- [art/](art/) — промпты и правила стиля пиксель-арта.

## Проверки

CI (GitHub Actions) запускает тесты прототипа боя и компиляцию Ink; сборки под Windows, macOS и Linux включатся, когда в проекте игры появятся пресеты экспорта. Локально:

```sh
godot --headless --path prototypes/combat --import
godot --headless --path prototypes/combat -s res://tests/run_tests.gd
npx -p inkjs@2.4.0 inkjs-compiler story/ink/game.ink -o /tmp/game.json
```
