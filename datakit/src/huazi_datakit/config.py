"""路径与全局配置。"""

from pathlib import Path

# datakit/ 的上一层就是仓库根 huazi/
ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / "data"
WORK_DIR = DATA / "works"
TEXT_DIR = DATA / "texts"
CHARLIST_DIR = DATA / "charlists"
CACHE = DATA / "cache"
THUMB_DIR = CACHE / "img"
BUILD = ROOT / "build"

SHUGE_API = "https://www.shuge.org/wp-json/wp/v2"

# 书格资源集合分类
SHUGE_ENTRIES = {
    25: "书法",
    28: "碑拓",
}

USER_AGENT = "huazi-datakit/0.1 (+local calligraphy practice app)"

# 抓取礼貌间隔（书格 robots 要求 Crawl-delay: 10，这里按条目数控制）
SHUGE_DELAY = 1.0
