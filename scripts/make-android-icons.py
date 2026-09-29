#!/usr/bin/env python3
"""Generate the Android adaptive launcher icon from the iOS 1024 px icon.

The iOS icon is a white square with handwritten 五十音 on the right. Android masks adaptive
icons, so the glyphs are re-centered inside the 66 dp safe zone of the 108 dp canvas.

Usage: python3 scripts/make-android-icons.py
"""
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source/kana/kana/Assets.xcassets/AppIcon.appiconset/Icon-1024.png"
RES = ROOT / "source/android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
CANVAS_DP = 108
GLYPH_BOX_DP = 60  # inside the 66 dp safe zone
INK = (0x17, 0x14, 0x12)


def extract_glyphs(image: Image.Image) -> Image.Image:
    gray = image.convert("L")
    alpha = gray.point(lambda p: 255 - p)
    ink = Image.new("RGBA", image.size, INK + (255,))
    ink.putalpha(alpha)
    bbox = alpha.point(lambda a: 255 if a > 10 else 0).getbbox()
    return ink.crop(bbox)


def foreground(glyphs: Image.Image, scale: float) -> Image.Image:
    canvas_px = round(CANVAS_DP * scale)
    box_px = round(GLYPH_BOX_DP * scale)
    canvas = Image.new("RGBA", (canvas_px, canvas_px), (0, 0, 0, 0))
    fitted = glyphs.copy()
    fitted.thumbnail((box_px, box_px), Image.LANCZOS)
    canvas.alpha_composite(fitted, ((canvas_px - fitted.width) // 2, (canvas_px - fitted.height) // 2))
    return canvas


def main() -> None:
    glyphs = extract_glyphs(Image.open(SOURCE))
    for density, scale in DENSITIES.items():
        target = RES / f"mipmap-{density}" / "ic_launcher_foreground.png"
        target.parent.mkdir(parents=True, exist_ok=True)
        foreground(glyphs, scale).save(target, optimize=True)
        print(f"wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
