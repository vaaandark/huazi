#!/usr/bin/env python3
"""生成应用图标：朱砂底 + 白「字」，用于各平台与网页 favicon。"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "app" / "assets" / "fonts" / "wenkai.ttf"
OUT = ROOT / "app" / "assets" / "icon"

CINNABAR = (178, 65, 46)
PAPER = (250, 247, 240)


def rounded(size: int, radius_ratio: float = 0.22, transparent: bool = False) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0) if transparent else CINNABAR)
    d = ImageDraw.Draw(img)
    r = int(size * radius_ratio)
    if transparent:
        d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=CINNABAR)
    return img


def draw_char(img: Image.Image, scale: float = 0.62, dy: float = 0.02) -> None:
    size = img.width
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(str(FONT), int(size * scale))
    box = d.textbbox((0, 0), "字", font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    x = (size - w) / 2 - box[0]
    y = (size - h) / 2 - box[1] + size * dy
    d.text((x, y), "字", font=font, fill=PAPER)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)

    base = rounded(1024)
    draw_char(base)
    base.save(OUT / "icon.png")

    fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    draw_char(fg)
    fg.save(OUT / "icon_foreground.png")

    base.convert("RGB").save(OUT / "icon_bg.png")

    for size in (512, 192, 48):
        im = base.resize((size, size), Image.LANCZOS)
        im.save(OUT / f"icon_{size}.png")
    print(f"图标写入 {OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
