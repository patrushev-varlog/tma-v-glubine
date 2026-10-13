"""K3, партия 2: шаблонные анимации героев (стойка, ходьба, урон, выбывание), SE и NE.

    python3 art/tools/k3_batch2.py                 # все герои
    python3 art/tools/k3_batch2.py crossbowman ...  # перечисленные персонажи

Повторный запуск доделывает недостающее: что уже есть, смотрится в самом персонаже в PixelLab.
"""
import sys, json, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue" / "characters"
TEMPLATES = {"idle": "breathing-idle", "walk": "walking-6-frames", "hit": "taking-punch", "down": "falling-back-death"}
DIRS = ("south-east", "north-east")


def heroes(names=None):
    """Последний id каждого персонажа из журнала: герои или перечисленные имена."""
    ids = {}
    for l in p.LOG.read_text().splitlines():
        e = json.loads(l)
        if e.get("kind") == "character" and (e["name"] in names if names else e["name"].startswith("hero_")):
            ids[e["name"]] = e["id"]
    return ids


def todo(cid):
    c = p.call("GET", f"/characters/{cid}")
    have = {}
    for a in c.get("animations") or []:
        have.setdefault(a["animation_type"], (a["animation_group_id"], {d["direction"] for d in a["directions"]}))
    for anim, tpl in TEMPLATES.items():
        group, dirs = have.get(tpl, (None, set()))
        missing = [d for d in DIRS if d not in dirs]
        if missing:
            yield anim, tpl, missing, group


def run(name, cid, anim, tpl, missing, group):
    gid, jobs = p.animate_template(name, cid, anim, tpl, missing, group)
    return name, anim, missing, [j.get("status") for j in jobs]


if __name__ == "__main__":
    H = heroes(sys.argv[1:])
    tasks = [(n, c, *t) for n, c in H.items() for t in todo(c)]
    print(len(tasks), "задач", flush=True)
    with cf.ThreadPoolExecutor(4) as ex:
        for f in cf.as_completed([ex.submit(run, *t) for t in tasks]):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
    for n, c in H.items():
        p.character_zip(c, OUT / n / "pixellab")
    print(p.balance()["subscription"])
