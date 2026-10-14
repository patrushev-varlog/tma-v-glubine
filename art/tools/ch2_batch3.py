"""Глава 2, партия 3: анимации бойцов затопленных выработок («Запускай» Валерия 14.10.2026):
утопленники, контрабандисты, Ренна, жрец святилища и страж шлюза.

Стойка, ходьба, урон и выбывание — шаблоны PixelLab (как k3_batch2), удар — по скелету (skeleton_anim.py).
Кадры: art/chapter2/characters/<имя>/pixellab (шаблоны) и anims/attack (удар). Готовое пропускается.

    python3 art/tools/ch2_batch3.py [имя ...]
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
import skeleton_anim as s
from k3_batch2 import heroes, todo, run

CH = p.ROOT / "art" / "chapter2" / "characters"
NAMES = ("drowned_m", "drowned_f", "smuggler", "renna", "shrine_priest", "sluice_guardian")


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
