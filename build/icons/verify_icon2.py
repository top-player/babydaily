"""Verify generated launcher icons: composite adaptive layers under android masks
and show legacy icons at 100% pixels."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BG = (252, 240, 223, 255)  # #FCF0DF, must equal ic_launcher_background.xml

fg = Image.open(RES / "mipmap-xxxhdpi" / "ic_launcher_foreground.png").convert("RGBA")
print(f"foreground xxxhdpi {fg.size}")
canvas = Image.new("RGBA", fg.size, BG)
canvas.alpha_composite(fg)


def mask(shape, size):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    if shape == "circle":
        d.ellipse((0, 0, size[0] - 1, size[1] - 1), fill=255)
    elif shape == "squircle":
        d.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=int(size[0] * 0.30), fill=255)
    return m


CELL = 320
sheet = Image.new("RGBA", (CELL * 3, CELL), (240, 240, 240, 255))
for i, shape in enumerate(("circle", "squircle", "square")):
    cell = Image.new("RGBA", fg.size, (0, 0, 0, 0))
    if shape == "square":
        cell = canvas.copy()
    else:
        cell.paste(canvas, (0, 0), mask(shape, fg.size))
    cell = cell.resize((CELL - 20, CELL - 20), Image.LANCZOS)
    sheet.paste(cell, (i * CELL + 10, 10), cell)
sheet.convert("RGB").save(ROOT / "build" / "icons" / "adaptive_check1.png")

# legacy row
row = Image.new("RGB", (CELL * 3, 240), (240, 240, 240))
x = 10
for d in ("xxxhdpi", "xxhdpi", "xhdpi", "hdpi", "mdpi"):
    im = Image.open(RES / f"mipmap-{d}" / "ic_launcher.png").convert("RGBA")
    print(f"legacy {d}: {im.size}, corner alpha={im.getpixel((0, 0))[3]}, centre={im.getpixel((im.width//2, im.height//2))}")
    if x + im.width < CELL * 3:
        row.paste(im.convert("RGB"), (x, 240 - im.height - 10), im)
        x += im.width + 12
row.save(ROOT / "build" / "icons" / "legacy_check1.png")

# seam check: composite must have no visible step at the foreground edge
px = canvas.load()
edge = fg.getpixel((0, 0))
print(f"foreground corner pixel (outside art) = {edge}")
print(f"composited corner pixel               = {px[0, 0]}")
print(f"composited centre pixel               = {px[216, 216]}")
print("wrote build/icons/adaptive_check1.png, build/icons/legacy_check1.png")
