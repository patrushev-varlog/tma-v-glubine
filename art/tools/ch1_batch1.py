"""Глава 1, партия 1: тайлсет Верхних шахт (PROMPTS.md 3.2) — пробы перед массовой генерацией.

Каждый ассет — два seed в art/chapter1/tiles/<набор>/variants/<имя>_<seed>.png; отобранный копируется
в art/chapter1/tiles/<набор>/<имя>.png. Утверждённые якоря (пол и крепь, art/anchors/approved) не генерируются.

    python3 art/tools/ch1_batch1.py [набор ...]       # --reroll имя... — ещё seed 3 и 4
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO, FLAT

TILES = p.ROOT / "art" / "chapter1" / "tiles"
MINE = "inside a dark underground mine tunnel, dim warm oil lamp light, cold grey stone, "
SETS = {
 "mines": {
  "tiles": {
   "floor_stone": FLAT + "rough grey mine tunnel stone floor with rock dust and small ore fragments, dim torchlight, low contrast, seamless edges",
   "floor_rails": FLAT + "rough grey mine tunnel stone floor with a section of narrow minecart rails on wooden sleepers running straight across the tile diagonally, dim, low contrast, seamless edges",
   "floor_planks": FLAT + "floor made entirely of long parallel worn brown wooden planks laid side by side, a mine walkway, no stone visible, dim, low contrast, seamless edges",
   "floor_gravel": FLAT + "grey mine stone floor with a crack and loose gravel, dim, low contrast, seamless edges",
  },
  "objects": {
   "minecart": (MINE + "rusty iron minecart full of dark ore standing on short rails", 64, 64),
   "ore_heap": (MINE + "heap of raw dark ore and broken grey rock, the heap fills the canvas", 64, 64),
   "rockfall": (MINE + "collapsed rock pile of large grey boulders and broken timber blocking the way, the pile fills the canvas", 64, 64),
   "scaffold": (MINE + "wooden scaffolding platform with a ladder, rough planks, rope lashings", 64, 96),
   "cage": (MINE + "tall square cage built of vertical rusty iron bars with a flat iron top, big enough for one standing man, empty, door open, a small wooden plank sign hanging on the bars, freestanding, no walls, no lamp", 64, 96),
   "winch": (MINE + "large wooden mine lift winch with a big rope drum, iron gears and a long lever, a dull red crown-in-circle emblem on the frame", 96, 96),
  },
 },
 # Партия 3: бараки, караулка, подъёмник и закоулки (после того как тайлсет приняли).
 "mines2": {
  "tiles": {
   "floor_shaft": FLAT + "edge of a mine shaft: black bottomless void filling most of the tile with a strip of rough stone floor and a thick wooden beam along one edge, dim, seamless edges",
  },
  "objects": {
   "bars": (MINE + "straight section of a prison wall made of thick vertical rusty iron bars set in a wooden beam at top and bottom, no door", 64, 96),
   "bunk": (MINE + "rough wooden prisoner bunk bed with two levels of bare planks and a dirty blanket", 64, 64),
   "lift_cage": (MINE + "large iron lift cage of riveted bars hanging on four heavy chains, open front gate, big enough for a cart, the cage fills the canvas", 128, 128),
   "boards": (MINE + "a tunnel opening in a rock wall boarded up with old nailed wooden planks, darkness between the planks", 64, 96),
   "notice_board": (MINE + "wooden notice board on two posts with pinned paper lists of names", 64, 64),
   "guard_hut": (MINE + "small wooden guard hut with a slanted plank roof and a little window with bars, a lantern by the door, the hut fills the canvas", 96, 96),
   "tag_box": (MINE + "small open wooden box full of round copper tags on strings", 32, 32),
   "lamp_post": (MINE + "a single wooden post with an iron oil lamp burning warm yellow", 32, 64),
  },
 },
}


def one(kind, s, name, spec, seed):
    out = TILES / s / "variants" / f"{name}_{seed}.png"
    if out.exists():
        return out
    if kind == "tiles":
        return p.iso_tile(name, spec + ", " + p.STYLE_ISO, out, seed=seed)
    d, w, h = spec
    return p.map_object(name, d + ", " + ISO + p.STYLE_ISO, out, w, h, seed=seed)


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        sets = args or list(SETS)
        jobs = [(k, s, n, sp, seed) for s in sets for k in ("tiles", "objects") for n, sp in SETS[s][k].items() for seed in (1, 2)]
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(one, *j) for j in jobs]):
            try:
                print("ok", f.result().name, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
