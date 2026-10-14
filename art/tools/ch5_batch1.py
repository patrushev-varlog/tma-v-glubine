"""Глава 5, партия 1: пробы тайлсета дна (спуск и зал печати) и трёх врагов перед массовой генерацией.

Как ch4_batch1.py: тайлы и объекты по два seed в art/chapter5/tiles/<набор>/variants/<имя>_<seed>.png,
персонажи — основы в стиле Гаррета.

    python3 art/tools/ch5_batch1.py [tiles|chars|набор ...]     # --reroll имя... — ещё seed 3 и 4
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import FLAT
import ch3_batch1 as base

base.TILES = p.ROOT / "art" / "chapter5" / "tiles"
base.CHARS_OUT = p.ROOT / "art" / "chapter5" / "characters"
DEEP = ("at the very bottom of the world under ancient dwarven halls, cold blue-grey bedrock, old royal masonry, "
        "faint pale silver-white light glowing from carved grooves, ")
SETS = {
 "deep": {
  "tiles": {
   "floor_seal": FLAT + "a dark blue-grey basalt floor slab with a deep carved curved groove glowing faint pale silver-white light, cold, low contrast, seamless edges",
   "floor_descent": FLAT + "rough dark blue-grey bedrock floor of a deep mine descent, worn uneven stone, fine grey dust, cold dim light, low contrast, seamless edges",
  },
  "objects": {
   "pedestal": (DEEP + "a square stone pedestal of dark polished basalt, waist high, a royal crest of a tower over three stars carved on the front, empty top", 64, 96),
   "plaque": (DEEP + "a bronze memorial plaque with rows of engraved names bolted to a block of dark stone, green patina", 64, 64),
  },
 },
}
CHARS = {
 "council_guard": "an undead honour guard of a royal council sixty years dead, grey dried skin, empty eye sockets with faint pale light, ornate old ceremonial plate armour with a tarnished silver tower over three stars crest on the chest, a plumed helmet, a tattered dark blue cloak, a long halberd held upright, ",
 "edric": "an old stooped pale king, almost transparent pale skin with dark threads visible under it, tired living eyes, thin white hair, no crown, a long dark robe with a very high stiff collar, thin bony hands glowing with faint grey deathly light, ",
 "sleeper_shade": "a tall shadowy spirit of an ancient sleeping god, a humanoid shape of swirling black smoke and darkness with pale silver-white cracks of light, long thin arms ending in claws, no face but two faint white eyes, floating above the ground, ",
}
base.SETS = SETS


if __name__ == "__main__":
    args = sys.argv[1:]
    jobs, chars = [], []
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
        chars = [n for n in CHARS if n in names]
    else:
        what = args or ["tiles", "chars"]
        if "tiles" in what or any(a in SETS for a in what):
            sets = [a for a in what if a in SETS] or list(SETS)
            jobs = [(k, s, n, sp, seed) for s in sets for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
        if "chars" in what:
            chars = list(CHARS)
    base.run_jobs(jobs, chars, charset=CHARS)
    print(p.balance()["subscription"])
