"""Иконки умений 32×32, значки состояний и элементы интерфейса (PROMPTS.md 6.1–6.2, 7) через generate-image-v2.

Один запрос на 32×32 даёт 64 варианта. Сначала делается образец (move_attack), выбранный вариант
становится style_image для остальных, чтобы фон и рамка совпадали у всего набора.

    python3 art/tools/icons.py keys [id ...]        # варианты → icons/<id>/variants/NN.png
    python3 art/tools/icons.py pick id:NN [...]     # выбранный → icons/<id>.png
"""
import sys, shutil, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

OUT = p.ROOT / "art" / "prologue" / "icons"
STYLE_ICON = ("pixel art skill icon, 32x32, dark fantasy, centered symbol on a dark stone square background with a thin "
              "bevel border, bold readable silhouette, limited palette")
STYLE_STATUS = "tiny pixel art status icon, 16x16, single bold symbol, no background, bold readable silhouette, limited palette"
REF = OUT / "move_attack.png"
# Умения пролога: базовые, герой 1-го уровня по классу, Ирена, Гаррет (ASSETS.md раздел 5)
SKILLS = {
 "move_attack": "a boot print and a crossed sword",
 "end_turn": "an hourglass",
 "dodge": "a cloak swirling aside",
 "shove": "an open palm pushing",
 "second_wind": "a green-gold breath of air over a heart",
 "disengage": "a footstep moving backward with an arrow",
 "sacred_flame": "a white-gold flame pillar",
 "healing_word": "a glowing golden word sigil over an open hand",
 "fire_bolt": "a small fire bolt",
 "magic_missile": "three violet darts",
 "thunderwave": "a blue shockwave ring",
 "hallowed_ground": "a golden rune circle on stone",
 "shield_of_faith": "a golden shield with a candle-flame emblem",
 "trip": "a boot sweeping a leg",
 "taunt": "a shouting mouth with red sound waves",
}
STATUS = {
 "st_dodging": "grey swirling cloak",
 "st_ac_bonus": "small golden shield with a plus sign",
 "st_taunted": "red exclamation mark",
 "st_prone": "boot upside down, sole up",
 "st_hidden": "half-closed eye in dark shadow",
}

STYLE_UI = ("pixel art game UI element, dark fantasy, weathered dark iron and old dark stone with thin bronze trim, "
            "muted palette, clean straight edges for 9-slice scaling, no text, no letters")
# id: (ширина, высота, описание, прозрачный фон). Стиль — от образца иконки, чтобы рамки совпадали.
UI = {
 "ui_panel": (48, 48, "a rectangular UI panel frame, dark iron border with small rivets at the corners, dark stone interior", False),
 "ui_button": (96, 32, "a wide rectangular button, dark iron frame, dark stone face, empty", False),
 "ui_slot": (40, 40, "an empty square slot frame for an icon, iron border, dark empty interior", False),
 "ui_hpbar": (64, 16, "a thin horizontal empty health bar frame in dark iron, dark empty interior", True),
 "ui_portrait_frame": (72, 72, "an empty square portrait frame in dark iron with bronze corners, hollow transparent center", True),
 "ui_dialog": (192, 64, "a wide dialog text box panel, dark iron border with bronze corner pieces, dark stone interior, empty", False),
 "ui_nameplate": (96, 24, "a small name plate banner, dark iron with bronze trim, empty", False),
 "cursor_pointer": (16, 16, "a mouse cursor arrow shaped like an iron gauntlet pointer, pointing to the upper left", True),
 "cursor_attack": (16, 16, "a small crossed-swords mouse cursor", True),
 "cursor_spell": (16, 16, "a small glowing violet rune mouse cursor", True),
 "menu_bg": (384, 216, "dark mine tunnel descending into blackness, faint torchlight at the top, wooden supports, isometric pixel art background, no characters", False),
}


def key(icon_id):
    is_status = icon_id in STATUS
    if icon_id in UI:
        w, h, d, nobg = UI[icon_id]
        desc = d + ", " + (STYLE_UI if icon_id != "menu_bg" else "dark fantasy, muted desaturated palette")
        body = {"description": desc, "image_size": {"width": w, "height": h}, "no_background": nobg}
    else:
        desc = (STATUS[icon_id] + ", " + STYLE_STATUS) if is_status else (SKILLS[icon_id] + ", " + STYLE_ICON)
        size = 16 if is_status else 32
        body = {"description": desc, "image_size": {"width": size, "height": size}, "no_background": is_status}
    if not is_status and icon_id != "menu_bg" and REF.exists() and icon_id != "move_attack":
        body["style_image"] = {"image": p.b64img(REF), "size": {"width": 32, "height": 32}}
    r = p.call("POST", "/generate-image-v2", body)
    j = p.wait_job(p._job_id(r))
    imgs = (j.get("last_response") or {}).get("images") or []
    for i, im in enumerate(imgs):
        p.save_b64(im, OUT / icon_id / "variants" / f"{i:02d}.png")
    p.log({"kind": "icon", "name": icon_id, "id": p._job_id(r), "frames": len(imgs),
           "cost": (j.get("usage") or {}).get("generations"), "description": desc})
    return len(imgs), (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    cmd, *ids = sys.argv[1:]
    if cmd == "keys":
        todo = [i for i in (ids or list(SKILLS) + list(STATUS) + list(UI)) if not (OUT / i / "variants").exists()]
        with cf.ThreadPoolExecutor(4) as ex:
            for i, r in zip(todo, ex.map(key, todo)):
                print(i, r, flush=True)
    elif cmd == "pick":
        for a in ids:
            i, n = a.split(":")
            shutil.copy(OUT / i / "variants" / f"{n}.png", OUT / f"{i}.png")
