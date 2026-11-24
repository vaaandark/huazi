"""命令行入口：import / enrich / validate / thumbs / build"""

from __future__ import annotations

import argparse
import time
import sys
from collections import Counter
from pathlib import Path

import yaml

from . import config, enrich as enrich_mod, shuge
from .schema import Work


# ---------------------------------------------------------------- 读写

def work_path(wid: str) -> Path:
    return config.WORK_DIR / f"{wid}.yaml"


def load_work(path: Path) -> Work:
    with path.open(encoding="utf-8") as f:
        return Work.model_validate(yaml.safe_load(f))


def save_work(work: Work) -> Path:
    config.WORK_DIR.mkdir(parents=True, exist_ok=True)
    data = work.model_dump(mode="json", exclude_none=True, exclude_defaults=False)
    path = work_path(work.id)
    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False, width=100)
    return path


def iter_works() -> list[tuple[Path, Work]]:
    out = []
    if not config.WORK_DIR.exists():
        return out
    for p in sorted(config.WORK_DIR.glob("*.yaml")):
        out.append((p, load_work(p)))
    return out


# ---------------------------------------------------------------- 命令

def cmd_import(args: argparse.Namespace) -> int:
    entries = [int(x) for x in args.entries.split(",")] if args.entries else list(config.SHUGE_ENTRIES)
    print(f"从书格拉取资源集合 {entries}")
    items = shuge.list_portfolio(entries)
    print(f"共 {len(items)} 条")
    if args.limit:
        items = items[: args.limit]

    written = skipped = 0
    for i, it in enumerate(items, 1):
        title = shuge.clean_text(it["title"]["rendered"])
        full = shuge.get_item(it["id"])
        work = shuge.build_draft(full)
        work = enrich_mod.enrich(work, entry_ids=it.get("portfolio_entries", []))
        path = work_path(work.id)
        if path.exists() and not args.force:
            skipped += 1
            print(f"  [{i}/{len(items)}] 跳过（已存在）{title}")
            continue
        save_work(work)
        written += 1
        print(f"  [{i}/{len(items)}] {title}  → {path.name}  图 {work.image_count} 张")
    print(f"\n写入 {written} 条，跳过 {skipped} 条")
    return 0


def cmd_enrich(args: argparse.Namespace) -> int:
    changed = 0
    for path, work in iter_works():
        before = work.model_dump(mode="json")
        work = enrich_mod.enrich(work)
        if work.model_dump(mode="json") != before:
            save_work(work)
            changed += 1
            print(f"  更新 {path.name}")
    print(f"更新 {changed} 条")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    works = iter_works()
    problems: list[str] = []
    warnings: list[str] = []
    ids: Counter[str] = Counter()

    for path, w in works:
        ids[w.id] += 1
        if w.id != path.stem:
            problems.append(f"{path.name}: 文件名与 id 不一致（{w.id}）")
        for f in w.missing():
            warnings.append(f"{path.name}: 缺 {f}")
        if not w.images:
            warnings.append(f"{path.name}: 尚无图片（待补图源）")
        if "excluded:" in (w.notes or ""):
            continue
        if w.script is None:
            warnings.append(f"{path.name}: 书体未识别")
        for img in w.images:
            if not img.license:
                warnings.append(f"{path.name}#{img.seq}: 图片缺 license")

    for wid, n in ids.items():
        if n > 1:
            problems.append(f"重复 id: {wid} × {n}")

    total = len(works)
    reviewed = sum(1 for _, w in works if w.status == "reviewed")
    by_script = Counter(w.script.value if w.script else "?" for _, w in works)

    print(f"共 {total} 条（已校订 {reviewed}）")
    print("书体分布:", ", ".join(f"{k}={v}" for k, v in by_script.most_common()))
    if warnings:
        print(f"\n警告 {len(warnings)}:")
        for w in warnings[:40]:
            print("  ⚠", w)
    if problems:
        print(f"\n错误 {len(problems)}:")
        for p in problems:
            print("  ✗", p)
        return 1
    print("\n✓ 校验通过")
    return 0


def cmd_thumbs(args: argparse.Namespace) -> int:
    """下载缩略图到 data/cache/img（原图只存外链）。"""
    import httpx
    from PIL import Image
    from io import BytesIO

    config.THUMB_DIR.mkdir(parents=True, exist_ok=True)
    max_w = args.width
    done = skipped = failed = 0
    with httpx.Client(timeout=60, follow_redirects=True,
                      headers={"User-Agent": config.USER_AGENT}) as client:
        for path, work in iter_works():
            if "excluded:" in (work.notes or ""):
                continue
            changed = False
            for img in work.images[: args.max_per_work]:
                target = config.THUMB_DIR / f"{work.id}-{img.seq:03d}.webp"
                if target.exists():
                    img.thumb = str(target.relative_to(config.DATA))
                    skipped += 1
                    continue
                try:
                    r = client.get(img.remote)
                    r.raise_for_status()
                    im = Image.open(BytesIO(r.content)).convert("RGB")
                    ratio = max_w / im.width
                    if ratio < 1:
                        im = im.resize((max_w, int(im.height * ratio)), Image.LANCZOS)
                    im.save(target, "WEBP", quality=args.quality, method=4)
                    img.thumb = str(target.relative_to(config.DATA))
                    img.width, img.height = im.size
                    img.license = img.license or "公有领域（原作），扫描件来自书格"
                    changed = True
                    done += 1
                    time.sleep(1.5)  # 对书格保持礼貌间隔
                except Exception as e:  # noqa: BLE001
                    failed += 1
                    print(f"  ✗ {work.id}#{img.seq}: {e}")
            if changed:
                save_work(work)
    print(f"缩略图: 新增 {done}, 已存在 {skipped}, 失败 {failed}")
    return 0


def cmd_build(args: argparse.Namespace) -> int:
    from . import build_db

    out = config.BUILD / "huazi.sqlite"
    build_db.build(out)
    return 0


def cmd_chars(args: argparse.Namespace) -> int:
    from . import charlists

    stats = charlists.write_lists()
    for k, v in stats.items():
        print(f"  {k}: {v} 字")
    return 0


# ---------------------------------------------------------------- CLI

def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="huazi-data", description="huazi 数据构建工具")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("import", help="从书格导入碑帖草稿")
    sp.add_argument("--entries", help="逗号分隔的资源集合 id（默认 25,28）")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--force", action="store_true")
    sp.set_defaults(func=cmd_import)

    sp = sub.add_parser("enrich", help="补全书家/朝代/书体")
    sp.set_defaults(func=cmd_enrich)

    sp = sub.add_parser("validate", help="校验 YAML")
    sp.set_defaults(func=cmd_validate)

    sp = sub.add_parser("thumbs", help="下载缩略图")
    sp.add_argument("--width", type=int, default=640)
    sp.add_argument("--quality", type=int, default=80)
    sp.add_argument("--max-per-work", type=int, default=6)
    sp.set_defaults(func=cmd_thumbs)

    sp = sub.add_parser("chars", help="生成 6763 字表")
    sp.set_defaults(func=cmd_chars)

    sp = sub.add_parser("build", help="编译 SQLite")
    sp.set_defaults(func=cmd_build)

    args = p.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
