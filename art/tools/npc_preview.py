"""Превью анимаций персонажей партии 4 → art/prologue/previews/npcs_anim.png (ЮВ и СВ по строкам)."""
from pathlib import Path
from PIL import Image, ImageDraw

P = Path(__file__).resolve().parents[1] / "prologue" / "characters"
NAMES = {"idle": "breathing_idle", "walk": "walking", "hit": "taking_a_punch", "down": "falling_backward"}
CHARS = [("parishioner_m", "attack"), ("parishioner_f", "attack"), ("crossbowman", "shoot"), ("neighbor", "thrust")]


def frames(n, anim, d):
    comp = P / n / "composited" / anim / d
    if comp.exists():
        return sorted(comp.glob("*.png"))
    if anim in NAMES:
        return sorted((P / n / "pixellab/Idle/animations" / NAMES[anim] / d).glob("*.png"))
    return sorted((P / n / "anims" / anim / d).glob("*.png"))


def main(S=2, C=144):
    rows = [(f"{n} {d[:5]}", [(a, frames(n, a, d)) for a in ("idle", att, "hit", "down")])
            for n, att in CHARS for d in ("south-east", "north-east")]
    ncol = max(sum(len(f) for _, f in r) for _, r in rows)
    img = Image.new("RGBA", (150 + (C + 3) * ncol + 40, C * len(rows)), (40, 38, 44, 255))
    dr = ImageDraw.Draw(img)
    for r, (lab, groups) in enumerate(rows):
        dr.text((4, r * C + C // 2), lab, fill=(220, 220, 220, 255))
        x = 150
        for a, fs in groups:
            dr.text((x, r * C + 2), a, fill=(160, 160, 160, 255))
            for f in fs:
                im = Image.open(f).convert("RGBA")
                im = im.resize((im.width * S, im.height * S), Image.NEAREST)
                img.alpha_composite(im, (x + (C - im.width) // 2, r * C + (C - im.height) // 2))
                x += C
            x += 10
    img = img.crop((0, 0, img.getbbox()[2] + 10, img.height))
    out = P.parent / "previews" / "npcs_anim.png"
    img.save(out)
    return out


if __name__ == "__main__":
    print(main())
