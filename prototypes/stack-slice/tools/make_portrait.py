#!/usr/bin/env python3
"""Портрет героя 128×128 из генерации универсальной модели и слои Тьмы к нему.

Источник — art/portraits/source/hero_wizard_m.png (Midjourney/Flux по art/PROMPTS.md, раздел 8).
Шаги, как в PROMPTS.md: кадр → уменьшение до 128 → подъём тёмных тонов → перевод в Resurrect 64.
Кожа (маска по тону внутри рамки лица) раскладывается на рампу из четырёх цветов палитры:
это ключи шейдера scripts/portrait/skin_swap.gdshader, по ним стадии Тьмы меняют кожу.
Слои Сумрак/Мрак/Бездна рисуются по координатам глаз, висков и шеи этого портрета.

    python3 tools/make_portrait.py   (нужны Pillow и numpy)

Это черновик для проверки схемы: финальный портрет и слои стоит дочистить в Aseprite.
"""
import colorsys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance

SLICE = Path(__file__).resolve().parent.parent
SRC = SLICE.parent.parent / "art" / "portraits" / "source" / "hero_wizard_m.png"
PALETTE = SLICE / "art" / "resurrect-64.png"
OUT = SLICE / "art" / "portrait"
S = 128

CROP = (80, 0, 1180, 1100)  # квадрат вокруг бюста в исходнике 1254×1254, кристалл посоха в кадре
GAMMA = 0.75                # подъём тёмных тонов: генерация темнее, чем читается в 128 px
SATURATION = 1.25
CHROMA = 1.3                # вес цветности при выборе ближайшего цвета палитры (Lab)
BACKGROUND = ("#313638", "#2e222f")  # серый фон генерации → самый тёмный цвет палитры

FACE_BOX = (46, 12, 100, 74)  # x0, y0, x1, y1: лицо, ухо и шея в координатах 128
# Рампа кожи стадии «Тень», от света к тени. Совпадает с SKIN[0] в dark_portrait.gd.
SKIN_RAMP = ["#fca790", "#e6904e", "#cd683d", "#9e4539"]
SKIN_SPLITS = (0.85, 0.55, 0.2)  # доли яркости кожи для четырёх тонов

# Черты лица этого портрета (128 px).
EYE_NEAR = (76, 82, 34)   # x0, x1, y зрачковой линии
EYE_FAR = (90, 94, 36)
IRIS_NEAR = (79, 34)
IRIS_FAR = (92, 36)
TEMPLE = (71, 28)
CHEEK = (75, 41)
NECK = (60, 58)


def hexrgb(h: str) -> tuple[int, int, int]:
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def lab(rgb: np.ndarray) -> np.ndarray:
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.9505, 1.0, 1.089])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def quantize(im: Image.Image, pal: np.ndarray) -> np.ndarray:
    a = lab(np.asarray(im).astype(float))
    p = lab(pal)
    d = (a[..., None, 0] - p[:, 0]) ** 2 + CHROMA * ((a[..., None, 1] - p[:, 1]) ** 2 + (a[..., None, 2] - p[:, 2]) ** 2)
    return pal[d.argmin(-1)].astype(np.uint8)


def base() -> Image.Image:
    pal = np.asarray(Image.open(PALETTE).convert("RGB")).reshape(-1, 3).astype(float)
    small = Image.open(SRC).convert("RGB").crop(CROP).resize((S, S), Image.LANCZOS)
    a = np.asarray(small).astype(float) / 255
    small = ImageEnhance.Color(Image.fromarray((255 * a ** GAMMA).astype(np.uint8))).enhance(SATURATION)
    q = quantize(small, pal)
    q[(q == hexrgb(BACKGROUND[0])).all(-1)] = hexrgb(BACKGROUND[1])

    # Кожа: тёплый тон достаточной яркости внутри рамки лица (борода и волосы темнее порога).
    a = np.asarray(small).astype(float) / 255
    hsv = np.array([[colorsys.rgb_to_hsv(*a[y, x]) for x in range(S)] for y in range(S)])
    box = np.zeros((S, S), bool)
    x0, y0, x1, y1 = FACE_BOX
    box[y0:y1, x0:x1] = True
    skin = box & ((hsv[..., 0] < 0.12) | (hsv[..., 0] > 0.95)) & (hsv[..., 1] > 0.18) & (hsv[..., 2] > 0.42)
    light = a.mean(-1)
    th = np.quantile(light[skin], SKIN_SPLITS)
    tone = np.select([light >= th[0], light >= th[1], light >= th[2]], [0, 1, 2], 3)
    for k, h in enumerate(SKIN_RAMP):
        q[skin & (tone == k)] = hexrgb(h)
    return Image.fromarray(q).convert("RGBA")


def layer() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def dusk() -> Image.Image:
    """Сумрак: тени под глазами."""
    im, d = layer()
    x0, x1, y = EYE_NEAR
    d.line([x0, y + 2, x1, y + 2], fill="#7a3045")
    d.line([x0 + 1, y + 3, x1 - 1, y + 3], fill="#694f62")
    x0, x1, y = EYE_FAR
    d.line([x0, y + 2, x1, y + 2], fill="#7a3045")
    return im


def gloom() -> Image.Image:
    """Мрак: потемневшие вены у висков, радужка темнее."""
    im, d = layer()
    x, y = TEMPLE
    d.line([x, y, x + 1, y + 3, x, y + 6, x + 2, y + 8], fill="#6b3e75")
    d.point([x + 2, y + 3], fill="#6b3e75")
    for x, y in (IRIS_NEAR, IRIS_FAR):
        d.rectangle([x - 1, y, x, y], fill="#323353")
    return im


def abyss() -> Image.Image:
    """Бездна: чёрно-фиолетовые прожилки, бледно-зелёный отблеск глаз."""
    im, d = layer()
    x, y = TEMPLE
    d.line([x - 1, y - 4, x + 1, y, x, y + 4], fill="#45293f")
    x, y = CHEEK
    d.line([x, y, x + 2, y + 3, x + 1, y + 6], fill="#45293f")
    d.point([x + 3, y + 3], fill="#6b3e75")
    x, y = NECK
    d.line([x, y, x + 1, y + 4, x - 1, y + 8], fill="#45293f")
    for x, y in (IRIS_NEAR, IRIS_FAR):
        d.rectangle([x - 1, y, x, y], fill="#165a4c")
        d.point([x, y], fill="#91db69")
    d.point([IRIS_NEAR[0] - 1, IRIS_NEAR[1]], fill="#cddf6c")
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    base().save(OUT / "hero_base.png")
    dusk().save(OUT / "dark_1_dusk.png")
    gloom().save(OUT / "dark_2_gloom.png")
    abyss().save(OUT / "dark_3_abyss.png")
    print(f"портрет и слои записаны в {OUT}")


if __name__ == "__main__":
    main()
