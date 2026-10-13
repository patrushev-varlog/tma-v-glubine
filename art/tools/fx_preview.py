"""Превью эффектов: лист всех кадров (previews/fx_sheet.png) и анимация сеткой (previews/fx.gif)."""
from pathlib import Path
from PIL import Image, ImageDraw

A = Path(__file__).resolve().parents[1]
F = A / "prologue" / "fx"


def main(S=2, C=128):
    ids = sorted(d.name for d in F.iterdir() if (d / "frames").exists())
    frames = {i: [Image.open(f).convert("RGBA") for f in sorted((F / i / "frames").glob("*.png"))] for i in ids}
    n = max(len(v) for v in frames.values())
    sheet = Image.new("RGBA", (130 + C * n, C * len(ids)), (40, 38, 44, 255))
    d = ImageDraw.Draw(sheet)
    for r, i in enumerate(ids):
        d.text((4, r * C + C // 2), i, fill=(230, 230, 230, 255))
        for k, im in enumerate(frames[i]):
            s = max(1, min(S, C // max(im.size)))
            im = im.resize((im.width * s, im.height * s), Image.NEAREST)
            sheet.alpha_composite(im, (130 + k * C + (C - im.width) // 2, r * C + (C - im.height) // 2))
    sheet.save(A / "prologue/previews/fx_sheet.png")
    cols = 6
    rows = (len(ids) + cols - 1) // cols
    gif = []
    for k in range(n):
        g = Image.new("RGBA", (cols * C, rows * (C + 14)), (40, 38, 44, 255))
        dg = ImageDraw.Draw(g)
        for j, i in enumerate(ids):
            x, y = (j % cols) * C, (j // cols) * (C + 14)
            dg.text((x + 4, y + C), i, fill=(200, 200, 200, 255))
            fr = frames[i]
            im = fr[k % len(fr)]
            s = max(1, min(S, C // max(im.size)))
            im = im.resize((im.width * s, im.height * s), Image.NEAREST)
            g.alpha_composite(im, (x + (C - im.width) // 2, y + (C - im.height) // 2))
        gif.append(g.convert("P", palette=Image.ADAPTIVE))
    gif[0].save(A / "prologue/previews/fx.gif", save_all=True, append_images=gif[1:], duration=100, loop=0)


if __name__ == "__main__":
    main()
