"""K3, партия 3: удар и заклинание героев по скелету (skeleton_anim.py)."""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import skeleton_anim as s

JOBS = [(h, "attack") for h in ("hero_fighter_m", "hero_fighter_f", "hero_rogue_m", "hero_rogue_f",
                                 "hero_cleric_m", "hero_cleric_f")]
JOBS += [(h, "cast") for h in ("hero_wizard_f", "hero_cleric_m", "hero_cleric_f")]


def one(h, a, d):
    if (s.PRO / h / "anims" / a / d / "05.png").exists():
        return h, a, d, "есть"
    return h, a, d, s.run(h, a, dirs=(d,))


if __name__ == "__main__":
    with cf.ThreadPoolExecutor(2) as ex:
        fs = [ex.submit(one, h, a, d) for h, a in JOBS for d in s.DIRS]
        for f in cf.as_completed(fs):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
