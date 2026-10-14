"""Глава 3, партия 1: пробы тайлсета дварфийских залов и двух врагов перед массовой генерацией.

Как ch2_batch1.py: тайлы и объекты по два seed в art/chapter3/tiles/<набор>/variants/<имя>_<seed>.png,
персонажи — основы в стиле Гаррета.

    python3 art/tools/ch3_batch1.py [tiles|chars|набор ...]     # --reroll имя... — ещё seed 3 и 4
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO, FLAT
from ch1_batch2 import NO_SHADOW, EMPTY

TILES = p.ROOT / "art" / "chapter3" / "tiles"
CHARS_OUT = p.ROOT / "art" / "chapter3" / "characters"
HALLS = ("inside ancient silent dwarven halls carved in solid rock, dry dusty warm-grey stone, angular deep-cut runes, "
         "dim lantern light, ")
SETS = {
 "dwarf": {
  "tiles": {
   "floor_hall": FLAT + "large square dwarven flagstones of smooth warm sandstone-brown and ochre-grey granite lit by warm amber lantern light, precise thin joints, dry dust, low contrast, seamless edges",
   "floor_rune": FLAT + "a warm sandstone-brown dwarven floor slab lit by amber lantern light, a shallow carved channel of angular runes, dust in the grooves, low contrast, seamless edges",
  },
  "objects": {
   "rune_arch": (HALLS + "a massive carved stone archway cut from a single block, rows of angular dwarven runes along it, dark empty opening", 128, 128),
   "riddle_door": (HALLS + "a round-topped solid stone door without handle or keyhole set in a carved wall, a circle of runes in its centre and one larger line of runes below it", 64, 96),
   "great_forge": (HALLS + "a huge dwarven forge hearth of black stone blocks with a glowing orange fire inside, big bellows on the side, a stone chimney hood", 96, 96),
   "tablet_shelf": (HALLS + "a tall carved stone shelf filled with thin stone tablets covered in runes standing upright like books, dust on top", 64, 96),
  },
 },
}
CHARS = {
 "stone_guardian": "a dwarven stone construct guardian the height of a man, broad square body of carved grey granite blocks, angular runes glowing faintly blue on the chest, a smooth stone face with eyes but no mouth, heavy stone fists, ",
 "dwarf_dead": "a dead dwarf archivist risen as undead, short and stocky, dried leathery mummified skin, very long grey braided beard down to the knees, dusty scholar's robe with a leather apron, a stone chisel and a heavy mallet in the hands, empty dark eye sockets, ",
}
SIZES = {}


def one(kind, s, name, spec, seed):
    out = TILES / s / "variants" / f"{name}_{seed}.png"
    if out.exists():
        return out
    if kind == "tiles":
        return p.iso_tile(name, spec + ", " + p.STYLE_ISO, out, seed=seed)
    d, w, h = spec
    return p.map_object(name, d + ", " + ISO + p.STYLE_ISO, out, w, h, seed=seed)


def char(name, desc):
    if (CHARS_OUT / name / "id.txt").exists():
        return name, "exists", 0
    cid, j = p.create_character(name, desc + NO_SHADOW + p.STYLE_CHAR, size=SIZES.get(name, 64))
    p.character_zip(cid, CHARS_OUT / name / "base")
    (CHARS_OUT / name / "id.txt").write_text(cid + "\n")
    return name, cid, (j.get("usage") or {}).get("generations")


def run_jobs(jobs, chars, charset=CHARS, char_fn=char):
    with cf.ThreadPoolExecutor(4) as ex:
        fs = [ex.submit(one, *j) for j in jobs] + [ex.submit(char_fn, n, charset[n]) for n in chars]
        for f in cf.as_completed(fs):
            try:
                r = f.result()
                print("ok", r.name if hasattr(r, "name") else r, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)


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
    run_jobs(jobs, chars)
    print(p.balance()["subscription"])
