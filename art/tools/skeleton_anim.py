"""Удар и заклинание по скелету (схема 2a, п. 4) с переносом поз с готового персонажа.

Позы берутся из скелетов кадров первой волны (art/wave1/characters/*/skeletons*.json):
удар — Гаррет `attack`, заклинание — волшебник `cast`. Для каждого сустава считается смещение
от первого кадра образца (стойка), масштабируется по росту и прибавляется к скелету героя в стойке.
Готовые кадры — art/prologue/characters/<герой>/anims/<анимация>/<направление>/NN.png.

    python3 art/tools/skeleton_anim.py hero_fighter_m attack
"""
import json, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p  # noqa: E402

W1 = p.ROOT / "art" / "wave1" / "characters"
PRO = p.ROOT / "art" / "prologue" / "characters"
SOURCES = {
    "attack": (W1 / "garret/unarmed/skeletons2.json", "attack", "swinging an empty fist in a diagonal downward strike"),
    "cast": (W1 / "hero_wizard_evoker/unarmed/skeletons.json", "cast", "raising an empty hand and thrusting it forward to cast a spell"),
}
DIRS = ("south-east", "north-east")
# Направление «вперёд» на экране для изометрии: ЮВ — вправо-вниз, СВ — вправо-вверх.
FORWARD = {"south-east": (1.0, 0.5), "north-east": (1.0, -0.5)}
THRUST_ACTION = "thrusting both empty fists forward from the hip like a spear thrust, lunging forward"


def thrust_keypoints(base, d):
    """Удар копьём от бедра: стойка → кисти к правому бедру → глубже назад → выпад вперёд → держит → стойка.

    base — скелет стойки героя в пикселях. Позы заданы смещениями от бедра и плеч, поэтому
    подходят любому герою обычного роста."""
    fx, fy = FORWARD[d]
    hip = base["RIGHT HIP"] if d == "south-east" else base["LEFT HIP"]  # заднее бедро
    def pose(back, reach, lean, step):
        k = {j: list(v) for j, v in base.items()}
        for j in k:  # корпус наклоняется: верх тела смещается
            if j in ("NOSE", "NECK", "LEFT EYE", "RIGHT EYE", "LEFT EAR", "RIGHT EAR", "LEFT SHOULDER", "RIGHT SHOULDER"):
                k[j][0] += lean * fx; k[j][1] += lean * fy
        if reach is None:  # обе кисти у заднего бедра, локти отведены назад
            for side, ahead in (("RIGHT", 0.0), ("LEFT", 4.0)):
                k[f"{side} ARM"] = [hip[0] + (ahead - back) * fx, hip[1] + 1 + (ahead - back) * fy]
                sh = k[f"{side} SHOULDER"]
                k[f"{side} ELBOW"] = [(sh[0] + k[f"{side} ARM"][0]) / 2 - 3 * fx, (sh[1] + k[f"{side} ARM"][1]) / 2 + 1]
        else:  # руки выброшены вперёд и чуть вниз
            for side, extra in (("RIGHT", 0.0), ("LEFT", 4.0)):
                sh = k[f"{side} SHOULDER"]
                k[f"{side} ARM"] = [sh[0] + (reach + extra) * fx, sh[1] + 9 + (reach + extra) * fy]
                k[f"{side} ELBOW"] = [(sh[0] + k[f"{side} ARM"][0]) / 2, (sh[1] + k[f"{side} ARM"][1]) / 2 + 1]
        if step:  # передняя нога шагает вперёд
            for j in ("LEFT KNEE", "LEFT LEG") if d == "south-east" else ("RIGHT KNEE", "RIGHT LEG"):
                k[j][0] += step * fx; k[j][1] += step * fy
        return k
    poses = [pose(0, None, -1, 0), pose(2, None, -2, 0), pose(0, 9, 2, 3), pose(0, 10, 2, 3), pose(0, 4, 1, 1),
             {j: list(v) for j, v in base.items()}]
    return [[{"x": min(max(x / SIZE, 0), 1), "y": min(max(y / SIZE, 0), 1), "label": j} for j, (x, y) in p_.items()]
            for p_ in poses]
SIZE = 64
SHOOT_ACTION = "raising the crossbow to the shoulder, aiming forward and shooting, small recoil"


