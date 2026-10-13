"""Оружие на кадры анимации (схема 2a, пп. 5–6).

Тело героя генерируется без оружия; оружие — отдельный вертикальный спрайт. По каждому кадру
`estimate-skeleton` даёт локоть и кисть правой руки; оружие поворачивается вокруг точки хвата и
ставится в кисть, кулак рисуется поверх рукояти. Угол = направление предплечья + поправка,
подобранная так, чтобы в стойке клинок смотрел вперёд с наклоном вниз (ЮВ 105°, СВ 75°;
0° — вверх, по часовой). Удар ЮВ идёт по кривой из 2a.

Результат: art/prologue/characters/<герой>/composited/<анимация>/<направление>/NN.png, холст 96×96
(кадр 64×64 со сдвигом 16, чтобы оружие не обрезалось). Скелеты кадров кешируются в skeletons.json.

    python3 art/tools/compose.py hero_fighter_m
"""
import json, math, sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p  # noqa: E402

A = p.ROOT / "art"
PRO = A / "prologue" / "characters"
PAD = 16
STANCE = {"south-east": 105.0, "north-east": 75.0}
STANCE_STAFF = {"south-east": 15.0, "north-east": 15.0}  # посох в стойке почти вертикален, как у волшебника первой волны
ATTACK_SE = [105, -40, -10, 50, 125, 105]

WEAPONS = {
    "longsword": (A / "wave1/characters/garret/unarmed/sword.png", 1, "blade"),
    "shortsword": (A / "prologue/weapons/shortsword_v_5.png", 2, "blade"),
    "mace": (A / "prologue/weapons/mace_v_5.png", 2, "mace"),
    "staff": (A / "wave1/characters/hero_wizard_evoker/weapon.png", 1, "staff"),
}
HERO_WEAPON = {"fighter": "longsword", "rogue": "shortsword", "cleric": "mace", "wizard": "staff"}


def weapon(name):
    """Обрезанный спрайт оружия и точка хвата (x, y) в нём."""
    f, step, rule = WEAPONS[name]
    im = Image.open(f).convert("RGBA")
    if step > 1:  # исходник нарисован крупными пикселями 2×2
        im = im.resize((im.width // step, im.height // step), Image.NEAREST)
    im = im.crop(im.getbbox())
    a = np.array(im)[..., 3] > 0
    widths = a.sum(1)
    h = im.height
    if rule == "blade":
        guard = int(np.argmax(widths))
        gy = min(guard + 3, h - 1)
    elif rule == "mace":
        gy = int(round(0.72 * h))
    else:
        gy = h // 2
    xs = np.nonzero(a[gy])[0]
    gx = (xs.min() + xs.max()) / 2 if len(xs) else im.width / 2
    return im, (gx, gy)


def skeleton(img, cache, key):
    if key not in cache:
        r = p.call("POST", "/estimate-skeleton", {"image": p.b64img(img)})
        w, h = Image.open(img).size
        cache[key] = {k["label"]: [k["x"] * w, k["y"] * h] for k in r["keypoints"]}
    return cache[key]


def forearm_angle(sk):
    ex, ey = sk["RIGHT ELBOW"]
    wx, wy = sk["RIGHT ARM"]
    return math.degrees(math.atan2(wx - ex, -(wy - ey)))  # 0 — вверх, по часовой


def place(frame, wimg, grip, wrist, angle):
    """Кадр 96×96: тело, оружие поворотом вокруг хвата в кисти, кулак поверх."""
    body = Image.open(frame).convert("RGBA")
    ox = PAD - (body.width - 64) // 2
    oy = PAD - (body.height - 64) // 2
    out = Image.new("RGBA", (64 + 2 * PAD, 64 + 2 * PAD))
    out.alpha_composite(body, (ox, oy))
    R = int(math.hypot(wimg.width, wimg.height)) + 2
    big = Image.new("RGBA", (2 * R, 2 * R))
    big.alpha_composite(wimg, (int(round(R - grip[0])), int(round(R - grip[1]))))
    rot = big.rotate(-angle, resample=Image.NEAREST, center=(R, R))
    wx, wy = wrist[0] + ox, wrist[1] + oy
    out.alpha_composite(rot, (int(round(wx - R)), int(round(wy - R))))
    # кулак поверх рукояти: пиксели тела в радиусе 2 от кисти
    b = np.array(body)
    o = np.array(out)
    for y in range(max(0, int(wrist[1]) - 2), min(body.height, int(wrist[1]) + 3)):
        for x in range(max(0, int(wrist[0]) - 2), min(body.width, int(wrist[0]) + 3)):
            if b[y, x, 3] and (x - wrist[0]) ** 2 + (y - wrist[1]) ** 2 <= 5:
                o[y + oy, x + ox] = b[y, x]
    return Image.fromarray(o)


def frames_of(hero):
    """{(анимация, направление): [кадры]} — шаблонные из выгрузки PixelLab и скелетные из anims/."""
    res = {}
    names = {"breathing_idle": "idle", "walking": "walk", "taking_a_punch": "hit", "falling_backward": "down"}
    for d in (PRO / hero / "pixellab").rglob("animations/*/*"):
        if not d.is_dir():
            continue
        anim = d.parent.name
        anim = names.get(anim, anim)
        res[(anim, d.name)] = sorted(d.glob("*.png"))
    for d in (PRO / hero / "anims").glob("*/*"):
        res[(d.parent.name, d.name)] = sorted(d.glob("*.png"))
    return res


def run(hero):
    cls = hero.split("_")[1]
    wimg, grip = weapon(HERO_WEAPON[cls])
    cache_f = PRO / hero / "skeletons.json"
    cache = json.loads(cache_f.read_text()) if cache_f.exists() else {}
    fr = frames_of(hero)
    offsets = {}
    for d in STANCE:
        idle = fr.get(("idle", d))
        if not idle:
            continue
        sk = skeleton(idle[0], cache, f"idle/{d}/0")
        offsets[d] = (STANCE_STAFF if cls == "wizard" else STANCE)[d] - forearm_angle(sk)
    done = 0
    for (anim, d), files in sorted(fr.items()):
        if d not in offsets:
            continue
        for i, f in enumerate(files):
            sk = skeleton(f, cache, f"{anim}/{d}/{i}")
            ang = forearm_angle(sk) + offsets[d]
            if anim == "attack" and d == "south-east" and len(files) == len(ATTACK_SE):
                ang = ATTACK_SE[i]
            out = PRO / hero / "composited" / anim / d / f"{i:02d}.png"
            out.parent.mkdir(parents=True, exist_ok=True)
            place(f, wimg, grip, sk["RIGHT ARM"], ang).save(out)
            done += 1
        cache_f.write_text(json.dumps(cache))
    return done


if __name__ == "__main__":
    for h in sys.argv[1:]:
        print(h, run(h))
