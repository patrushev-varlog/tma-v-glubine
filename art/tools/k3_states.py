"""K3: позы-состояния пролога (PROMPTS.md 4.5) — связанные Гаррет и Брандт, один кадр ЮВ.

`create-character-state` позу не меняет (только перекрашивает и убирает детали), поэтому кадр
генерируется через `generate-image-v2` с ростовым спрайтом персонажа как образцом внешности и стиля.
Запрос 64×64 даёт 16 вариантов: все сохраняются в variants/, лучший выбирается вручную.
"""
import sys, concurrent.futures as cf
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
import pixellab as p

W1 = p.ROOT / "art" / "wave1" / "characters"
OUT = p.ROOT / "art" / "prologue" / "characters"
STATES = {
 "garret_tied": (W1 / "garret/unarmed/rotations/south-east.png",
                 "the same grey-haired old soldier from the reference, unarmed, no shield, lying on the ground on his side, "
                 "hands tied behind his back with rope, ropes around the ankles, captive"),
 "brandt_tied": (W1 / "overseer_chief/unarmed/rotations/south-east.png",
                 "the same mine overseer chief from the reference, unarmed, no whip, sitting on the ground with knees up, "
                 "hands tied in front with rope, wounded, head lowered, captive"),
}
TAIL = ", isometric 3/4 view from upper left, pixel art game sprite, 1px dark outline, muted desaturated palette, transparent background"


def state(name, ref, desc, seed=None):
    from PIL import Image
    w, h = Image.open(ref).size
    r64 = {"image": p.b64img(ref), "size": {"width": w, "height": h}}
    body = {"description": desc + TAIL, "image_size": {"width": 64, "height": 64}, "no_background": True,
            "reference_images": [dict(r64, usage_description="this character's look, clothes and colors")],
            "style_image": r64}
    if seed is not None:
        body["seed"] = seed
    r = p.call("POST", "/generate-image-v2", body)
    j = p.wait_job(p._job_id(r))
    imgs = (j.get("last_response") or {}).get("images") or []
    for i, im in enumerate(imgs):
        p.save_b64(im, OUT / name / "variants" / f"{i:02d}.png")
    p.log({"kind": "image", "name": name, "id": p._job_id(r), "status": j.get("status"), "frames": len(imgs),
           "cost": (j.get("usage") or {}).get("generations"), "description": desc})
    return name, len(imgs), (j.get("usage") or {}).get("generations")


if __name__ == "__main__":
    names = sys.argv[1:] or list(STATES)
    with cf.ThreadPoolExecutor(2) as ex:
        for f in cf.as_completed([ex.submit(state, n, *STATES[n]) for n in names]):
            try:
                print("ok", f.result(), flush=True)
            except Exception as e:
                print("ERR", e, flush=True)
