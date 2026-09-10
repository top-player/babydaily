"""Generate Android launcher icons from icon2.png.

- legacy ic_launcher.png for API < 26 (rounded-square tile as-is, cream fill kept)
- adaptive ic_launcher_foreground.png: tile scaled to 108/108 dp so the cream tile art
  itself fills the mask viewport (no background layer shows through -> no ring/seam);
  the tile art is padded with the same clean cream as its own fill, so a mask that is
  larger than the art cannot reveal a colour step.
- mipmap-anydpi-v26/ic_launcher.xml wires foreground + flat cream background.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "icon2.png"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

# tile bounding box inside icon2.png (measured: alpha > 8)
TILE_BOX = (23, 28, 366, 364)

# density -> legacy icon size in px (48/72/96/144/192 dp)
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# density -> (foreground canvas px, tile px) ; canvas = 108 dp, tile = 108 dp (full bleed)
FOREGROUND = {
    "mdpi": (108, 108),
    "hdpi": (162, 162),
    "xhdpi": (216, 216),
    "xxhdpi": (324, 324),
    "xxxhdpi": (432, 432),
}

src = Image.open(SRC).convert("RGBA")
tile = src.crop(TILE_BOX)
# square it up with transparent padding so scaling stays undistorted
side = max(tile.size)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
square.paste(tile, ((side - tile.width) // 2, (side - tile.height) // 2), tile)
print(f"source {src.size} -> tile {tile.size} -> square {square.size}")


def fit(img, size):
    return img.resize((size, size), Image.LANCZOS)


for density, px in LEGACY.items():
    out = RES / f"mipmap-{density}" / "ic_launcher.png"
    art = fit(square, px)
    art.save(out)
    print(f"legacy   {out.relative_to(ROOT)}  {px}x{px}")

for density, (canvas_px, tile_px) in FOREGROUND.items():
    out = RES / f"mipmap-{density}" / "ic_launcher_foreground.png"
    canvas = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
    art = fit(square, tile_px)
    off = (canvas_px - tile_px) // 2
    canvas.paste(art, (off, off), art)
    canvas.save(out)
    print(f"adaptive {out.relative_to(ROOT)}  {canvas_px}x{canvas_px} (tile {tile_px})")
