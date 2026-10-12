#!/usr/bin/env python3
"""Заглушка портрета героя 128×128 и слои Тьмы для проверки композитной схемы.

Не арт: простые фигуры в цветах Resurrect 64, чтобы проверить механику на экране
(базовый портрет + накладываемые слои + замена цветов кожи шейдером). Настоящий портрет
делается по art/PROMPTS.md, раздел 8, и кладётся под теми же именами.

    python3 tools/make_placeholder_portrait.py   (нужен Pillow)
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "art" / "portrait"
S = 128

# Цвета из Resurrect 64.
BG = "#2e222f"
BG2 = "#3e3546"
CLOAK = "#323353"
CLOAK_LIGHT = "#484a77"
HAIR = "#45293f"
HAIR_LIGHT = "#694f62"
# Три тона кожи — ключи для шейдера замены (scripts/portrait/skin_swap.gdshader).
SKIN_HI = "#fdcbb0"
SKIN = "#fca790"
SKIN_SH = "#cd683d"
EYE = "#2e222f"
IRIS = "#4d65b4"


def base() -> Image.Image:
    im = Image.new("RGBA", (S, S), BG)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 96, S, S], fill=BG2)
    # Плечи и плащ.
    d.ellipse([14, 92, 114, 160], fill=CLOAK)
    d.ellipse([22, 96, 70, 150], fill=CLOAK_LIGHT)
    # Шея.
    d.rectangle([54, 78, 74, 100], fill=SKIN_SH)
    d.rectangle([54, 78, 62, 98], fill=SKIN)
    # Голова: свет сверху слева.
    d.ellipse([38, 26, 90, 88], fill=SKIN_SH)
    d.ellipse([38, 26, 84, 84], fill=SKIN)
    d.ellipse([44, 32, 66, 54], fill=SKIN_HI)
    # Волосы.
    d.pieslice([34, 18, 94, 70], 180, 360, fill=HAIR)
    d.rectangle([34, 40, 42, 74], fill=HAIR)
    d.rectangle([86, 40, 94, 70], fill=HAIR)
    d.line([44, 24, 70, 22], fill=HAIR_LIGHT, width=2)
    # Брови, глаза, нос, рот.
    d.line([48, 50, 58, 49], fill=HAIR, width=2)
    d.line([68, 49, 78, 50], fill=HAIR, width=2)
    for x in (50, 70):
        d.rectangle([x, 54, x + 7, 57], fill="#ffffff")
        d.rectangle([x + 2, 54, x + 5, 57], fill=IRIS)
        d.rectangle([x + 3, 55, x + 4, 56], fill=EYE)
    d.line([63, 58, 61, 68], fill=SKIN_SH, width=2)
    d.line([58, 69, 64, 69], fill=SKIN_SH)
    d.line([56, 75, 70, 75], fill="#9e4539", width=2)
    return im


def layer() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def dusk() -> Image.Image:
    """Сумрак: тени под глазами."""
    im, d = layer()
    for x in (50, 70):
        d.line([x, 59, x + 7, 59], fill="#694f62")
        d.line([x + 1, 60, x + 6, 60], fill="#7f708a")
    return im


def gloom() -> Image.Image:
    """Мрак: потемневшие вены у висков, радужка темнее."""
    im, d = layer()
    d.line([42, 48, 44, 56, 42, 62], fill="#6b3e75")
    d.line([86, 48, 84, 55, 86, 60], fill="#6b3e75")
    for x in (50, 70):
        d.rectangle([x + 2, 54, x + 5, 57], fill="#323353")
        d.rectangle([x + 3, 55, x + 4, 56], fill="#2e222f")
    return im


def abyss() -> Image.Image:
    """Бездна: чёрно-фиолетовые прожилки, бледно-зелёный отблеск глаз."""
    im, d = layer()
    d.line([44, 36, 48, 44, 46, 50], fill="#45293f")
    d.line([80, 62, 76, 70, 78, 78], fill="#45293f")
    d.line([58, 80, 60, 90], fill="#45293f")
    for x in (50, 70):
        d.rectangle([x + 2, 54, x + 5, 57], fill="#165a4c")
        d.point([x + 3, 55], fill="#91db69")
        d.point([x + 4, 55], fill="#cddf6c")
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    base().save(OUT / "hero_base.png")
    dusk().save(OUT / "dark_1_dusk.png")
    gloom().save(OUT / "dark_2_gloom.png")
    abyss().save(OUT / "dark_3_abyss.png")
    print(f"заглушки портрета записаны в {OUT}")


if __name__ == "__main__":
    main()
