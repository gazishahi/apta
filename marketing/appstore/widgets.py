"""Cuts the widgets used on the widgets slide (iPhone slide 4) out of device screenshots.

Inputs (1179 x 2556 device screenshots on a plain black wallpaper), in captures/widgets/:
- lock_raw.png: Lock Screen with the two rectangular widgets.
- home_raw.png: Home Screen with two small widgets and a medium one.
- home_large_raw.png, lock_circular_raw.png: kept for other pages (large widget, circular widgets).
Outputs: lock.png (date, clock and widgets on black) and one transparent PNG per Home Screen tile.
Needs OpenCV: pip install opencv-python-headless
Usage: python3 widgets.py
"""
from pathlib import Path

import cv2
import numpy as np

here = Path(__file__).parent / "captures" / "widgets"

# Tile boxes (x, y, w, h), found from the black wallpaper.
HOME_TILES = {
    "tile_list": (72, 240, 488, 488),
    "tile_next": (618, 240, 488, 488),
    "tile_medium": (72, 832, 1034, 488),
}
LARGE_TILE = (72, 240, 1034, 1080)
# From just above the date to just below the widgets; the status bar is left out.
LOCK_CROP = (220, 860)


def cut_tile(image, box):
    """The tile with a transparent background. The wallpaper is pure black, so the
    antialiased edge's brightness is its coverage; colors are un-premultiplied."""
    x, y, w, h = box
    pad = 4
    tile = image[y - pad:y + h + pad, x - pad:x + w + pad].astype(np.float32)
    alpha = np.clip(tile.max(axis=2, keepdims=True) / 40.0, 0, 1)
    # The tile body is opaque everywhere (its dark text included); only the outer edge ramps.
    contours, _ = cv2.findContours((alpha[..., 0] > 0.02).astype(np.uint8), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    inside = np.zeros(alpha.shape[:2], np.uint8)
    cv2.drawContours(inside, [max(contours, key=cv2.contourArea)], -1, 255, -1)
    inside = cv2.erode(inside, np.ones((7, 7), np.uint8))
    alpha[inside > 0] = 1
    color = np.where(alpha > 0, tile / np.maximum(alpha, 1e-3), 0)
    return np.dstack([np.clip(color, 0, 255), alpha * 255]).astype(np.uint8)


lock = cv2.imread(str(here / "lock_raw.png"))
top, bottom = LOCK_CROP
cv2.imwrite(str(here / "lock.png"), lock[top:bottom])

home = cv2.imread(str(here / "home_raw.png"))
for name, box in HOME_TILES.items():
    cv2.imwrite(str(here / f"{name}.png"), cut_tile(home, box))
large = cv2.imread(str(here / "home_large_raw.png"))
cv2.imwrite(str(here / "tile_large.png"), cut_tile(large, LARGE_TILE))
print("wrote", here / "lock.png", *(here / f"{n}.png" for n in [*HOME_TILES, "tile_large"]))
