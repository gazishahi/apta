"""Exports the iPhone set at the size App Store Connect asks for.

Designs are 1320 x 2868 (6.9"); App Store Connect's required iPhone slot is the
6.3" display at 1206 x 2622, which it scales to other iPhones. The aspect ratios
differ by under 0.1%, so this scales to cover and trims the sub-pixel overflow.
Usage: python3 sizes.py
"""
from pathlib import Path
from PIL import Image

TARGET = (1206, 2622)

here = Path(__file__).parent / "out"
dest = here / f"iphone-{TARGET[0]}x{TARGET[1]}"
dest.mkdir(exist_ok=True)

for path in sorted((here / "iphone").glob("*.png")):
    image = Image.open(path).convert("RGB")
    scale = max(TARGET[0] / image.width, TARGET[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left = (resized.width - TARGET[0]) // 2
    top = (resized.height - TARGET[1]) // 2
    resized.crop((left, top, left + TARGET[0], top + TARGET[1])).save(dest / path.name)
    print(dest / path.name)
