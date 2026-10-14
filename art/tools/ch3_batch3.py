"""Глава 3, партия 3: анимации бойцов дварфийских залов (после проб, по слову Валерия):
страж Молчащих, мёртвый архивариус и Торвин-Без-Голоса.

Стойка, ходьба, урон и выбывание — шаблоны PixelLab (как k3_batch2), удар — по скелету (skeleton_anim.py).
Кадры: art/chapter3/characters/<имя>/pixellab (шаблоны) и anims/attack (удар). Готовое пропускается.

    python3 art/tools/ch3_batch3.py [имя ...]
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
import skeleton_anim as s
from k3_batch2 import heroes, todo, run

CH = p.ROOT / "art" / "chapter3" / "characters"
NAMES = ("stone_guardian", "dwarf_dead", "torvin")


def attack(n, d):
    if (CH / n / "anims" / "attack" / d / "05.png").exists():
        return n, "attack", d, "есть"
    return n, "attack", d, s.run(n, "attack", dirs=(d,), root=CH)


if __name__ == "__main__":
    H = heroes(sys.argv[1:] or NAMES)
    tasks = [(n, c, *t) for n, c in H.items() for t in todo(c)]
    print(len(tasks), "шаблонных задач", flush=True)
    with cf.ThreadPoolExecutor(4) as ex:
        fs = [ex.submit(run, *t) for t in tasks] + [ex.submit(attack, n, d) for n in H for d in s.DIRS]
        for f in cf.as_completed(fs):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
    for n, c in H.items():
        p.character_zip(c, CH / n / "pixellab")
    print(p.balance()["subscription"])
