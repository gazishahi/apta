"""Builds the Apple Watch screenshot set from raw simulator captures.

watchOS simulators can't override the status bar, so the clock is repainted
to match the iPhone set, in the system face (SF Compact Text Medium).
Usage: python3 watch.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FONT = ImageFont.truetype("/Library/Fonts/SF-Compact-Text-Medium.otf", 34)
CLOCK_AREA = (290, 28, 416, 76)   # wipe area around the clock on a 416 x 496 capture
CLOCK_RIGHT, CLOCK_TOP = 383, 40  # right edge and cap top of the real clock
# (capture, clock to show) — clocks match each capture's -CaptureTime.
ORDER = [("times", "3:33"), ("qibla", "3:33"), ("after_isha", "7:30")]

here = Path(__file__).parent
out = here / "out" / "watch"
out.mkdir(parents=True, exist_ok=True)

for i, (name, clock) in enumerate(ORDER, start=1):
    im = Image.open(here / "captures" / "watch" / f"{name}.png").convert("RGB")
    draw = ImageDraw.Draw(im)
    draw.rectangle(CLOCK_AREA, fill=(0, 0, 0))
    left, top, right, _ = draw.textbbox((0, 0), clock, font=FONT)
    draw.text((CLOCK_RIGHT - right, CLOCK_TOP - top), clock, font=FONT, fill=(255, 255, 255))
    im.save(out / f"{i:02d}.png")
    print(out / f"{i:02d}.png", im.size)
