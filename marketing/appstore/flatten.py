"""Converts every exported PNG to opaque RGB; App Store Connect rejects alpha channels."""
from pathlib import Path
from PIL import Image

for path in sorted((Path(__file__).parent / "out").rglob("*.png")):
    image = Image.open(path)
    if image.mode != "RGB":
        image.convert("RGB").save(path)
