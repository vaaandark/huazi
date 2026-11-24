"""书格 (shuge.org) WordPress REST API 客户端。

只读公开 API；robots.txt 仅禁止 /dl/ 下载区，本模块不访问该路径。
"""

from __future__ import annotations

import html
import re
import time
from datetime import date
from typing import Any, Iterable

import httpx

from . import config
from .schema import Carrier, Script, Source, Work, WorkImage

_IMG_SUFFIX = re.compile(r"-\d+x\d+(?=\.\w+$)")
_TAG = re.compile(r"<[^>]+>")
_PAGER = re.compile(r"^(\s*上一页\s*下一页)+\s*([0-9]+\s*)+")


def _client() -> httpx.Client:
    return httpx.Client(
        timeout=30.0,
        follow_redirects=True,
        headers={"User-Agent": config.USER_AGENT},
    )


def get_json(path: str, params: dict[str, Any] | None = None) -> httpx.Response:
    with _client() as c:
        r = c.get(f"{config.SHUGE_API}{path}", params=params)
        r.raise_for_status()
        return r


def list_portfolio(entry_ids: Iterable[int], per_page: int = 100) -> list[dict]:
    """列出指定资源集合下的所有条目（只取必要字段）。"""
    out: list[dict] = []
    for entry in entry_ids:
        with _client() as c:
            r = c.get(
                f"{config.SHUGE_API}/portfolio",
                params={
                    "portfolio_entries": entry,
                    "per_page": per_page,
                    "page": 1,
                    "_fields": "id,slug,title,link,portfolio_entries,featured_media",
                },
            )
            r.raise_for_status()
            out.extend(r.json())
    return out


def get_item(item_id: int) -> dict:
    r = get_json(f"/portfolio/{item_id}")
    return r.json()


# ---------------------------------------------------------------- 解析


def extract_images(html_text: str) -> list[str]:
    """从正文里抽出图集图片，去重、还原原图尺寸、按页序排序。"""
    urls = re.findall(r"<img[^>]*src=['\"]([^'\"]+)['\"]", html_text)
    clean: dict[str, str] = {}
    for u in urls:
        if "/wp-content/uploads/" not in u:
            continue
        full = _IMG_SUFFIX.sub("", u)
        clean.setdefault(full, full)

    def sort_key(u: str) -> tuple[int, str]:
        stem = u.rsplit("/", 1)[-1].rsplit(".", 1)[0]
        m = re.search(r"(\d+)$", stem)
        return (int(m.group(1)) if m else 0, stem)

    return sorted(clean, key=sort_key)


def clean_text(html_text: str) -> str:
    """把正文 HTML 压成纯文本，去掉图集翻页按钮、标签、多余空白。"""
    t = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", html_text, flags=re.S | re.I)
    t = _TAG.sub(" ", t)
    t = html.unescape(t)
    t = _PAGER.sub("", t)
    t = re.sub(r"[ \t\u00a0]+", " ", t)
    t = re.sub(r"\n\s*\n+", "\n", t)
    return t.strip()


# 书格详情页尾部的结构化字段标题
SECTION_KEYS = [
    "释文", "版本信息", "书写信息", "创作时间", "责任人信息", "行款版式",
    "形制尺寸", "钤印信息", "题跋信息", "收藏来源", "版权协议", "参考文献",
    "文件名", "存档目录", "文件格式", "在线浏览高清图", "下载链接",
    "分享", "初步评估", "内容修订", "参与修订者", "更新记录", "已同步推送",
]
_SECTION_RE = re.compile(
    "(" + "|".join(re.escape(k) for k in sorted(SECTION_KEYS, key=len, reverse=True)) + ")"
)

# 用来截断「正文」和「释文」的边界
_BODY_BOUNDARY = {"版本信息", "书写信息", "责任人信息", "行款版式", "形制尺寸",
                  "钤印信息", "题跋信息", "收藏来源", "版权协议", "文件名",
                  "存档目录", "文件格式", "在线浏览高清图", "下载链接"}
_TRANS_BOUNDARY = {"书写信息", "版本信息", "收藏来源", "版权协议", "在线浏览高清图",
                   "下载链接", "存档目录", "文件格式"}


def split_sections(text: str) -> tuple[str, dict[str, str]]:
    """把页面纯文本切成 (正文, {字段名: 内容})。"""
    pieces = _SECTION_RE.split(text)
    preamble = pieces[0].strip()
    fields: dict[str, str] = {}
    for i in range(1, len(pieces) - 1, 2):
        key, val = pieces[i], pieces[i + 1]
        fields.setdefault(key, val.strip())
    return preamble, fields


def split_body(text: str) -> str:
    """去掉「撰自 … / 类目 … / 日期」这段页头，只留正文。"""
    m = re.search(r"\d{4}年\d{1,2}月\d{1,2}日\s*", text)
    return text[m.end():].strip() if m else text


SCRIPT_KEYS = (
    ("行楷", Script.xing), ("行草", Script.xing), ("楷书", Script.kai),
    ("行书", Script.xing), ("草书", Script.cao), ("隶书", Script.li),
    ("篆书", Script.zhuan),
)


