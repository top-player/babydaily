"""Inspect icon2.png: tile bbox, corner radius, edge colour, content radius."""
import math
from PIL import Image

im = Image.open("icon2.png").convert("RGBA")
w, h = im.size
px = im.load()
print(f"size {w}x{h}")

# 1) bounding box of non-transparent pixels
minx, miny, maxx, maxy = w, h, -1, -1
for y in range(h):
    for x in range(w):
        if px[x, y][3] > 8:
            minx = min(minx, x)
            miny = min(miny, y)
            maxx = max(maxx, x)
            maxy = max(maxy, y)
print(f"alpha bbox: ({minx},{miny})-({maxx},{maxy})  tile {maxx-minx+1}x{maxy-miny+1}")

# 2) corner radius: along the top edge row, how far in does opacity start?
ty = miny
row = [x for x in range(w) if px[x, ty][3] > 8]
print(f"top row y={ty}: first/last opaque x = {row[0]}..{row[-1]}")
# scan down left edge
lx = minx
col = [y for y in range(h) if px[lx, y][3] > 8]
print(f"left col x={lx}: first/last opaque y = {col[0]}..{col[-1]}")

# find radius r such that opaque region at top row starts at minx + r
# walk the top-left corner: for each y offset, first opaque x
print("\ncorner profile (dy -> first opaque dx):")
for dy in range(0, 60, 4):
    y = miny + dy
    xs = [x for x in range(w) if px[x, y][3] > 8]
    if xs:
        print(f"  dy={dy:3d}  dx={xs[0]-minx:3d}")

# 3) edge colours: sample just inside each edge midpoint and the extreme corners
def sample(x, y):
    return px[x, y]

cx, cy = (minx + maxx) // 2, (miny + maxy) // 2
print("\nedge midpoints (8px inside):")
for name, (x, y) in {
    "top": (cx, miny + 8),
    "bottom": (cx, maxy - 8),
    "left": (minx + 8, cy),
    "right": (maxx - 8, cy),
}.items():
    print(f"  {name:7s} {sample(x, y)}")

print("\ncorner samples (12px diagonal in):")
for name, (x, y) in {
    "TL": (minx + 12, miny + 12),
    "TR": (maxx - 12, miny + 12),
    "BL": (minx + 12, maxy - 12),
    "BR": (maxx - 12, maxy - 12),
}.items():
    print(f"  {name} {sample(x, y)}")

# 4) content radius from tile centre, in tile units (ignore background-ish px)
tw, th = maxx - minx + 1, maxy - miny + 1
ccx, ccy = minx + tw / 2, miny + th / 2
bg = sample(minx + 12, miny + 12)[:3]


def is_bg(c, tol=14):
    return all(abs(c[i] - bg[i]) <= tol for i in range(3))


rows = []
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        if a < 200 or is_bg((r, g, b)):
            continue
        dx = (x - ccx) / tw
        dy = (y - ccy) / th
        rows.append((math.hypot(dx, dy), x, y, (r, g, b)))

rows.sort(reverse=True)
print(f"\ncontent px (non-background): {len(rows)}")
print(f"bg colour sampled near TL = {bg}")
for rad, x, y, col in rows[:8]:
    print(f"  r={rad:.3f}  ({x:3d},{y:3d})  rgb={col}")
print(f"farthest content radius = {rows[0][0]:.3f} tile units")
print(f"max tile size keeping content in 66dp safe circle = {33 / rows[0][0]:.1f}dp of 108dp canvas")
