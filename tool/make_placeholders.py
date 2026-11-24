#!/usr/bin/env python3
"""给没有图源的碑帖生成一张纸色封面，避免列表出现空图/404。"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml
from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "datakit" / "src"))
from huazi_datakit import config  # noqa: E402

W, H = 640, 840
PAPER = (246, 242, 233)
INK = (31, 35, 40)
RED = (178, 65, 46)
FONT = Path(__file__).resolve().parents[1] / "app" / "assets" / "fonts" / "wenkai.ttf"


def make(work: dict, out: Path) -> None:
    img = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(img)
    d.rectangle([18, 18, W - 18, H - 18], outline=(210, 202, 188), width=2)

    title = ImageFont.truetype(str(FONT), 54)
    small = ImageFont.truetype(str(FONT), 24)
    head = ImageFont.truetype(str(FONT), 26)

    text = (work.get("title") or "").replace("（", "(").replace("）", ")")
    text = text.split("(")[0][:12]
    x = W - 92
    y = 70
    for ch in text:
        d.text((x, y), ch, font=title, fill=INK)
        y += 62
        if y > H - 150:
            x -= 64
            y = 70

    author = work.get("author") or "佚名"
    dynasty = work.get("dynasty") or ""
    d.text((44, H - 150), f"{dynasty}  {author}", font=small, fill=INK)

    script = {"kai": "楷书", "xing": "行书", "cao": "草书", "li": "隶书", "zhuan": "篆书"}
    label = script.get(work.get("script") or "", "碑帖")
    d.text((44, 52), label, font=head, fill=RED)
    d.text((44, H - 100), "待补高清图源", font=small, fill=(150, 142, 128))

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "WEBP", quality=82, method=4)


def main() -> int:
    made = 0
    for p in sorted(config.WORK_DIR.glob("*.yaml")):
        w = yaml.safe_load(p.read_text(encoding="utf-8"))
        if "excluded:" in (w.get("notes") or ""):
            continue
        if w.get("images"):
            continue
        target = config.THUMB_DIR / f"{w['id']}-001.webp"
        if target.exists():
            continue
        make(w, target)
        made += 1
        print(f"  + {target.name}  {w.get('title')}")
    print(f"生成 {made} 张占位封面")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