def shoot_keypoints(base, d):
    """Выстрел из арбалета: стойка → арбалет вверх → прицел у плеча → отдача → прицел → стойка.

    Обе кисти поднимаются к уровню плеча и выносятся вперёд; при отдаче корпус и кисти уходят назад."""
    fx, fy = FORWARD[d]
    def pose(lift, reach, lean):
        k = {j: list(v) for j, v in base.items()}
        for j in ("NOSE", "NECK", "LEFT EYE", "RIGHT EYE", "LEFT EAR", "RIGHT EAR", "LEFT SHOULDER", "RIGHT SHOULDER"):
            k[j][0] += lean * fx; k[j][1] += lean * fy
        for side, extra in (("RIGHT", 0.0), ("LEFT", 4.0)):
            w = k[f"{side} ARM"]
            sh = k[f"{side} SHOULDER"]
            w[0] += (reach + extra * (lift > 0)) * fx
            w[1] += (reach + extra * (lift > 0)) * fy - lift * (w[1] - sh[1] - 2)
            k[f"{side} ELBOW"] = [(sh[0] + w[0]) / 2 - 1.5 * fx, (sh[1] + w[1]) / 2 + 2]
        return k
    poses = [pose(0.5, 1, 0), pose(1.0, 3, 0), pose(1.0, 1, -1.5), pose(1.0, 3, 0), pose(0.4, 1, 0),
             {j: list(v) for j, v in base.items()}]
    return [[{"x": min(max(x / SIZE, 0), 1), "y": min(max(y / SIZE, 0), 1), "label": j} for j, (x, y) in p_.items()]
            for p_ in poses]


def _frames(ref, anim, d):
    n = 0
    while f"{anim}/{d}/{n}" in ref:
        n += 1
    return [ref[f"{anim}/{d}/{i}"] for i in range(n)]


def _height(sk):
    """Рост по скелету: от носа до средней точки лодыжек (в пикселях)."""
    get = (lambda j: sk[j][:2]) if isinstance(sk, dict) else (lambda j: sk[j])
    return (get("LEFT LEG")[1] + get("RIGHT LEG")[1]) / 2 - get("NOSE")[1]


def estimate(img):
    r = p.call("POST", "/estimate-skeleton", {"image": p.b64img(img)})
    return {k["label"]: (k["x"] * SIZE, k["y"] * SIZE) for k in r["keypoints"]}


def transfer(ref_base, ref_frames, hero_base):
    s = _height(hero_base) / _height(ref_base)
    out = []
    for fr in ref_frames:
        kp = []
        for j, (hx, hy) in hero_base.items():
            if j not in fr or j not in ref_base:
                dx = dy = 0.0
            else:
                dx, dy = fr[j][0] - ref_base[j][0], fr[j][1] - ref_base[j][1]
            x = min(max((hx + s * dx) / SIZE, 0.0), 1.0)
            y = min(max((hy + s * dy) / SIZE, 0.0), 1.0)
            kp.append({"x": x, "y": y, "label": j})
        out.append(kp)
    return out


def hero_description(name):
    for l in reversed(p.LOG.read_text().splitlines()):  # последняя версия персонажа
        e = json.loads(l)
        if e.get("kind") == "character" and e["name"] == name:
            desc = e.get("description") or p.call("GET", f"/characters/{e['id']}")["prompt"]
            return desc.split(", pixel art game sprite")[0]
    raise KeyError(name)


def run(hero, anim, dirs=DIRS, seed=0, root=PRO):
    if anim in ("thrust", "shoot"):
        src, key, action = None, None, THRUST_ACTION if anim == "thrust" else SHOOT_ACTION
    else:
        src, key, action = SOURCES[anim]
        ref = json.loads(Path(src).read_text())
    desc = hero_description(hero)
    results = {}
    for d in dirs:
        rot = root / hero / "base" / "Idle" / "rotations" / f"{d}.png"
        hero_base = estimate(rot)
        if anim in ("thrust", "shoot"):
            kps = (thrust_keypoints if anim == "thrust" else shoot_keypoints)(hero_base, d)
        else:
            frames = _frames(ref, key, d)
            ref_base = frames[0]  # первый кадр — стойка; холсты стойки и удара у образцов разного размера
            kps = transfer(ref_base, frames, hero_base)
        body = {"description": desc, "action": action, "direction": d, "view": "low top-down",
                "first_frame": p.b64img(rot),
                "first_frame_keypoints": [{"x": x / SIZE, "y": y / SIZE, "label": j} for j, (x, y) in hero_base.items()],
                "keypoints": kps, "seed": seed, "no_background": True}
        r = p.call("POST", "/animate-with-skeleton-v3", body)
        j = p.wait_job(p._job_id(r), every=10, limit=1200)
        imgs = (j.get("last_response") or {}).get("images") or []
        out = root / hero / "anims" / anim / d
        for i, im in enumerate(imgs):
            p.save_b64(im, out / f"{i:02d}.png")
        (out / "keypoints.json").write_text(json.dumps({"base": hero_base, "frames": kps}))
        p.log({"kind": "skeleton_anim", "name": f"{hero}/{anim}/{d}", "id": p._job_id(r), "status": j.get("status"),
               "frames": len(imgs), "cost": (j.get("usage") or {}).get("generations")})
        results[d] = (j.get("status"), len(imgs))
    return results


if __name__ == "__main__":
    print(run(sys.argv[1], sys.argv[2]))
