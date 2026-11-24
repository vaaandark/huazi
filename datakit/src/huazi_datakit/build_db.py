"""把 data/works/*.yaml 编译成 app 内置的 SQLite。"""

from __future__ import annotations

import json
import shutil
import sqlite3
from collections import Counter
from pathlib import Path

from . import config
from .cli import iter_works

SCHEMA = """
PRAGMA journal_mode=DELETE;
PRAGMA page_size=4096;

DROP TABLE IF EXISTS work_fts;
DROP TABLE IF EXISTS work_image;
DROP TABLE IF EXISTS work;
DROP TABLE IF EXISTS person;

CREATE TABLE work (
  id            TEXT PRIMARY KEY,
  title         TEXT NOT NULL,
  aliases       TEXT,
  author        TEXT,
  dynasty       TEXT,
  script        TEXT,
  carrier       TEXT,
  era           TEXT,
  lines         INTEGER,
  chars_per_line INTEGER,
  total_chars   INTEGER,
  holder        TEXT,
  rubbing       TEXT,
  layout        TEXT,
  summary       TEXT,
  description   TEXT,
  transcription TEXT,
  rights        TEXT,
  status        TEXT,
  source_name   TEXT,
  source_url    TEXT,
  image_count   INTEGER,
  excluded      INTEGER DEFAULT 0
);

CREATE TABLE work_image (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  work_id   TEXT NOT NULL REFERENCES work(id),
  seq       INTEGER NOT NULL,
  thumb     TEXT,
  remote    TEXT,
  width     INTEGER,
  height    INTEGER,
  license   TEXT,
  note      TEXT
);
CREATE INDEX idx_image_work ON work_image(work_id, seq);

CREATE TABLE person (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  dynasty    TEXT,
  work_count INTEGER DEFAULT 0
);

CREATE TABLE char (
  cp             INTEGER PRIMARY KEY,
  ch             TEXT NOT NULL,
  pinyin         TEXT,
  radical        TEXT,
  decomposition  TEXT,
  etymology_type TEXT,
  etymology_hint TEXT,
  strokes        INTEGER
);

CREATE TABLE stroke (
  cp   INTEGER PRIMARY KEY,
  data BLOB NOT NULL,
  n    INTEGER
);

CREATE VIRTUAL TABLE work_fts USING fts5(
  id UNINDEXED, title, author, summary, transcription, tokenize='unicode61'
);
"""

PERSON_BIO = {
    "颜真卿": "唐·楷行皆绝，「颜体」宽博雄强。代表作《多宝塔碑》《颜勤礼碑》《祭侄文稿》。",
    "欧阳询": "唐·「欧体」险劲严谨，结体紧收。代表作《九成宫醴泉铭》《化度寺碑》。",
    "柳公权": "唐·「柳体」骨力劲健，与颜真卿并称「颜筋柳骨」。代表作《玄秘塔碑》《神策军碑》。",
    "赵孟頫": "元·「赵体」流丽温润，由楷入行最顺。代表作《胆巴碑》《妙严寺记》。",
    "王羲之": "东晋·书圣，《兰亭序》为「天下第一行书」。",
    "王献之": "东晋·与父并称「二王」，行草纵逸。",
    "苏轼": "北宋·「宋四家」之首，《黄州寒食帖》为天下第三行书。",
    "黄庭坚": "北宋·长枪大戟，辐射式结体。代表作《松风阁诗卷》。",
    "米芾": "北宋·八面出锋，欹侧多姿。代表作《蜀素帖》《苕溪诗帖》。",
    "褚遂良": "唐·瘦劲飘逸，《雁塔圣教序》为楷书典范。",
    "怀素": "唐·狂草，《自叙帖》为草书极则。",
    "董其昌": "明·淡雅秀润，主张「以禅入书」。",
    "文徵明": "明·精严雅正，小楷冠绝明代。",
    "王铎": "明末清初·涨墨连绵，气势雄强。",
    "沈周": "明·吴门画派领袖，书法学黄庭坚。",
    "朱熹": "南宋·理学大家，书崇古雅。",
    "曹善": "元·以楷书抄经著称。",
    "李隆基": "唐玄宗·工八分、行书，《鹡鸰颂》为其代表。",
}


