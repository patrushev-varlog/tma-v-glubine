"""Глава 3, партия 2 (после проб, по слову Валерия): остальные предметы дварфийских залов, пол пропасти
и основа Торвина. Как ch3_batch1.py: предметы по два seed в variants/, персонажи — основы в стиле Гаррета.

    python3 art/tools/ch3_batch2.py [tiles|chars|имя ...]     # --reroll имя... — ещё seed 3 и 4
    python3 art/tools/ch3_batch2.py --blocks                  # стены кубами, variants/<имя>_b<seed>.png
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import FLAT
from ch1_batch2 import NO_SHADOW
from ch3_batch1 import CHARS_OUT, HALLS, run_jobs

SETS = {
 "dwarf": {
  "tiles": {
   "floor_chasm": FLAT + "a bottomless chasm seen from above, an even near-black void with only very faint dark blue-grey mist, completely uniform, no light spots, no objects, no rim, no border, seamless edges",
  },
  "objects": {
   "wall_block": (HALLS + "a plain solid cube of dwarven masonry, large precisely cut warm-grey stone blocks on every face, flat grey stone top, no door, no window, no roof, no light", 64, 64),
   "wall_runes": (HALLS + "a plain solid cube of dwarven masonry, large cut warm-grey stone blocks, one deep-cut band of angular runes across the front faces, flat grey stone top, no door, no window, no roof, no light", 64, 64),
   "rune_column": (HALLS + "a square carved dwarven stone column with angular runes on each face and a heavy capital", 64, 96),
   "stone_niche": (HALLS + "an empty tall stone wall niche carved in the rock where a stone guardian statue used to stand, broken stone fragments at its foot", 64, 96),
   "rune_brazier": (HALLS + "a squat dwarven stone brazier bowl on a carved rune pedestal with small warm flames", 32, 64),
   "rubble": (HALLS + "a heap of broken carved stone blocks and fragments of a smashed stone statue, a stone hand among them", 64, 64),
   "anvil": (HALLS + "a huge dwarven anvil of dark iron on a stone block, a heavy hammer lying on it", 64, 64),
   "steel_chest": (HALLS + "a long stone bin with an iron-bound lid propped open, dull dark dwarven steel ingots stacked inside", 64, 64),
   "coal_heap": (HALLS + "a heap of black coal with a shovel stuck in it beside a wooden barrow", 64, 64),
   "brew_door": (HALLS + "a low heavy wooden door bound with iron set in a carved stone wall, a carved tankard sign above it", 64, 96),
   "scribe_desk": (HALLS + "a low stone writing desk covered with thin rune tablets, stone chisels and a small mallet, a stone stool", 64, 64),
   "child_tablets": (HALLS + "a single small low stone shelf, a free-standing object with no walls and no room, holding a few small thin stone tablets with large clumsy runes and a child's practice slate", 64, 64),
   "floor_slab": (HALLS + "one loose square flagstone lying flat, a single isolated object with no walls and no room around it, its edges slightly raised and scraped, a thin ring of disturbed dust", 64, 64),
   "bones": (HALLS + "several human skeletons in tattered miner jackets lying flat on their backs on the ground in a heap, seen from above, broken pickaxes beside them, nothing standing", 64, 64),
   "warhammer": (HALLS + "a huge dwarven long-hafted warhammer with an iron head lying flat on the stone floor", 64, 64),
  },
 },
}
# Стены объектами выходят домиками с дверью (seed 1–4); как в ch1_batch3.py — куб через create-isometric-tile (block).
BLOCKS = {
 "wall_block": "solid cube of dwarven masonry, large precisely cut warm-grey stone blocks on all visible faces, "
               "the wall of an underground dwarven hall, no door, no window, no torch, no floor",
 "wall_runes": "solid cube of dwarven masonry, large cut warm-grey stone blocks, one band of deep-cut angular runes "
               "across the faces, the wall of an underground dwarven hall, no door, no window, no torch, no floor",
}
VARIANTS = p.ROOT / "art" / "chapter3" / "tiles" / "dwarf" / "variants"


def block(name, seed):
    out = VARIANTS / f"{name}_b{seed}.png"
    if out.exists():
        return out
    return p.iso_tile(name, BLOCKS[name] + ", " + p.STYLE_ISO, out, shape="block", seed=seed)


CHARS = {
 "torvin": "a huge undead dwarf warrior, the last keeper of the seal, broad and armoured in heavy green-patinaed bronze plate, very long grey beard braided with iron rings down to the belt, a riveted iron muzzle plate where the mouth should be, empty pale eyes, a long-hafted warhammer held in both hands, ",
}
SIZES = {"torvin": 96}


def char(name, desc):
    if (CHARS_OUT / name / "id.txt").exists():
        return name, "exists", 0
    cid, j = p.create_character(name, desc + NO_SHADOW + p.STYLE_CHAR, size=SIZES.get(name, 64))
    p.character_zip(cid, CHARS_OUT / name / "base")
    (CHARS_OUT / name / "id.txt").write_text(cid + "\n")
    return name, cid, (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    args = sys.argv[1:]
    jobs, chars = [], []
    if args[:1] == ["--blocks"]:
        for n in BLOCKS:
            for seed in (1, 2):
                print("ok", block(n, seed).name, flush=True)
        print(p.balance()["subscription"])
        sys.exit()
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        what = args or ["tiles", "chars"]
        if "tiles" in what:
            jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
        chars = [n for n in CHARS if "chars" in what or n in what]
    run_jobs(jobs, chars, CHARS, char)
    print(p.balance()["subscription"])
