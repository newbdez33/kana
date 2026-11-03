# /// script
# dependencies = ["fonttools[woff]==4.60.1"]
# ///
"""Build a web subset of the font already used by the iOS app."""

from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parent.parent
source = root.parent / "kana/kana/resources/fonts/Hosohuwafont.ttf"
target = root / "assets/kana.woff2"
target.parent.mkdir(parents=True, exist_ok=True)
font = TTFont(source, recalcTimestamp=False)
options = subset.Options()
options.flavor = "woff2"
subsetter = subset.Subsetter(options=options)
subsetter.populate(unicodes=list(range(0x20, 0x7F)) + list(range(0x3040, 0x3100)))
subsetter.subset(font)
font.flavor = "woff2"
font.save(target)
print(f"Saved {target} ({target.stat().st_size} bytes)")
