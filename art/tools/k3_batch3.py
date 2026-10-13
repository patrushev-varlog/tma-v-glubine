"""K3, партии 3–4: удар, заклинание и выстрел по скелету (skeleton_anim.py). Готовое пропускается."""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import skeleton_anim as s

JOBS = [(h, "attack") for h in ("hero_fighter_m", "hero_fighter_f", "hero_rogue_m", "hero_rogue_f",
                                 "hero_cleric_m", "hero_cleric_f")]
JOBS += [(h, "cast") for h in ("hero_wizard_f", "hero_cleric_m", "hero_cleric_f")]
JOBS += [("parishioner_m", "attack"), ("parishioner_f", "attack"), ("crossbowman", "shoot"), ("neighbor", "thrust")]


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
