"""Клиент PixelLab API v2 для генерации ассетов (поток K3).

Токен подставляет окружение (секрет хоста api.pixellab.ai или PIXELLAB_API_TOKEN).
Каждый запрос пишется в журнал art/prologue/generations.jsonl: что просили, id, стоимость.
"""
import base64, json, os, sys, time, urllib.request, urllib.error
from pathlib import Path

API = "https://api.pixellab.ai/v2"
ROOT = Path(__file__).resolve().parents[2]
LOG = ROOT / "art" / "prologue" / "generations.jsonl"

STYLE_CHAR = ("pixel art game sprite, single full-body character, isometric 3/4 view, dark fantasy, "
              "muted desaturated palette with one accent color, warm torchlight from upper left, "
              "1px dark outline (not pure black), medium shading, readable silhouette, feet at bottom center, "
              "transparent background")
STYLE_ISO = ("isometric pixel art, 2:1 dimetric projection, dark fantasy, muted desaturated palette, "
             "warm light from upper left, cool blue-grey shadows from lower right, crisp hard pixels, "
             "no anti-aliasing, game asset, transparent background")
GARRET = "e0e044cd-adc5-4a6a-9e9b-7e7de527cea2"


def _headers():
    h = {"Content-Type": "application/json"}
    tok = os.environ.get("PIXELLAB_API_TOKEN")
    if tok:
        h["Authorization"] = f"Bearer {tok}"
    return h


def call(method, path, body=None, timeout=300):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers=_headers())
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{method} {path}: {e.code} {e.read()[:800]!r}") from None


def log(entry):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    entry = {"t": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), **entry}
    if "file" in entry:
        entry["file"] = str(Path(entry["file"]).resolve().relative_to(ROOT))
    with LOG.open("a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def balance():
    return call("GET", "/balance")


def wait_job(job_id, every=5, limit=900):
    t0 = time.time()
    while time.time() - t0 < limit:
        j = call("GET", f"/background-jobs/{job_id}")
        if j.get("status") in ("completed", "failed", "cancelled"):
            return j
        time.sleep(every)
    raise TimeoutError(job_id)


def b64img(path):
    return {"type": "base64", "base64": base64.b64encode(Path(path).read_bytes()).decode()}


def save_b64(obj, path):
    if isinstance(obj, dict):
        obj = obj.get("base64") or obj.get("image", {}).get("base64")
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(base64.b64decode(obj.split(",")[-1]))
    return path


def download(url, path):
    path = Path(path); path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=120) as r:
        path.write_bytes(r.read())
    return path


if __name__ == "__main__":
    print(json.dumps(balance(), indent=1))


# --- высокоуровневые обёртки -------------------------------------------------

def _job_id(r):
    return r.get("background_job_id") or r.get("job_id") or r.get("id")


def character_zip(char_id, out_dir):
    """Скачивает персонажа целиком (повороты и анимации) через api-хост и распаковывает."""
    import io, zipfile
    req = urllib.request.Request(f"{API}/characters/{char_id}/zip", headers=_headers())
    with urllib.request.urlopen(req, timeout=300) as r:
        zipfile.ZipFile(io.BytesIO(r.read())).extractall(out_dir)
    return Path(out_dir)


def create_character(name, description, size=64, style=GARRET, seed=None):
    body = {"description": description, "image_size": {"width": size, "height": size},
            "view": "low top-down", "style_character_id": style, "no_background": True}
    if seed is not None:
        body["seed"] = seed
    r = call("POST", "/create-character-pro", body)
    j = wait_job(_job_id(r))
    log({"kind": "character", "name": name, "id": r["character_id"], "status": j.get("status"),
         "cost": (j.get("usage") or {}).get("generations"), "description": description})
    return r["character_id"], j


def _image_from_job(j):
    lr = j.get("last_response") or {}
    for k in ("image", "images", "result"):
        v = lr.get(k)
        if isinstance(v, list):
            v = v[0]
        if isinstance(v, dict) and (v.get("base64") or v.get("image")):
            return v
    return lr


def iso_tile(name, description, out, size=64, tile_size=32, shape="thin tile", palette=None, seed=None, **kw):
    body = {"description": description, "image_size": {"width": size, "height": size},
            "isometric_tile_size": tile_size, "isometric_tile_shape": shape,
            "outline": "lineless", "shading": "medium shading", "detail": "medium detail", **kw}
    if palette:
        body["color_image"] = b64img(palette)
    if seed is not None:
        body["seed"] = seed
    r = call("POST", "/create-isometric-tile", body)
    j = wait_job(_job_id(r)) if _job_id(r) and "image" not in r else r
    img = _image_from_job(j) if "image" not in r else r["image"]
    save_b64(img, out)
    log({"kind": "iso_tile", "name": name, "id": _job_id(r), "cost": (j.get("usage") or {}).get("generations"),
         "file": str(out), "description": description})
    return out


def fetch_map_object(oid, out):
    """PNG объекта: ссылка на скачивание ведёт на api-хост (файловый хост PixelLab закрыт прокси)."""
    url = call("GET", f"/map-objects/{oid}")["download_url"]
    req = urllib.request.Request(url, headers=_headers())
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    out = Path(out); out.parent.mkdir(parents=True, exist_ok=True)
    if data[:2] == b"PK":
        import io, zipfile
        z = zipfile.ZipFile(io.BytesIO(data))
        png = [n for n in z.namelist() if n.endswith(".png")][0]
        data = z.read(png)
    out.write_bytes(data)
    return out


def map_object(name, description, out, w=64, h=64, view="high top-down", palette=None, seed=None, **kw):
    body = {"description": description, "image_size": {"width": w, "height": h}, "view": view,
            "outline": "single color outline", "shading": "medium shading", "detail": "medium detail", **kw}
    if palette:
        body["color_image"] = b64img(palette)
    if seed is not None:
        body["seed"] = seed
    r = call("POST", "/map-objects", body)
    j = wait_job(_job_id(r))
    oid = r.get("object_id") or (j.get("last_response") or {}).get("object_id")
    fetch_map_object(oid, out)
    log({"kind": "map_object", "name": name, "id": oid, "cost": (j.get("usage") or {}).get("generations"),
         "file": str(out), "description": description})
    return out
