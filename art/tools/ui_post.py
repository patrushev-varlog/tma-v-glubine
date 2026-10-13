"""Доводка интерфейса после генерации: прозрачный фон вокруг рамок, состояния кнопки, рамка активного.

    python3 art/tools/ui_post.py
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

O = Path(__file__).resolve().parents[1] / "prologue" / "icons"
OPAQUE = ["ui_panel", "ui_button", "ui_slot", "ui_dialog"]


def clear_bg(a, tol=40):
    """Стирает фон, залитый от краёв: пиксели, близкие по цвету к угловому и связанные с краем."""
    h, w = a.shape[:2]
    bg = a[0, 0, :3].astype(int)
    near = (np.abs(a[..., :3].astype(int) - bg).max(-1) <= tol)
    seen = np.zeros((h, w), bool)
    stack = [(y, x) for y in range(h) for x in (0, w - 1)] + [(y, x) for x in range(w) for y in (0, h - 1)]
    while stack:
        y, x = stack.pop()
        if 0 <= y < h and 0 <= x < w and not seen[y, x] and near[y, x]:
            seen[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    a[seen] = 0
    return a


def nine(src, w, h, m):
    """9-slice: углы m×m как есть, края и середина растягиваются ближайшим соседом."""
    W, H = src.size
    out = Image.new("RGBA", (w, h))
    xs = [(0, m, 0, m), (m, W - m, m, w - m), (W - m, W, w - m, w)]
    ys = [(0, m, 0, m), (m, H - m, m, h - m), (H - m, H, h - m, h)]
    for sy0, sy1, dy0, dy1 in ys:
        for sx0, sx1, dx0, dx1 in xs:
            part = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.NEAREST)
            out.alpha_composite(part, (dx0, dy0))
    return out


def tone(img, mul, add=(0, 0, 0)):
    a = np.array(img).astype(float)
    a[..., :3] = np.clip(a[..., :3] * mul + add, 0, 255)
    return Image.fromarray(a.round().astype(np.uint8))


def glow(img, color=(255, 196, 92)):
    """Тёплое свечение по контуру рамки (рамка активного персонажа)."""
    a = img.split()[3]
    halo = a.filter(ImageFilter.MaxFilter(5)).point(lambda v: 160 if v else 0)
    pad = Image.new("RGBA", img.size, color + (0,))
    pad.putalpha(halo)
    pad.alpha_composite(tone(img, 1.08, (18, 12, 0)))
    return pad


if __name__ == "__main__":
    for n in OPAQUE:
        f = O / f"{n}.png"
        a = np.array(Image.open(f).convert("RGBA"))
        Image.fromarray(clear_bg(a)).save(f)
    b = Image.open(O / "ui_button.png").convert("RGBA")
    tone(b, 1.0).save(O / "ui_button_normal.png")
    tone(b, 1.15, (22, 14, 0)).save(O / "ui_button_hover.png")
    pressed = Image.new("RGBA", b.size)
    pressed.alpha_composite(tone(b, 0.8), (0, 1))
    pressed.save(O / "ui_button_pressed.png")
    tone(b, 0.55).convert("LA").convert("RGBA").save(O / "ui_button_disabled.png")
    # Рамки, полоса хитов и плашка имени собираются из ячейки умения, чтобы весь бой был одной рамкой.
    # Сгенерированная резная рамка остаётся ui_portrait_frame_ornate (крупная, для диалога).
    if not (O / "ui_portrait_frame_ornate.png").exists():
        (O / "ui_portrait_frame.png").rename(O / "ui_portrait_frame_ornate.png")
    slot = Image.open(O / "ui_slot.png").convert("RGBA")
    slot = slot.crop(slot.getbbox())
    fr = nine(slot, 72, 72, 7)
    a = np.array(fr); a[4:-4, 4:-4] = 0  # окно под портрет 64×64
    fr = Image.fromarray(a)
    fr.save(O / "ui_portrait_frame.png")
    nine(slot, 64, 10, 4).save(O / "ui_hpbar.png")
    nine(slot, 96, 24, 7).save(O / "ui_nameplate.png")
    big = Image.new("RGBA", (fr.width + 8, fr.height + 8))
    big.alpha_composite(fr, (4, 4))
    glow(big).save(O / "ui_portrait_frame_active.png")
    print("ok")
