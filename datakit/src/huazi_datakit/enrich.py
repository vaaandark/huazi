"""从著录文字里抽取书家、朝代，并做基础过滤。

原则：只做"可信的自动补全"，拿不准就留空，交给人工在 YAML 里补。
"""

from __future__ import annotations

import re

from .schema import Carrier, Script, Work

# 书家 → 朝代。按名字长度倒序匹配，避免「王羲之」被「王」类误伤。
CALLIGRAPHERS: dict[str, str] = {
    "王羲之": "东晋", "王献之": "东晋", "王珣": "东晋", "钟繇": "曹魏",
    "索靖": "西晋", "陆机": "西晋", "卫夫人": "东晋",
    "智永": "隋", "欧阳询": "唐", "欧阳通": "唐", "虞世南": "唐",
    "褚遂良": "唐", "薛稷": "唐", "李世民": "唐", "李邕": "唐",
    "颜真卿": "唐", "柳公权": "唐", "怀素": "唐", "张旭": "唐",
    "孙过庭": "唐", "冯承素": "唐", "怀仁": "唐", "李阳冰": "唐",
    "杨凝式": "五代",
    "苏轼": "北宋", "黄庭坚": "北宋", "米芾": "北宋", "蔡襄": "北宋",
    "李建中": "北宋", "赵佶": "北宋",
    "陆游": "南宋", "朱熹": "南宋", "张即之": "南宋",
    "赵孟頫": "元", "鲜于枢": "元", "杨维桢": "元", "邓文原": "元",
    "康里巎巎": "元",
    "文徵明": "明", "文彭": "明", "董其昌": "明", "祝允明": "明",
    "王铎": "明", "徐渭": "明", "王宠": "明", "倪元璐": "明",
    "陈淳": "明", "唐寅": "明",
    "傅山": "清", "朱耷": "清", "金农": "清", "郑燮": "清",
    "邓石如": "清", "伊秉绶": "清", "何绍基": "清", "赵之谦": "清",
    "吴昌硕": "清", "王文治": "清", "刘墉": "清", "翁方纲": "清",
    "李斯": "秦", "蔡邕": "东汉", "张芝": "东汉", "皇象": "三国吴",
}

DYNASTY_BY_ENTRY = {
    152: "先秦", 153: "两汉", 154: "魏晋南北朝", 155: "隋唐五代",
    156: "宋辽金", 157: "元代", 158: "明代", 159: "清代",
    160: "民国", 162: "四九后",
}

# 不是练字对象的条目（绘画、农书、书目），保留在库里但标记 excluded。
EXCLUDED_SLUGS = {
    "chen-fu-nong-shu": "农书，非书法",
    "xuan-he-shu-pu": "书学著录，非字帖",
    "zhi-ping-jin-jian-ce": "政书抄本",
    "lao-zi-shou-jing-tu": "绘画",
    "gu-xian-shi-yi-tu": "绘画",
    "cai-lian-tu-juan": "绘画",
    "cao-tang-shi-zhi-tu-juan": "绘画",
    "tian-xia-ming-shan-tu-ce": "绘画",
    "xie-jing-huan-cha-tu-juan": "绘画",
    "chen-fu-nong-shu-ce": "农书，非书法",
}

_NAMES_SORTED = sorted(CALLIGRAPHERS, key=len, reverse=True)


def find_author(*texts: str | None) -> str | None:
    for t in texts:
        if not t:
            continue
        for name in _NAMES_SORTED:
            if name in t:
                return name
    return None


def dynasty_from_entries(entry_ids: list[int]) -> str | None:
    for eid in entry_ids:
        if eid in DYNASTY_BY_ENTRY:
            return DYNASTY_BY_ENTRY[eid]
    return None


def _shuge_id(work: Work) -> int | None:
    m = re.search(r"shuge_id=(\d+)", work.notes or "")
    return int(m.group(1)) if m else None


def enrich(work: Work, entry_ids: list[int] | None = None) -> Work:
    """就地补全 author / dynasty / script / carrier，返回同一个对象。"""
    author = find_author(work.title, work.summary, work.description)
    if author and not work.author:
        work.author = author
    if work.author and not work.dynasty:
        work.dynasty = CALLIGRAPHERS.get(work.author)
    if not work.dynasty and entry_ids:
        work.dynasty = dynasty_from_entries(entry_ids)
    if work.dynasty and "隋唐五代" in work.dynasty:
        work.dynasty = "唐"

    if work.script is None:
        for t in (work.summary, work.description):
            if not t:
                continue
            for key, s in (
                ("楷书", Script.kai), ("行书", Script.xing), ("行楷", Script.xing),
                ("草书", Script.cao), ("隶书", Script.li), ("篆书", Script.zhuan),
            ):
                if key in t:
                    work.script = s
                    break
            if work.script:
                break

    # 「碑」「墓志」「造像」出现在标题里时，修正载体
    title = work.title
    if "墓志" in title:
        work.carrier = Carrier.muzhi
    elif "造像" in title:
        work.carrier = Carrier.zaoxiang
    elif "摩崖" in title:
        work.carrier = Carrier.moya
    elif title.endswith("碑") or "碑" in title:
        work.carrier = Carrier.beike

    # 从著录里抽行数、每行字数
    if work.lines is None and work.description:
        m = re.search(r"共\s*([一二三四五六七八九十百零\d]+)\s*行", work.description)
        if m:
            work.lines = _cn_num(m.group(1))
    if work.chars_per_line is None and work.description:
        m = re.search(r"满行\s*([一二三四五六七八九十百零\d]+)\s*字", work.description)
        if m:
            work.chars_per_line = _cn_num(m.group(1))

    slug = work.id
    if slug in EXCLUDED_SLUGS:
        work.notes = f"{work.notes or ''}\nexcluded: {EXCLUDED_SLUGS[slug]}".strip()
    return work


_CN_DIGITS = {"零": 0, "一": 1, "二": 2, "三": 3, "四": 4, "五": 5,
              "六": 6, "七": 7, "八": 8, "九": 9}


def _cn_num(s: str) -> int | None:
    if s.isdigit():
        return int(s)
    if "十" in s:
        a, _, b = s.partition("十")
        tens = _CN_DIGITS.get(a, 1) if a else 1
        ones = _CN_DIGITS.get(b, 0) if b else 0
        return tens * 10 + ones
    total = 0
    for ch in s:
        if ch in _CN_DIGITS:
            total = total * 10 + _CN_DIGITS[ch]
    return total or None