def build(out: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.exists():
        out.unlink()

    works = iter_works()
    conn = sqlite3.connect(out)
    conn.executescript(SCHEMA)

    clock: Counter[str] = Counter()

    for _, w in works:
        excluded = 1 if "excluded:" in (w.notes or "") else 0
        src = w.sources[0] if w.sources else None
        conn.execute(
            """INSERT INTO work (id,title,aliases,author,dynasty,script,carrier,era,
                lines,chars_per_line,total_chars,holder,rubbing,layout,summary,
                description,transcription,rights,status,source_name,source_url,
                image_count,excluded)
               VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (
                w.id, w.title, json.dumps(w.aliases, ensure_ascii=False) if w.aliases else None,
                w.author, w.dynasty, w.script.value if w.script else None,
                w.carrier.value if w.carrier else None, w.era,
                w.lines, w.chars_per_line, w.total_chars, w.holder, w.rubbing,
                w.layout, w.summary, w.description, w.transcription, w.rights,
                w.status, src.name if src else None, src.url if src else None,
                len(w.images), excluded,
            ),
        )
        for img in w.images:
            conn.execute(
                """INSERT INTO work_image (work_id,seq,thumb,remote,width,height,license,note)
                   VALUES (?,?,?,?,?,?,?,?)""",
                (w.id, img.seq, img.thumb, img.remote, img.width, img.height,
                 img.license, img.note),
            )
        conn.execute(
            "INSERT INTO work_fts (id,title,author,summary,transcription) VALUES (?,?,?,?,?)",
            (w.id, w.title, w.author or "", w.summary or "", w.transcription or ""),
        )
        clock[w.script.value if w.script else "?"] += 1

    # 书家表
    by_author: dict[str, str | None] = {}
    for _, w in works:
        if w.author and "excluded:" not in (w.notes or ""):
            by_author.setdefault(w.author, w.dynasty)
    for name, dynasty in by_author.items():
        pid = "p-" + str(abs(hash(name)) % 10**8)
        cnt = conn.execute(
            "SELECT COUNT(*) FROM work WHERE author=? AND excluded=0", (name,)
        ).fetchone()[0]
        conn.execute(
            "INSERT INTO person (id,name,dynasty,work_count) VALUES (?,?,?,?)",
            (pid, name, dynasty, cnt),
        )

    conn.commit()

    # ---- 字元数据：笔顺 + 结构
    from . import glyphdata

    chars = glyphdata.load_chars()
    strokes_dir = config.VENDOR / "strokes" / "package"
    stroke_rows = []
    if strokes_dir.exists():
        stroke_rows = glyphdata.build_strokes(strokes_dir, chars)
        smap = glyphdata.stroke_count_map(stroke_rows)
        conn.executemany(
            "INSERT INTO stroke (cp,data,n) VALUES (?,?,?)", stroke_rows
        )
    else:
        smap = {}

    dict_path = config.VENDOR / "dictionary.txt"
    if dict_path.exists():
        rows = glyphdata.build_chars(dict_path, chars)
        conn.executemany(
            """INSERT INTO char (cp,ch,pinyin,radical,decomposition,etymology_type,
                etymology_hint,strokes) VALUES (?,?,?,?,?,?,?,?)""",
            [(cp, ch, py, rad, dec, et, hint, smap.get(cp)) for
             cp, ch, py, rad, dec, et, hint in rows],
        )
    conn.commit()

    # 缩略图
    dst = out.parent / "thumbs"
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)
    copied = 0
    for p in config.THUMB_DIR.glob("*.webp"):
        shutil.copy2(p, dst / p.name)
        copied += 1

    size = out.stat().st_size
    # 数据版本清单，app 据此判断是否需要重新拷贝内置库
    import json as _json
    from datetime import datetime, timezone

    manifest = {
        "version": datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S"),
        "works": len(works),
        "size": size,
    }
    (out.parent / "manifest.json").write_text(
        _json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"✓ {out}  {size/1024/1024:.1f} MB")
    print(f"  作品 {len(works)} 条，其中排除 {sum(1 for _, w in works if 'excluded:' in (w.notes or ''))} 条")
    print(f"  书家 {len(by_author)} 位，缩略图 {copied} 张")
    print("  书体分布:", ", ".join(f"{k}={v}" for k, v in clock.most_common()))
