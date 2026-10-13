"""Эффекты умений (PROMPTS.md 5): ключевой кадр через generate-image-v2 (16 вариантов на 64×64),
затем анимация от выбранного кадра через animate-with-text-v3.

    python3 art/tools/fx.py key fire_hit            # варианты ключевого кадра → fx/<id>/keys/NN.png
    python3 art/tools/fx.py anim fire_hit 03        # анимация от keys/03.png → fx/<id>/frames/NN.png
"""
import sys, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue" / "fx"
STYLE_FX = ("pixel art visual effect, isometric view, bright saturated magic colors against transparency, "
            "hard pixels, no anti-aliasing, transparent background")
FADE = "then fades away completely"
GROUND = "flat on the ground, seen in isometric perspective as a wide flat ellipse"
# id: (размер, ключевой кадр, движение анимации или None для статичного, кадров). Умения — ASSETS.md раздел 3.
FX = {
 "fire_hit": ((64, 64), "small fiery burst impact, orange and yellow flames exploding outward at the moment of impact",
              "the fiery burst expands a little, then breaks into embers and thin smoke that fade away completely", 8),
 "fire_bolt": ((32, 32), "small fire bolt projectile flying to the right with a short ember trail, horizontal",
               "the flames of the bolt flicker and the ember trail shimmers, looping", 4),
 "magic_missile": ((32, 32), "single glowing violet magic dart flying to the right, horizontal, small violet glow trail",
                   "the violet dart pulses and its glow trail shimmers, looping", 4),
 "thunderwave": ((128, 64), "expanding shockwave ring of pale blue distorted air, " + GROUND,
                 "the shockwave ring expands outward quickly, " + FADE, 8),
 "sacred_flame": ((64, 64), "a pillar of radiant white-gold holy fire descending onto the ground",
                  "the pillar of holy fire flares brightly, then rises into golden sparks and " + FADE, 8),
 "healing_word": ((64, 64), "soft golden healing sparkles rising in a spiral",
                  "the golden sparkles rise upward in a spiral and " + FADE, 8),
 "hallowed_ground": ((128, 64), "glowing circle of golden holy runes, " + GROUND,
                     "the golden runes pulse softly with light, looping", 8),
 "shield_of_faith": ((64, 64), "faint translucent golden shield dome, empty inside",
                     "the translucent golden dome shimmers gently, looping", 8),
 "second_wind": ((64, 64), "quick warm green-gold burst of renewed vigor rising upward, empty center",
                 "the green-gold burst rises upward and " + FADE, 8),
 "dust_trail": ((64, 32), "small trail of brown dust puffs kicked up behind running feet",
                "the dust puffs drift backward, spread and " + FADE, 6),
 "dust_puff": ((64, 32), "small dust puff impact on the ground",
               "the dust puff spreads outward and " + FADE, 6),
 "taunt": ((128, 64), "red shouting shockwave ripple, " + GROUND,
           "the red ripple expands outward and " + FADE, 6),
 "hit_spark": ((32, 32), "small white-yellow weapon impact spark", "the spark flashes, " + FADE, 4),
 "crit": ((48, 48), "larger red-white impact burst with a star shape", "the star burst flashes bigger, " + FADE, 6),
 "miss": ((32, 32), "small grey whoosh arc of a missed swing", "the grey arc sweeps and " + FADE, 4),
 "blood": ((32, 32), "small dark-red blood splatter, minimal", "the droplets fly out and " + FADE, 4),
 "bone_hit": ((32, 32), "bone chips and dust burst", "the bone chips fly out and " + FADE, 4),
 "undead_death": ((64, 64), "pile of bones collapsing into dust with a fading cold blue wisp rising",
                  "the bones crumble into dust while the cold blue wisp rises and " + FADE, 8),
 "arrow": ((16, 16), "single wooden arrow in flight, perfectly horizontal, pointing to the right", None, 0),
 "bolt": ((16, 16), "single short crossbow bolt in flight, perfectly horizontal, pointing to the right", None, 0),
 "roof_fire": ((64, 64), "bright flames burning on a thatched roof, a patch of fire with sparks, no roof visible",
               "the flames flicker and dance with rising sparks, looping", 8),
}


def key(fx_id, seed=None):
    (w, h), desc, _, _ = FX[fx_id]
    body = {"description": desc + ", " + STYLE_FX, "image_size": {"width": w, "height": h}, "no_background": True}
    if seed is not None:
        body["seed"] = seed
    r = p.call("POST", "/generate-image-v2", body)
    j = p.wait_job(p._job_id(r))
    imgs = (j.get("last_response") or {}).get("images") or []
    for i, im in enumerate(imgs):
        p.save_b64(im, OUT / fx_id / "keys" / f"{i:02d}.png")
    p.log({"kind": "fx_key", "name": fx_id, "id": p._job_id(r), "frames": len(imgs),
           "cost": (j.get("usage") or {}).get("generations"), "description": desc})
    return len(imgs), (j.get("usage") or {}).get("generations")


def anim(fx_id, key_no, seed=None):
    (w, h), _, action, n = FX[fx_id]
    first = OUT / fx_id / "keys" / f"{key_no}.png"
    body = {"first_frame": p.b64img(first), "action": action, "frame_count": n, "no_background": True}
    if seed is not None:
        body["seed"] = seed
    r = p.call("POST", "/animate-with-text-v3", body)
    j = p.wait_job(p._job_id(r))
    imgs = (j.get("last_response") or {}).get("images") or []
    out = OUT / fx_id / "frames"
    for f in out.glob("*.png"):
        f.unlink()
    for i, im in enumerate(imgs):
        p.save_b64(im, out / f"{i:02d}.png")
    p.log({"kind": "fx_anim", "name": fx_id, "id": p._job_id(r), "key": key_no, "frames": len(imgs),
           "cost": (j.get("usage") or {}).get("generations"), "description": action})
    return len(imgs), (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    import concurrent.futures as cf
    cmd, *ids = sys.argv[1:]
    if cmd == "keys":  # все, у кого ещё нет keys/
        todo = [i for i in (ids or FX) if not (OUT / i / "keys").exists()]
        with cf.ThreadPoolExecutor(4) as ex:
            for i, r in zip(todo, ex.map(key, todo)):
                print(i, r, flush=True)
    elif cmd == "anims":  # пары id:номер ключа
        pairs = [a.split(":") for a in ids]
        with cf.ThreadPoolExecutor(4) as ex:
            for (i, k), r in zip(pairs, ex.map(lambda a: anim(*a), pairs)):
                print(i, k, r, flush=True)
    else:
        fx_id, *rest = ids
        print(key(fx_id) if cmd == "key" else anim(fx_id, rest[0]))