def detect_script(*texts: str | None) -> Script | None:
    """按优先级在若干段文字里找书体。"""
    for t in texts:
        if not t:
            continue
        for key, s in SCRIPT_KEYS:
            if key in t:
                return s
    return None


def detect_rubbing(text: str) -> str | None:
    m = re.search(r"(北宋拓本|南宋拓本|宋拓本|宋拓|明拓本|明拓|清拓本|清拓|初拓本|旧拓本|唐代拓本)", text)
    return m.group(1) if m else None


DYNASTY_TOKENS = {
    "先秦", "秦", "两汉", "汉", "东汉", "西汉", "三国", "曹魏", "西晋", "东晋", "晋",
    "南北朝", "隋", "唐", "唐代", "五代", "北宋", "南宋", "宋", "宋代",
    "辽", "金", "元", "元代", "明", "明代", "清", "清代", "民国",
    "明末清初", "宋辽金", "隋唐五代", "魏晋南北朝", "未知朝代",
}


def parse_responsible(text: str) -> tuple[str | None, str | None, Script | None]:
    """解析「责任人信息 唐代 颜真卿 行书」这类字段（仅作兜底）。"""
    dynasty = author = None
    m = re.search(r"(先秦|秦|两汉|三国[吴魏蜀]?|曹魏|西晋|东晋|晋|南北朝|隋|唐|五代|北宋|南宋|宋|元|明|清|民国)", text)
    if m:
        dynasty = m.group(1)
    for name in re.split(r"[、,，/\s]+", text):
        name = re.sub(r"(撰文|书丹|書丹|书|書|撰|刻|镌|題額|题额|篆额|集字)", "", name)
        if 2 <= len(name) <= 4 and re.fullmatch(r"[\u4e00-\u9fa5]+", name) and name not in DYNASTY_TOKENS:
            author = author or name
    return dynasty, author, detect_script(text)


def build_draft(item: dict) -> Work:
    """把一个 WP 条目转成 Work 草稿。"""
    from .enrich import CALLIGRAPHERS, find_author

    content_html = item.get("content", {}).get("rendered", "")
    title = clean_text(item.get("title", {}).get("rendered", ""))
    summary = clean_text(item.get("excerpt", {}).get("rendered", ""))

    raw = split_body(clean_text(content_html))
    body, fields = split_sections(raw)

    holder = fields.get("收藏来源")
    if holder:
        holder = re.split(r"[（(]", holder)[0].strip()
        holder = re.sub(r"^(此系列|此卷|此本|此套|此为|此)\s*现藏于[:：]?\s*", "", holder)
        holder = re.sub(r"^(现藏于|藏于[:：]?)\s*", "", holder)
        holder = re.sub(r"[\s，,。：:]*藏本?$", "", holder).strip()

    rights = fields.get("版权协议")
    if rights:
        rights = re.sub(r"\s*\*.*$", "", rights, flags=re.S).strip()
        rights = re.sub(r"\s*\n\s*", " ", rights).strip()

    # 「文件名」字段格式最规整：多宝塔碑. 唐. 颜真卿. 书. 北宋拓本. 东京国立博物馆藏
    file_name = fields.get("文件名", "")
    responsible = fields.get("责任人信息", "")

    dynasty, resp_author, resp_script = parse_responsible(responsible)
    author = (
        find_author(file_name)
        or find_author(responsible)
        or find_author(title)
        or resp_author
    )
    if author and not dynasty:
        dynasty = CALLIGRAPHERS.get(author)

    script = (
        detect_script(file_name)
        or detect_script(summary)
        or detect_script(responsible)
        or detect_script(title)
        or resp_script
    )

    layout = fields.get("行款版式") or fields.get("形制尺寸")
    if layout:
        layout = layout.strip()

    transcription = fields.get("释文")
    if transcription:
        transcription = transcription.strip()[:20000]

    entries = item.get("portfolio_entries", [])
    carrier = Carrier.beike if 28 in entries else Carrier.moji

    images = [
        WorkImage(seq=i + 1, remote=u)
        for i, u in enumerate(extract_images(content_html))
    ]

    slug = (item.get("slug") or f"work-{item['id']}").replace("_", "-")
    return Work(
        id=slug,
        title=title,
        summary=summary or None,
        description=body or None,
        transcription=transcription,
        author=author,
        dynasty=dynasty,
        script=script,
        carrier=carrier,
        holder=holder,
        rights=rights,
        layout=layout,
        rubbing=detect_rubbing(file_name) or detect_rubbing(f"{summary}\n{raw}"),
        images=images,
        sources=[
            Source(
                name="书格",
                url=item.get("link"),
                license=rights,
                retrieved=date.today().isoformat(),
            )
        ],
        status="draft",
        notes=f"shuge_id={item['id']}",
    )


def fetch_all(entry_ids: Iterable[int], limit: int | None = None) -> list[Work]:
    items = list_portfolio(entry_ids)
    if limit:
        items = items[:limit]
    works: list[Work] = []
    for i, it in enumerate(items, 1):
        print(f"  [{i}/{len(items)}] {it['title']['rendered']}")
        full = get_item(it["id"])
        works.append(build_draft(full))
        time.sleep(config.SHUGE_DELAY)
    return works
