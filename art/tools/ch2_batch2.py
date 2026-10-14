"""Глава 2, партия 2 (после проб, «Запускай» Валерия 14.10.2026): остальные предметы затопленных выработок
и основы шести персонажей. Как ch2_batch1.py: предметы по два seed в variants/, персонажи — основы в стиле Гаррета.

    python3 art/tools/ch2_batch2.py [tiles|chars|имя ...]     # --reroll имя... — ещё seed 3 и 4
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p
from k3_batch6 import ISO, FLAT
from ch1_batch2 import NO_SHADOW, EMPTY
from ch2_batch1 import TILES, CHARS_OUT, FLOOD, one

SETS = {
 "flooded": {
  "tiles": {
   "floor_deep": FLAT + "very dark deep black water surface, almost no detail, faint ripples, no rim, no border, no stones, seamless edges",
  },
  "objects": {
   "cellar_door": (FLOOD + "an old wooden storeroom door set in a rough rock wall, half sunk in black water so that only its upper half and the stone lintel show above the surface", 64, 96),
   "pipes": (FLOOD + "a straight section of two thick rusty iron pipes lying side by side on short stone supports, riveted joints, water dripping", 64, 64),
   "crates": (FLOOD + "a stack of three wooden smuggler crates with rope handles and a branded mark, one crate open with straw", 64, 64),
   "brazier": (FLOOD + "an iron brazier on three legs with glowing coals and small warm flames", 32, 64),
   "bedding": (FLOOD + "an abandoned sleeping spot on a rock ledge: a sackcloth mat, a burnt-down candle stub and an empty tin flask, flat on the ground", 64, 64),
   "small_lever": (FLOOD + "a small rusty iron lever set in a carved stone block, wrapped three times in a heavy rusted chain, a single angular dwarven rune above it", 32, 64),
   "grate": (FLOOD + "a heavy iron grate set in a carved stone wall arch, black water standing behind the bars, silt stains", 64, 96),
   "stairs": (FLOOD + "wide ancient dwarven stone stairs going down into darkness, short broad steps, wet, seen from above, flat on the ground, the stair opening fills the canvas", 64, 64),
   "rune_pillar": (FLOOD + "a square carved dwarven stone pillar with angular runes, the lower part wet and covered in silt and weed", 64, 96),
  },
 },
}
CHARS = {
 "drowned_f": "a drowned undead woman risen from black mine water, bloated grey-blue skin, soaked rags of a sackcloth dress dripping water, long wet hair over the face, milky white eyes, strands of dark weed, reaching forward with bare hands, ",
 "smuggler": "a rough human smuggler, oiled leather jerkin over a striped shirt, rolled sleeves, knit cap, scarred face, short curved cutlass in the right hand, ",
 "tobin": "a stooped gaunt male escaped mine prisoner in his forties, ragged grey sackcloth shirt, one arm bandaged in a dirty sling, stubble, tired wary eyes, " + EMPTY,
 "boatman": "a heavy-set human boatman in a waxed oilskin coat and wide-brimmed hat, rope coiled over the shoulder, weathered face, " + EMPTY,
 "shrine_priest": "an undead drowned priest in heavy waterlogged dark vestments, face almost gone, white fish-like eyes, holding a long three-pronged fishing spear trident upright in both hands, river weed hanging from the robe, ",
 "sluice_guardian": "a huge hulking undead giant stitched together from several drowned bodies with thick iron wire, grey-blue bloated skin, extra arms fused into the torso, a heavy iron collar with a broken chain on its neck, enormous fists, ",
}
SIZES = {"sluice_guardian": 96}


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
    if args[:1] == ["--reroll"]:
        names = set(args[1:])
        jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                if n in names for seed in (3, 4)]
    else:
        what = args or ["tiles", "chars"]
        if "tiles" in what:
            jobs = [(k, s, n, sp, seed) for s in SETS for k in ("tiles", "objects") for n, sp in SETS[s][k].items()
                    for seed in ((3, 4) if n == "floor_deep" else (1, 2))]
        chars = [n for n in CHARS if "chars" in what or n in what]
    with cf.ThreadPoolExecutor(4) as ex:
        fs = [ex.submit(one, *j) for j in jobs] + [ex.submit(char, n, CHARS[n]) for n in chars]
        for f in cf.as_completed(fs):
            try:
                r = f.result()
                print("ok", r.name if hasattr(r, "name") else r, flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
