"""Measure the cream colour across the tile fill and the exact tile corner, to pick
a background colour that cannot show a seam."""
import statistics as st
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
im = Image.open(ROOT / "icon2.png").convert("RGBA")
px = im.load()
X0, Y0, X1, Y1 = 23, 28, 365, 363

# sample a grid over the tile, keeping only pixels that are "cream-ish" (near-uniform
# light warm colour) -> the artwork is orange/brown/yellow, the fill is a pale cream
samples = []
for y in range(Y0 + 8, Y1 - 8, 3):
    for x in range(X0 + 8, X1 - 8, 3):
        r, g, b, a = px[x, y]
        if a < 250:
            continue
        if r > 240 and g > 225 and b > 200 and b < 245 and (r - g) < 20:
            samples.append((r, g, b))
print(f"cream fill samples: {len(samples)}")
med = tuple(round(st.median(c[i] for c in samples)) for i in range(3))
mean = tuple(round(st.fmean(c[i] for c in samples)) for i in range(3))
print(f"tile fill median {med} mean {mean} -> #{med[0]:02X}{med[1]:02X}{med[2]:02X}")

# the exact pixel ring just inside the rounded corner of the composited tile
# (this is what a mask slightly larger than the art would expose)
corners = []
for (cx, cy, dx, dy) in ((X0, Y0, 1, 1), (X1, Y0, -1, 1), (X0, Y1, 1, -1), (X1, Y1, -1, -1)):
    # walk diagonally in until opaque
    for k in range(1, 40):
        r, g, b, a = px[cx + dx * k, cy + dy * k]
        if a > 250:
            corners.append((k, (r, g, b)))
            break
print("corner entry pixels (diagonal step, rgb):")
for k, c in corners:
    print(f"  step {k:2d}  {c}")
print("corner mean", tuple(round(st.fmean(c[i] for c in (c for _, c in corners))) for i in range(3)))

# what the old green background would look like against this tile edge (contrast)
green = (180, 235, 193)
print(f"\ncontrast vs old green bg {green}: max channel delta "
      f"{max(abs(med[i] - green[i]) for i in range(3))}")
print(f"contrast vs chosen cream #FCF0DE: max channel delta "
      f"{max(abs(med[i] - 252, abs(med[i] - 240), 0) for i in range(1))}")
