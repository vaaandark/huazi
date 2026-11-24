"""字元数据：笔顺、部件分解、篆隶字形。"""

from __future__ import annotations

import csv
import gzip
import json
from pathlib import Path

from . import config

CHARLIST = config.CHARLIST_DIR / "6763.txt"


def load_chars() -> list[str]:
    return [c for c in CHARLIST.read_text(encoding="utf-8").split("\n") if c.strip()]


def cp_of(ch: str) -> int:
    return ord(ch)


# ---------------------------------------------------------------- 笔顺

def build_strokes(strokes_dir: Path, chars: list[str]) -> list[tuple[int, bytes, int]]:
    """返回 (code_point, gzip(json), 笔画数)。缺失的字跳过。"""
    out = []
    for ch in chars:
        p = strokes_dir / f"{ch}.json"
        if not p.exists():
            continue
        raw = p.read_bytes()
        try:
            n = len(json.loads(raw)["strokes"])
        except Exception:  # noqa: BLE001
            n = 0
        out.append((cp_of(ch), gzip.compress(raw, 9), n))
    return out


# ---------------------------------------------------------------- 结构

def build_chars(dictionary: Path, chars: list[str]) -> list[tuple]:
    """从 Make Me a Hanzi 的 dictionary.txt 取部件分解、部首、拼音。"""
    wanted = set(chars)
    out = []
    with dictionary.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            ch = d.get("character", "")
            if ch not in wanted:
                continue
            pins = d.get("pinyin") or []
            out.append((
                cp_of(ch), ch,
                "/".join(pins) if pins else None,
                d.get("radical"),
                d.get("decomposition"),
                (d.get("etymology") or {}).get("type"),
                (d.get("etymology") or {}).get("hint"),
            ))
    return out


def stroke_count_map(stroke_rows: list[tuple[int, bytes, int]]) -> dict[int, int]:
    return {cp: n for cp, _, n in stroke_rows}


# ---------------------------------------------------------------- 篆隶

LAYER_SCRIPT = {"seal": "zhuan", "clerical": "li"}


def build_ancient(glyphs_dir: Path, chars: list[str]) -> list[tuple]:
    """从 hanzi-glyphs-svg 提取篆/隶字形。

    简体字先转成繁体再查，因为字形库以传统字形为准。
    """
    from zhconv import convert

    wanted: dict[str, str] = {}
    for ch in chars:
        wanted[ch] = ch
        trad = convert(ch, "zh-hant")
        if trad != ch:
            wanted[trad] = ch

    ledger = glyphs_dir / "glyph-ids.csv"
    out = []
    with ledger.open(encoding="utf-8") as f:
        for r in csv.DictReader(f):
            layer = r["layer"]
            if layer not in LAYER_SCRIPT or r["status"] != "active":
                continue
            mc = r["modern_char"]
            if mc not in wanted:
                continue
            src = glyphs_dir / layer / r["file"]
            if not src.exists():
                continue
            svg = src.read_text(encoding="utf-8")
            # 去掉多余空白，压一压体积
            svg = " ".join(svg.split())
            out.append((
                cp_of(wanted[mc]),
                LAYER_SCRIPT[layer],
                int(r["unified_id"].rsplit("-", 1)[1]),
                svg,
                layer,
                r["unified_id"],
            ))
    return out


# ---------------------------------------------------------------- 字体

def subset_font(src: Path, dst: Path, chars: list[str]) -> Path:
    from fontTools import subset

    opts = subset.Options()
    opts.layout_features = ["*"]
    opts.drop_tables += ["DSIG"]
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    opts.recalc_bounds = True
    opts.desubroutinize = True

    font = subset.load_font(str(src), opts)
    subsetter = subset.Subsetter(options=opts)
    subsetter.populate(text="".join(chars))
    subsetter.subset(font)
    dst.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(dst), opts)
    return dst
