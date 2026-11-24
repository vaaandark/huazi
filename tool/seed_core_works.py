#!/usr/bin/env python3
"""补齐书格没有收录、但练楷/行必备的名碑名帖。

只写元数据，图源留空（card 会显示占位图），后续 M3 切字时再接高清拓本。
幂等：已存在的 YAML 不覆盖。
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "datakit" / "src"))

from huazi_datakit import config  # noqa: E402

CORE = [
    {
        "id": "jiu-cheng-gong",
        "title": "九成宫醴泉铭",
        "aliases": ["九成宫碑"],
        "author": "欧阳询",
        "writer": "魏征",
        "carver": "刻工不详",
        "dynasty": "唐",
        "era": "贞观六年（632）",
        "script": "kai",
        "carrier": "beike",
        "lines": 24,
        "chars_per_line": 50,
        "total_chars": 1108,
        "holder": "故宫博物院（李祺本）",
        "rubbing": "宋拓",
        "summary": "欧阳询七十六岁所书，"
        "「欧体」第一代表作。结体险劲，中宫收紧而四边舒展，横画左低右高，"
        "是学楷书结构最标准的范本。原碑在陕西麟游，风化严重，现存以宋拓为最善。",
        "layout": "碑高 2.7 米，24 行，满行 50 字",
        "status": "reviewed",
        "notes": "书格未收。图源可参考故宫博物院数字文物库、中华书局影印本。",
    },
    {
        "id": "xuan-mi-ta",
        "title": "玄秘塔碑",
        "aliases": ["玄秘塔碑铭", "大达法师玄秘塔碑"],
        "author": "柳公权",
        "writer": "裴休",
        "carver": "邵建和、邵建初",
        "dynasty": "唐",
        "era": "会昌元年（841）",
        "script": "kai",
        "carrier": "beike",
        "lines": 28,
        "chars_per_line": 54,
        "total_chars": 1512,
        "holder": "西安碑林",
        "rubbing": "宋拓",
        "summary": "柳公权六十四岁书，"
        "「柳体」标准件。骨力劲健、笔画瘦硬，所谓「颜筋柳骨」的柳骨即指此碑。"
        "起笔方斩、转折顿挫分明，适合练笔画力度与字形收紧。",
        "layout": "28 行，满行 54 字",
        "status": "reviewed",
        "notes": "书格未收。",
    },
    {
        "id": "yan-qin-li",
        "title": "颜勤礼碑",
        "aliases": ["唐故秘书省著作郎夔州都督府长史上护军颜君神道碑"],
        "author": "颜真卿",
        "writer": "颜真卿",
        "dynasty": "唐",
        "era": "大历十四年（779）",
        "script": "kai",
        "carrier": "beike",
        "total_chars": 1600,
        "holder": "西安碑林",
        "rubbing": "宋拓",
        "summary": "颜真卿七十岁书，"
        "「颜体」成熟期代表作。笔画丰腴厚重、横细竖粗、外拓开张，气象宏阔。"
        "1922 年出土时字口如新，是学颜体最可靠的一本。",
        "layout": "四面刻，现存三面",
        "status": "reviewed",
        "notes": "书格未收。与《多宝塔碑》对照，可见颜体早晚期差异。",
    },
    {
        "id": "lan-ting-xu",
        "title": "兰亭序（神龙本）",
        "aliases": ["兰亭集序", "冯承素摹本"],
        "author": "王羲之",
        "dynasty": "东晋",
        "era": "永和九年（353）",
        "script": "xing",
        "carrier": "moji",
        "lines": 28,
        "chars_per_line": 12,
        "total_chars": 324,
        "holder": "故宫博物院",
        "rubbing": "唐摹本",
        "summary": "天下第一行书。"
        "28 行 324 字，二十余个「之」字无一雷同。冯承素双钩填墨摹本最接近原迹，"
        "是学行书笔法与行气的第一范本。",
        "layout": "纸本，28 行 324 字",
        "status": "reviewed",
        "notes": "书格未收。",
    },
    {
        "id": "ji-wang-sheng-jiao-xu",
        "title": "怀仁集王圣教序",
        "aliases": ["大唐三藏圣教序", "集字圣教序"],
        "author": "王羲之",
        "dynasty": "唐",
        "era": "咸亨三年（672）",
        "script": "xing",
        "carrier": "beike",
        "lines": 30,
        "holder": "西安碑林",
        "rubbing": "宋拓",
        "summary": "怀仁和尚集王羲之行书字刻成，"
        "历时二十余年。字字取自王羲之真迹，是学王字行书最系统、字数最全的范本，"
        "历来与《兰亭序》并称行书双璧。",
        "layout": "30 行，碑文两千余字",
        "status": "reviewed",
        "notes": "书格未收。集字碑，单字之间缺少行气，适合练单字结构。",
    },
    {
        "id": "yan-ta-sheng-jiao-xu",
        "title": "雁塔圣教序",
        "aliases": ["大唐三藏圣教序（褚遂良书）"],
        "author": "褚遂良",
        "dynasty": "唐",
        "era": "永徽四年（653）",
        "script": "kai",
        "carrier": "beike",
        "holder": "西安大雁塔",
        "rubbing": "宋拓",
        "summary": "褚遂良晚年代表作，"
        "楷书瘦劲飘逸、提按分明，线条如「美人婵娟」。是从楷入行的最佳过渡范本。",
        "layout": "两石，分《序》与《记》",
        "status": "reviewed",
        "notes": "书格未收。",
    },
    {
        "id": "zhang-meng-long",
        "title": "张猛龙碑",
        "aliases": ["鲁郡太守张府君清颂碑"],
        "author": "佚名",
        "dynasty": "北魏",
        "era": "正光三年（522）",
        "script": "kai",
        "carrier": "beike",
        "holder": "曲阜汉魏碑刻陈列馆",
        "rubbing": "明拓",
        "summary": "魏碑第一。"
        "方笔雄强、结体奇险而稳，被称为「魏碑中的楷书极则」。"
        "练方笔与骨力，此碑是绕不开的一课。",
        "layout": "碑阳 24 行，满行 46 字",
        "status": "reviewed",
        "notes": "书格未收。",
    },
    {
        "id": "dan-ba-bei",
        "title": "胆巴碑",
        "aliases": ["帝师胆巴碑"],
        "author": "赵孟頫",
        "dynasty": "元",
        "era": "延祐三年（1316）",
        "script": "kai",
        "carrier": "moji",
        "holder": "故宫博物院",
        "rubbing": "墨迹",
        "summary": "赵孟頫六十三岁书，"
        "「赵体」楷书代表作。笔画圆润流丽、起收含蓄，写来顺手，"
        "是从楷书过渡到行书最省力的一本。",
        "layout": "纸本，正文 120 余行",
        "status": "reviewed",
        "notes": "书格未收。",
    },
]


def main() -> int:
    config.WORK_DIR.mkdir(parents=True, exist_ok=True)
    written = skipped = 0
    for w in CORE:
        path = config.WORK_DIR / f"{w['id']}.yaml"
        if path.exists():
            skipped += 1
            continue
        w.setdefault("images", [])
        w.setdefault("sources", [])
        with path.open("w", encoding="utf-8") as f:
            yaml.safe_dump(w, f, allow_unicode=True, sort_keys=False, width=100)
        written += 1
        print(f"  + {path.name}")
    print(f"新增 {written} 条，跳过 {skipped} 条")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
