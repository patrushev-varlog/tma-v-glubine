"""Утро после облавы: перекраска ночных ассетов деревни в холодный серый утренний свет (PROMPTS.md 3.7).

Насыщенность снижается, тени поднимаются, всё сдвигается к сине-серому; огонь в окнах гаснет до тусклого.
    python3 art/tools/morning.py  → tiles/village_morning/<имя>.png для ассетов из NIGHT
"""
from pathlib import Path
import colorsys
import numpy as np
from PIL import Image

A = Path(__file__).resolve().parents[1] / "prologue" / "tiles"
NIGHT = ["floor_path", "floor_grass", "floor_garden", "edge", "fence", "fence_b", "woodpile", "well", "bell_tower", "tools", "house"]
TINT = np.array([150, 158, 170]) / 255  # холодный серый


def morning(img):
    a = np.array(img.convert("RGBA")).astype(float) / 255
    rgb = a[..., :3]
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    hsv = np.array([colorsys.rgb_to_hsv(*px) for px in rgb.reshape(-1, 3)]).reshape(rgb.shape)
    warm_glow = (hsv[..., 1] > 0.55) & (hsv[..., 2] > 0.7) & ((hsv[..., 0] < 0.15) | (hsv[..., 0] > 0.95))
    grey = lum[..., None] * np.ones(3)
    out = rgb * 0.45 + grey * 0.55          # снять насыщенность
    out = out * 0.85 + 0.12                 # поднять тени: утро светлее ночи
    out = out * (0.7 + 0.3 * TINT / TINT.mean())
    out[warm_glow] = grey[warm_glow] * 0.6 + 0.1  # окна и огонь гаснут
    a[..., :3] = np.clip(out, 0, 1)
    return Image.fromarray((a * 255).round().astype(np.uint8))


if __name__ == "__main__":
    for n in NIGHT:
        src = A / "village_night" / f"{n}.png"
        morning(Image.open(src)).save(A / "village_morning" / f"{n}.png")
        print(n)
