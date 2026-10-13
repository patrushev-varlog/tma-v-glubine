"""K3, партия 4: прихожане-мертвецы, арбалетчик, сосед с вилами (PROMPTS.md 4.5).

Прихожане и сосед — по схеме 2a без оружия (вилы ставятся compose.py). Арбалет держится двумя
руками и в кисть одной точкой не ставится, поэтому арбалетчик генерируется сразу с арбалетом.
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue" / "characters"
EMPTY = "both hands empty, no weapon in hands, "

NPCS = {
 "parishioner_m": "a freshly risen village parishioner corpse, middle-aged man, simple clean Sunday tunic and a wool shawl, grey-green skin, slack jaw, empty eyes with a faint green glint, arms reaching forward, shambling pose, " + EMPTY,
 "parishioner_f": "a freshly risen old village woman corpse, dark Sunday dress and a white head scarf, grey-green skin, empty eyes with a faint green glint, arms reaching forward, shambling pose, " + EMPTY,
 "crossbowman": "a human mine overseer holding a loaded crossbow in both hands at waist level, black padded jacket with a dull-red iron crown-in-circle badge, bolt quiver on the right hip, leather cap, stern, ",
 "neighbor": "a middle-aged male villager in a long white nightshirt and boots, tousled hair, scared but resolute, fists clenched, " + EMPTY,
}


def npc(name, desc):
    cid, j = p.create_character(name, desc + p.STYLE_CHAR)
    p.character_zip(cid, OUT / name / "base")
    return name, cid, (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    names = sys.argv[1:] or list(NPCS)
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(npc, n, NPCS[n]) for n in names]):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
