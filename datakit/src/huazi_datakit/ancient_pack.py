"""构建篆隶字形可选包（独立 SQLite，按需下载）。"""

from __future__ import annotations

import gzip
import sqlite3
from pathlib import Path

from . import config, glyphdata

SCHEMA = """
PRAGMA page_size=4096;
DROP TABLE IF EXISTS glyph;
CREATE TABLE glyph (
  cp     INTEGER NOT NULL,
  script TEXT NOT NULL,     -- zhuan | li
  seq    INTEGER NOT NULL,
  svg    BLOB NOT NULL,     -- gzip 后的 SVG 文本
  layer  TEXT,
  uid    TEXT,
  PRIMARY KEY (cp, script, seq)
);
CREATE INDEX idx_glyph_cp ON glyph(cp);
"""


def build(out: Path) -> None:
    glyphs_dir = config.VENDOR / "glyphs-src" / "glyphs"
    if not glyphs_dir.exists():
        raise SystemExit(f"缺少字形库：{glyphs_dir}\n先跑 tool/fetch-glyphs.sh")

    chars = glyphdata.load_chars()
    rows = glyphdata.build_ancient(glyphs_dir, chars)

    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()
    conn = sqlite3.connect(out)
    conn.executescript(SCHEMA)
    conn.executemany(
        "INSERT OR REPLACE INTO glyph (cp,script,seq,svg,layer,uid) VALUES (?,?,?,?,?,?)",
        [(cp, sc, seq, gzip.compress(svg.encode("utf-8"), 9), layer, uid)
         for cp, sc, seq, svg, layer, uid in rows],
    )
    conn.commit()
    conn.execute("VACUUM")
    conn.close()

    covered = len({r[0] for r in rows})
    by_script: dict[str, int] = {}
    for r in rows:
        by_script[r[1]] = by_script.get(r[1], 0) + 1
    print(f"✓ {out}  {out.stat().st_size/1024/1024:.1f} MB")
    print(f"  覆盖 {covered}/{len(chars)} 字，字形 {len(rows)} 个 "
          f"({', '.join(f'{k}={v}' for k, v in by_script.items())})")
