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
# Посох (вариант C, 2026-10-13): в левой руке, с другой стороны от лица, почти вертикально,
# хват ниже середины. Удар — копьём от бедра: посох в обеих руках, навершие вперёд.
STANCE_STAFF = {"south-east": 12.0, "north-east": -12.0}
STAFF_HAND, STAFF_GRIP = "LEFT ARM", 0.62
FORWARD_ANGLE = {"south-east": 116.6, "north-east": 63.4}  # «вперёд» в изометрии, 0° — вверх
ATTACK_SE = [105, -40, -10, 50, 125, 105]

WEAPONS = {
    "longsword": (A / "wave1/characters/garret/unarmed/sword.png", 1, "blade"),
    "shortsword": (A / "prologue/weapons/shortsword_v_5.png", 2, "blade"),
    "mace": (A / "prologue/weapons/mace_v_5.png", 2, "mace"),
    "staff": (A / "wave1/characters/hero_wizard_evoker/weapon.png", 1, "staff"),
    "pitchfork": (A / "prologue/weapons/pitchfork_v_6.png", 59 / 44, "staff"),  # до роста посоха
}
HERO_WEAPON = {"fighter": "longsword", "rogue": "shortsword", "cleric": "mace", "wizard": "staff"}
# Персонажи вне классов героев: оружие, рука, держится ли как посох (вертикально, удар копьём).
NPC_WEAPON = {"neighbor": ("pitchfork", "RIGHT ARM")}
STANCE_POLE = {"south-east": -25.0, "north-east": 25.0}  # древко в правой руке, по другую сторону от лица


def weapon(name):
    """Обрезанный спрайт оружия и точка хвата (x, y) в нём."""
    f, step, rule = WEAPONS[name]
    im = Image.open(f).convert("RGBA")
    if step != 1:  # исходник крупнее нужного (у мечей и булавы — пиксели 2×2)
        im = im.resize((round(im.width / step), round(im.height / step)), Image.NEAREST)
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
        gy = int(round(STAFF_GRIP * h))
    xs = np.nonzero(a[gy])[0]
    gx = (xs.min() + xs.max()) / 2 if len(xs) else im.width / 2
    return im, (gx, gy)


def skeleton(img, cache, key):
    if key not in cache:
        r = p.call("POST", "/estimate-skeleton", {"image": p.b64img(img)})
        w, h = Image.open(img).size
        cache[key] = {k["label"]: [k["x"] * w, k["y"] * h] for k in r["keypoints"]}
    return cache[key]


def forearm_angle(sk, side="RIGHT"):
    ex, ey = sk[f"{side} ELBOW"]
    wx, wy = sk[f"{side} ARM"]
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
    if hero in NPC_WEAPON:
        wname, hand = NPC_WEAPON[hero]
        pole, stance = True, STANCE_POLE
    else:
        cls = hero.split("_")[1]
        wname = HERO_WEAPON[cls]
        pole = cls == "wizard"
        hand = STAFF_HAND if pole else "RIGHT ARM"
        stance = STANCE_STAFF if pole else STANCE
    wimg, grip = weapon(wname)
    side = hand.split()[0]
    mid_grip = (wimg.width / 2, 0.6 * wimg.height)
    cache_f = PRO / hero / "skeletons.json"
    cache = json.loads(cache_f.read_text()) if cache_f.exists() else {}
    fr = frames_of(hero)
    offsets = {}
    for d in STANCE:
        idle = fr.get(("idle", d))
        if not idle:
            continue
        sk = skeleton(idle[0], cache, f"idle/{d}/0")
        offsets[d] = stance[d] - forearm_angle(sk, side)
    done = 0
    for (anim, d), files in sorted(fr.items()):
        if d not in offsets:
            continue
        for i, f in enumerate(files):
            sk = skeleton(f, cache, f"{anim}/{d}/{i}")
            ang = forearm_angle(sk, side) + offsets[d]
            wrist, g = sk[hand], grip
            if anim == "attack" and d == "south-east" and len(files) == len(ATTACK_SE):
                ang = ATTACK_SE[i]
            if anim == "thrust" and 0 < i < len(files) - 1:  # обе руки на древке
                wrist = [(sk["RIGHT ARM"][k] + sk["LEFT ARM"][k]) / 2 for k in (0, 1)]
                ang, g = FORWARD_ANGLE[d], mid_grip
            elif anim == "thrust":
                ang = stance[d]
            elif anim == "hit" and pole:  # шаблон урона крутит предплечье, древко держим ровно
                ang = stance[d]
            out = PRO / hero / "composited" / anim / d / f"{i:02d}.png"
            out.parent.mkdir(parents=True, exist_ok=True)
            place(f, wimg, g, wrist, ang).save(out)
            done += 1
        cache_f.write_text(json.dumps(cache))
    return done


if __name__ == "__main__":
    for h in sys.argv[1:]:
        print(h, run(h))
