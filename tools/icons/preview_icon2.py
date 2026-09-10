"""Preview adaptive-icon rendering for icon2.png under android masks.

Renders the way Android composites an adaptive icon:
  background layer (flat #FCF0DE) + foreground layer, then the system mask.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "icon2.png"
OUT = ROOT / "build" / "icons" / "icon2_preview.png"
BG = (252, 240, 222, 255)
TILE_BOX = (23, 28, 366, 364)  # alpha > 8 bbox, exclusive right/bottom

src = Image.open(SRC).convert("RGBA")
tile = src.crop(TILE_BOX)
side = max(tile.size)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
square.paste(tile, ((side - tile.width) // 2, (side - tile.height) // 2), tile)
print(f"tile {tile.size} -> square {square.size}")

CANVAS = 432  # xxxhdpi 108dp


def build(tile_dp):
    """Composite bg + foreground(tile at tile_dp of 108dp) at 432px canvas."""
    px = round(CANVAS * tile_dp / 108)
    canvas = Image.new("RGBA", (CANVAS, CANVAS), BG)
    art = square.resize((px, px), Image.LANCZOS)
    off = (CANVAS - px) // 2
    canvas.paste(art, (off, off), art)
    return canvas


def mask(img, shape):
    m = Image.new("L", (CANVAS, CANVAS), 0)
    d = ImageDraw.Draw(m)
    if shape == "circle":
        d.ellipse((0, 0, CANVAS - 1, CANVAS - 1), fill=255)
    elif shape == "squircle":  # android "rounded square" mask ~ 30% radius
        d.rounded_rectangle((0, 0, CANVAS - 1, CANVAS - 1), radius=int(CANVAS * 0.30), fill=255)
    elif shape == "square":
        d.rectangle((0, 0, CANVAS - 1, CANVAS - 1), fill=255)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.paste(img, (0, 0), m)
    return out


variants = [("fills-canvas 108dp", 108.0), ("safe 66dp-circle 52.7dp", 52.7), ("compromise 84dp", 84.0)]
shapes = ["circle", "squircle", "square"]
CELL = 300
sheet = Image.new("RGBA", (CELL * len(shapes), CELL * len(variants)), (245, 245, 245, 255))
for r, (label, dp) in enumerate(variants):
    base = build(dp)
    for c, shape in enumerate(shapes):
        cell = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        cell.paste(mask(base, shape), (0, 0))
        cell = cell.resize((CELL - 20, CELL - 20), Image.LANCZOS)
        sheet.paste(cell, (c * CELL + 10, r * CELL + 10), cell)
    print(f"row {r}: {label}")
sheet.convert("RGB").save(OUT)
print(f"wrote {OUT}")
