"""Глава 4, партия 1: пробы тайлсета кузниц плоти и двух врагов перед массовой генерацией.

Как ch3_batch1.py: тайлы и объекты по два seed в art/chapter4/tiles/<набор>/variants/<имя>_<seed>.png,
персонажи — основы в стиле Гаррета.

    python3 art/tools/ch4_batch1.py [tiles|chars|набор ...]     # --reroll имя... — ещё seed 3 и 4
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import FLAT
from ch1_batch2 import NO_SHADOW
import ch3_batch1 as base

base.TILES = p.ROOT / "art" / "chapter4" / "tiles"
base.CHARS_OUT = p.ROOT / "art" / "chapter4" / "characters"
WORKS = ("inside a hellish underground necromantic foundry carved in black rock, soot, rust and scorched iron, "
         "heat haze, deep orange glow of molten metal, ")
SETS = {
 "forge": {
  "tiles": {
   "floor_works": FLAT + "soot-blackened square stone floor plates with riveted rusty iron strips between them, dark ash and slag dust, faint warm orange reflected glow, low contrast, seamless edges",
   "floor_molten": FLAT + "a shallow stone channel filled with glowing molten orange-yellow iron flowing along the tile, dark cooling crust at the edges, bright but not white, seamless edges",
  },
  "objects": {
   "vat": (WORKS + "a large round iron vat on short legs filled to the brim with thick black bubbling liquid, rusty rivets, chains and a crank valve on the side, black fumes", 64, 96),
   "anatomy_table": (WORKS + "a long grey stone dissection table with a blood gutter along the edge, leather straps, iron surgical hooks and saws laid neatly on it, no body", 96, 64),
   "cage": (WORKS + "a tall square cage of black iron bars with a locked barred door, straw on the floor inside, empty", 64, 96),
   "ladle": (WORKS + "a huge iron foundry ladle hanging from a heavy chain on a wooden gantry, glowing molten metal spilling over its lip", 64, 128),
  },
 },
}
CHARS = {
 "dead_soldier": "an undead soldier made in a necromantic vat, grey dead skin, shaved head, blank empty face with milky eyes, identical dark iron plate armour of a royal army, a plain short sword and a round iron shield, standing in rigid formation stance, ",
 "gessar": "a thin pale elderly necromancer surgeon, grey hair, long blood-stained leather apron over a bare chest, faint dark glowing threads under the skin of the chest, polite smile, a long curved bone needle and a surgical saw in the hands, ",
}
base.SETS = SETS


if __name__ == "__main__":
    args = sys.argv[1:]
    jobs, chars = [], []
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        what = args or ["tiles", "chars"]
        if "tiles" in what or any(a in SETS for a in what):
            sets = [a for a in what if a in SETS] or list(SETS)
            jobs = [(k, s, n, sp, seed) for s in sets for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
        if "chars" in what:
            chars = list(CHARS)
    base.run_jobs(jobs, chars, charset=CHARS)
    print(p.balance()["subscription"])
