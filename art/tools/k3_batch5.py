"""K3, партия 5: статичные персонажи пролога (PROMPTS.md 4.5) — только стойка, 8 направлений."""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import k3_batch4 as b

STATIC = {
 "spouse_f": "a woman in her early thirties, villager, plain homespun dress, dark wool shawl, chestnut hair loosely pinned up, worried, hands empty, ",
 "spouse_m": "a man in his early thirties, villager, plain linen shirt, dark wool vest, short chestnut hair, short beard, worried, hands empty, ",
 "oldrik": "an old villager man in his seventies, wool cap, sheepskin vest, soot-stained face, white stubble, slightly hunched, hands empty, ",
 "neighbor_woman": "a village woman in her forties, plain dress and apron, head scarf, soot-stained face and apron, hands empty, ",
}
NO_SHADOW = "no ground shadow, no base under the feet, "

if __name__ == "__main__":
    names = sys.argv[1:] or list(STATIC)
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(b.npc, n, STATIC[n] + NO_SHADOW) for n in names]):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
