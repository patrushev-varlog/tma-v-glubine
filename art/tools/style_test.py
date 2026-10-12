#!/usr/bin/env python3
"""Карточки стиль-теста (поток K2 плана review/07-next-steps.md) в art/style-test/.

Карточки A–C — одна и та же сцена 6×5 из якорей стиля, собранная тремя наборами генераторов;
буквы перемешаны, чтобы тестер не угадал по порядку (ключ — в art/style-test/README.md).
Карточка D — сцена первой волны (PixelLab) с отрядом, врагами и портретом волшебника в рамке.
На карточках нет подписей генераторов и отладочного текста, в отличие от снимков среза стека.

    python3 art/tools/style_test.py      (нужны Pillow и numpy)
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ART = Path(__file__).resolve().parent.parent
OUT = ART / "style-test"
W, H, ZOOM = 1280, 720, 2
BG = (46, 34, 47)        # #2e222f, самый тёмный цвет Resurrect 64
TEXT = (199, 220, 208)   # #c7dcd0
GOLD = (251, 185, 84)    # #fbb954

ANCHORS = ART / "anchors"
WAVE = ART / "wave1"
CH = WAVE / "characters"

# Набор генераторов → файлы пола, крепи и персонажа. Буква карточки ≠ порядок генераторов.
SETS = {
    "B": {"floor": ANCHORS / "approved/floor_upper_mines.png", "timber": ANCHORS / "approved/timber_support.png",
          "hero": ANCHORS / "approved/garret/south-east.png"},
    "C": {"floor": ANCHORS / "rd/floor_upper_mines.png", "timber": ANCHORS / "rd/timber_support.png",
          "hero": ANCHORS / "rd/garret.png"},
    "A": {"floor": ANCHORS / "rd/floor_upper_mines.png", "timber": ANCHORS / "rd/timber_support.png",
          "hero": ANCHORS / "approved/garret/south-east.png"},
}


def load(p: Path) -> Image.Image:
    return Image.open(p).convert("RGBA")


def foot(im: Image.Image) -> tuple[int, int]:
    """Точка опоры: середина по x, нижний непрозрачный ряд минус 4 px (ступни и основания стоят в ромбе)."""
    a = np.asarray(im)[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    return im.width // 2, int(ys.max()) - 4


def floor_center(im: Image.Image) -> tuple[int, int]:
    """Центр ромба пола: середина между верхним непрозрачным рядом и верхом + 32."""
    a = np.asarray(im)[..., 3] > 0
    top = int(np.nonzero(a.any(1))[0].min())
    return im.width // 2, top + 16


class Scene:
    def __init__(self, cols: int, rows: int):
        self.cols, self.rows = cols, rows
        self.items: list[tuple[float, Image.Image, int, int]] = []
        self.canvas = Image.new("RGBA", (64 * (cols + rows) + 64, 32 * (cols + rows) + 160), (0, 0, 0, 0))
        self.ox, self.oy = 32 * rows + 32, 120

    def cell(self, x: int, y: int) -> tuple[int, int]:
        return self.ox + (x - y) * 32, self.oy + (x + y) * 16

    def floor(self, im: Image.Image, x: int, y: int) -> None:
        cx, cy = self.cell(x, y)
        fx, fy = floor_center(im)
        self.items.append((-1000 + x + y, im, cx - fx, cy - fy))

    def put(self, im: Image.Image, x: int, y: int, mirror: bool = False) -> None:
        if mirror:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        cx, cy = self.cell(x, y)
        fx, fy = foot(im)
        self.items.append((x + y + 0.5, im, cx - fx, cy - fy))

    def render(self) -> Image.Image:
        for _, im, x, y in sorted(self.items, key=lambda t: t[0]):
            self.canvas.alpha_composite(im, (x, y))
        bbox = self.canvas.getbbox()
        return self.canvas.crop(bbox)


def card(scene: Image.Image, letter: str, extra=None) -> Image.Image:
    c = Image.new("RGB", (W, H), BG)
    big = scene.resize((scene.width * ZOOM, scene.height * ZOOM), Image.NEAREST)
    left = 40 if extra else (W - big.width) // 2
    c.paste(big, (left, (H - big.height) // 2), big)
    if extra:
        extra(c)
    d = ImageDraw.Draw(c)
    d.text((24, 16), letter, fill=GOLD, font=font(48))
    return c


def font(size: int):
    for name in ("DejaVuSans.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/Library/Fonts/Arial Unicode.ttf",
                 "/System/Library/Fonts/Supplemental/Arial.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def anchors_card(letter: str) -> Image.Image:
    s = SETS[letter]
    fl, tb, hero = load(s["floor"]), load(s["timber"]), load(s["hero"])
    sc = Scene(6, 5)
    for x in range(6):
        for y in range(5):
            sc.floor(fl, x, y)
    for x, y in ((1, 0), (4, 0), (4, 3), (1, 3)):
        sc.put(tb, x, y)
    sc.put(hero, 2, 2)
    return card(sc.render(), letter)


def frame(rel: str) -> Image.Image:
    return load(CH / rel)


def wave_card() -> Image.Image:
    t = WAVE / "tiles/upper_mines"
    floors = [load(t / f) for f in ("floor_plain_a.png", "floor_plain_b.png", "floor_cracked.png")]
    rails = load(t / "floor_rails.png")
    sc = Scene(8, 6)
    rng = np.random.default_rng(7)
    for x in range(8):
        for y in range(6):
            sc.floor(rails if x == 3 else floors[int(rng.integers(0, 3))], x, y)
    sc.put(load(t / "rockfall.png"), 5, 0)
    sc.put(load(t / "minecart.png"), 3, 4)
    sc.put(load(t / "ore_heap.png"), 1, 0)
    sc.put(load(ANCHORS / "approved/timber_support.png"), 7, 1)
    idle = "composited/idle/south-east/00.png"
    sc.put(frame("hero_wizard_evoker/" + idle), 1, 3)
    sc.put(frame("irena/" + idle), 0, 4)
    sc.put(frame("garret/unarmed/composited2/idle/south-east/00.png"), 2, 2)
    sc.put(frame("overseer_chief/" + idle), 6, 2, mirror=True)
    sc.put(frame("overseer/" + idle), 5, 1, mirror=True)
    sc.put(frame("zombie/" + idle), 5, 3, mirror=True)
    sc.put(frame("skeleton_archer/" + idle), 7, 0, mirror=True)

    def side(c: Image.Image) -> None:
        d = ImageDraw.Draw(c)
        portrait = ART / "portraits/hero_wizard_m/base_128.png"
        x0, y0 = W - 32 - 256, 140
        d.rectangle([x0 - 8, y0 - 8, x0 + 256 + 8, y0 + 256 + 8], fill=(62, 53, 70), outline=(171, 148, 122), width=4)
        if portrait.exists():
            c.paste(load(portrait).resize((256, 256), Image.NEAREST), (x0, y0))
        y = y0 + 256 + 32
        d.text((x0 - 8, y), "Герой", fill=GOLD, font=font(22))
        for i, line in enumerate(("— Ты что-то недоговариваешь.", "Я же вижу. Скажи мне.")):
            d.text((x0 - 8, y + 32 + 26 * i), line, fill=TEXT, font=font(17))

    return card(sc.render(), "D", side)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for letter in ("A", "B", "C"):
        anchors_card(letter).save(OUT / f"card_{letter}.png")
    wave_card().save(OUT / "card_D.png")
    print(f"карточки записаны в {OUT.relative_to(ART.parent)}")


if __name__ == "__main__":
    main()
