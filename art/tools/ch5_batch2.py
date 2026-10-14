"""Глава 5, партия 2 (после проб, по слову Валерия): остальные предметы дна, центр печати и стены кубами.
Как ch4_batch2.py: предметы по два seed в variants/, стены — variants/<имя>_b<seed>.png.

    python3 art/tools/ch5_batch2.py [tiles|имя ...]     # --reroll имя... — ещё seed 3 и 4
    python3 art/tools/ch5_batch2.py --blocks            # стены кубами
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import FLAT
import ch3_batch1 as base
import ch5_batch1 as ch5

DEEP = ch5.DEEP
SETS = {
 "deep": {
  "tiles": {
   "floor_seal_core": FLAT + "the centre of a huge carved seal on a dark blue-grey basalt floor, many curved grooves converging into a small round hollow, all grooves and the hollow glowing bright pale silver-white light, seamless edges",
  },
  "objects": {
   "seal_light": (DEEP + "a column of soft pale silver-white light rising from a round hollow in a dark stone floor, glowing motes, translucent, no solid object", 64, 128),
   "council_door": (DEEP + "a small low iron-bound door half hidden in a dark basalt wall, a worn royal crest of a tower over three stars above it, a keyhole", 64, 96),
   "fallen_guard": (DEEP + "the collapsed remains of an undead honour guard lying on the floor, ornate tarnished ceremonial plate armour with a tower and three stars crest, a plumed helmet, a broken halberd, bones and dust", 64, 64),
   "pen_bars": (DEEP + "a pen of old rusty iron bars set into rough dark rock, a barred gate with a heavy padlock, straw and a wooden bowl inside, empty", 64, 96),
   "descent_stairs": (DEEP + "a narrow flight of worn stone steps cut into dark bedrock going down into darkness, an old iron chain rail", 64, 96),
   "pale_brazier": (DEEP + "a tall black iron brazier on three legs burning with cold pale silver-white flame", 32, 64),
   "council_banner": (DEEP + "a tattered dark blue royal banner hanging from an iron pole, a faded silver tower over three stars, cobwebs", 32, 96),
  },
 },
}
BLOCKS = {
 "wall_bedrock": "solid cube of rough dark blue-grey bedrock with old chisel marks, the wall of the deepest mine "
                 "descent under the world, cold dim light, no door, no window, no torch, no floor",
 "wall_seal": "solid cube of dark polished basalt blocks with a thin carved groove glowing faint pale silver-white, "
              "the wall of a vast round underground hall, no door, no window, no torch, no floor",
}
VARIANTS = base.TILES / "deep" / "variants"


def block(name, seed):
    out = VARIANTS / f"{name}_b{seed}.png"
    if out.exists():
        return out
    return p.iso_tile(name, BLOCKS[name] + ", " + p.STYLE_ISO, out, shape="block", seed=seed)


if __name__ == "__main__":
    base.SETS = SETS
    args = sys.argv[1:]
    if args[:1] == ["--blocks"]:
        for n in BLOCKS:
            for seed in (1, 2):
                print("ok", block(n, seed).name, flush=True)
        print(p.balance()["subscription"])
        sys.exit()
    seeds = (3, 4) if args[:1] == ["--reroll"] else (1, 2)
    names = set(args[1:] if args[:1] == ["--reroll"] else args)
    jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
            if not names or "tiles" in names or n in names for seed in seeds]
    base.run_jobs(jobs, [], {})
    print(p.balance()["subscription"])
