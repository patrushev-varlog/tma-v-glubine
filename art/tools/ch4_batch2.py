"""Глава 4, партия 2 (после проб, по слову Валерия): остальные предметы кузниц плоти, решётка стока,
стены кубами и четыре врага. Как ch3_batch2.py: предметы по два seed в variants/, персонажи — основы в стиле Гаррета.

    python3 art/tools/ch4_batch2.py [tiles|chars|имя ...]     # --reroll имя... — ещё seed 3 и 4
    python3 art/tools/ch4_batch2.py --blocks                  # стены кубами, variants/<имя>_b<seed>.png
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import FLAT
from ch1_batch2 import NO_SHADOW
import ch3_batch1 as base
import ch4_batch1 as ch4

WORKS = ch4.WORKS
CHARS_OUT = base.CHARS_OUT
SETS = {
 "forge": {
  "tiles": {
   "floor_grate": FLAT + "a square rusty iron drain grate set in soot-blackened stone floor plates, dark sludge below the bars, faint warm orange reflected glow, low contrast, seamless edges",
  },
  "objects": {
   "conveyor": (WORKS + "a long low iron conveyor of rusty rollers and chains on a riveted frame, empty iron hooks hanging above it", 96, 64),
   "names_wall": (WORKS + "a section of soot-stained wall of black stone blocks densely scratched with hundreds of small names in rows, a few names circled", 64, 96),
   "smithy": (WORKS + "a small cold blacksmith's hearth of black stone with an anvil, tongs and a hammer, a rack of horseshoes and plain tools on the wall", 64, 96),
   "gong": (WORKS + "a large round bronze gong hanging in a black iron frame, a heavy mallet leaning on the frame", 64, 96),
   "brazier": (WORKS + "a tall black iron brazier bowl on three legs full of glowing coals with small flames", 32, 64),
   "stairs_up": (WORKS + "a narrow flight of black iron stairs with a rail going up into darkness, riveted steps", 64, 96),
   "clerk_desk": (WORKS + "a plain whitewashed wooden clerk's desk with neat stacks of ledgers, an inkwell, a quill and an abacus, a stool", 64, 64),
   "report_shelf": (WORKS + "a tall plain wooden shelf of identical bound ledgers and rolled reports with numbered labels, all very orderly", 64, 96),
   "window_works": (WORKS + "a barred window in a whitewashed wall with an orange glow of the workshops behind the glass", 64, 96),
   "safe": (WORKS + "a squat heavy iron safe with a dial lock and riveted corners standing on the floor", 64, 64),
   "locked_drawer": (WORKS + "a small wooden cabinet of drawers, one drawer with a heavy iron padlock", 64, 64),
   "armory_door": (WORKS + "a heavy iron-bound oak door with a royal crown emblem painted on it set in a black stone wall", 64, 96),
   "weapon_rack": (WORKS + "a wooden weapon rack with identical short swords, round iron shields and a few spears in a row", 64, 96),
   "store_book": (WORKS + "an open thick ledger lying on a slanted wooden lectern, columns of numbers and a seal", 32, 64),
   "door_bright": (WORKS + "a tall double door of pale wood with cold white light shining through the gap, set in a black stone wall", 64, 96),
   "master_table": (WORKS + "a large stone work table with neatly laid bone needles, coils of dark thread, glass jars and a surgical saw, an oil lamp", 64, 64),
   "cupola_door": (WORKS + "a low arched passage into an old cold cupola furnace of black bricks, cobwebs and soot, a rusted iron door hanging open", 64, 96),
   "slag_heap": (WORKS + "a heap of black and dark red slag lumps with a few still glowing faintly", 64, 64),
   "furnace": (WORKS + "a big brick smelting furnace with an arched mouth full of white-orange fire, iron doors open, a tall soot-black chimney", 128, 128),
  },
 },
}
# Стены — кубы через create-isometric-tile (block), как в ch3_batch2.py.
BLOCKS = {
 "wall_block": "solid cube of soot-blackened rough black stone blocks with rusty iron bands, the wall of an underground "
               "necromantic foundry, faint orange glow on the edges, no door, no window, no torch, no floor",
 "wall_pipes": "solid cube of soot-blackened black stone blocks with two rusty iron pipes running across the faces, "
               "the wall of an underground necromantic foundry, no door, no window, no torch, no floor",
}
VARIANTS = base.TILES / "forge" / "variants"


def block(name, seed):
    out = VARIANTS / f"{name}_b{seed}.png"
    if out.exists():
        return out
    return p.iso_tile(name, BLOCKS[name] + ", " + p.STYLE_ISO, out, shape="block", seed=seed)


CHARS = {
 "vat_overseer": "a living human overseer of a necromantic workshop, stocky, soot-stained leather apron over a dark royal uniform, a leather cap, a coiled rope lasso on the belt and a saber in the hand, a tired cruel face, ",
 "stitched": "a huge hulking undead made of several bodies stitched together with coarse dark thread, grey patchwork skin with crude seams and iron staples, one arm much bigger than the other, a leather muzzle, no clothes but a ragged loincloth, ",
 "foundry_dead": "an undead foundry worker, grey burned skin, a scorched leather apron and thick gloves, a long iron hook on a pole held in both hands, glowing orange cracks in the skin, ",
 "executioner": "an undead royal executioner raised in a necromantic vat, a tall broad dead man with grey skin in a black hood with eye holes, bare muscular grey arms, a black leather jerkin, a huge two-handed executioner's axe, ",
}
SIZES = {}


def char(name, desc):
    if (CHARS_OUT / name / "id.txt").exists():
        return name, "exists", 0
    cid, j = p.create_character(name, desc + NO_SHADOW + p.STYLE_CHAR, size=SIZES.get(name, 64))
    p.character_zip(cid, CHARS_OUT / name / "base")
    (CHARS_OUT / name / "id.txt").write_text(cid + "\n")
    return name, cid, (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    base.SETS = SETS
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
        else:
            jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                    if n in what for seed in (1, 2)]
        chars = [n for n in CHARS if "chars" in what or n in what]
    base.run_jobs(jobs, chars, CHARS, char)
    print(p.balance()["subscription"])
