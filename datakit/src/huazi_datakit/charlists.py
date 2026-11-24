"""生成字表：GB2312 一二级汉字共 6763 字，无需外部数据。"""

from __future__ import annotations

from pathlib import Path

from . import config


def gb2312_chars(level: int = 0) -> list[str]:
    """level 0=全部 6763，1=一级 3755，2=二级 3008。"""
    lo = {0: 0xB0, 1: 0xB0, 2: 0xD8}[level]
    hi = {0: 0xF7, 1: 0xD7, 2: 0xF7}[level]
    out: list[str] = []
    for b1 in range(lo, hi + 1):
        for b2 in range(0xA1, 0xFF):
            try:
                ch = bytes([b1, b2]).decode("gb2312")
            except UnicodeDecodeError:
                continue
            out.append(ch)
    return out


def write_lists() -> dict[str, int]:
    config.CHARLIST_DIR.mkdir(parents=True, exist_ok=True)
    stats: dict[str, int] = {}
    for name, level in (("6763", 0), ("3755", 1), ("3008", 2)):
        chars = gb2312_chars(level)
        path: Path = config.CHARLIST_DIR / f"{name}.txt"
        path.write_text("\n".join(chars) + "\n", encoding="utf-8")
        stats[name] = len(chars)
    return stats
