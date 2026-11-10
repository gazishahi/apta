"""Builds screen masks from Apple's bezel PNGs so screenshots fill the cutout exactly.

The mask is the bezel's transparent screen area (flood-filled from the center),
grown by two pixels so it tucks under the bezel's anti-aliased edge. Prints the
mask's bounding box as percentages for positioning the screenshot in CSS.
Usage: python3 masks.py
"""
from PIL import Image, ImageDraw, ImageFilter

BEZELS = ["iphone-bezel.png", "duo-outer-bezel.png", "duo-inner-bezel.png"]

for name in BEZELS:
    bezel = Image.open(name).convert("RGBA")
    w, h = bezel.size
    # Opaque bezel pixels are walls; flood the transparent screen from the center.
    canvas = bezel.getchannel("A").point(lambda a: 255 if a > 200 else 0).convert("RGB")
    ImageDraw.floodfill(canvas, (w // 2, h // 2), (0, 255, 0))
    r, g, _ = canvas.split()
    # Flooded pixels are pure green: green channel full, red channel empty.
    mask = Image.new("L", (w, h), 0)
    mask.paste(255, mask=g.point(lambda v: 255 if v == 255 else 0))
    mask.paste(0, mask=r.point(lambda v: 255 if v == 255 else 0))
    mask = mask.filter(ImageFilter.MaxFilter(5))

    left, top, right, bottom = mask.getbbox()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.putalpha(mask)
    out.save(name.replace("-bezel", "-mask"))
    print(f"{name}: left {left / w:.3%} top {top / h:.3%} width {(right - left) / w:.3%} height {(bottom - top) / h:.3%}")
