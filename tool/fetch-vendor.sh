#!/usr/bin/env bash
# 拉取构建所需的第三方数据（不进版本控制）
# 用法: bash tool/fetch-vendor.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/data/vendor"
mkdir -p "$VENDOR"

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }

# 1. 字形库：只取需要的层
if [ ! -d "$VENDOR/glyphs-src/glyphs" ]; then
  log "稀疏检出 hanzi-glyphs-svg（篆/隶/楷）"
  git clone --filter=blob:none --no-checkout --depth 1 \
    https://github.com/zhouyongh/hanzi-glyphs-svg.git "$VENDOR/glyphs-src"
  cd "$VENDOR/glyphs-src"
  git sparse-checkout init --cone
  git sparse-checkout set glyphs/glyph-ids.csv glyphs/seal glyphs/clerical glyphs/kaishu
  git checkout
fi

# 2. 笔顺
if [ ! -d "$VENDOR/strokes/package" ]; then
  log "下载 hanzi-writer-data"
  mkdir -p "$VENDOR/strokes"
  curl -sSL -o "$VENDOR/strokes/hwd.tgz" \
    https://registry.npmjs.org/hanzi-writer-data/-/hanzi-writer-data-2.0.1.tgz
  tar -xzf "$VENDOR/strokes/hwd.tgz" -C "$VENDOR/strokes"
fi

# 3. 结构分解
if [ ! -f "$VENDOR/dictionary.txt" ]; then
  log "下载 Make Me a Hanzi 字典"
  curl -sSL -o "$VENDOR/dictionary.txt" \
    https://raw.githubusercontent.com/skishore/makemeahanzi/master/dictionary.txt
fi

# 4. 字体（OFL）
mkdir -p "$VENDOR/fonts"
get() { [ -f "$2" ] || { log "下载 $(basename "$2")"; curl -sSL --retry 3 -o "$2" "$1"; }; }
get "https://github.com/lxgw/LxgwWenkaiGB/releases/download/v1.530/LXGWWenKaiGB-Regular.ttf" \
    "$VENDOR/fonts/LXGWWenKaiGB-Regular.ttf"
get "https://github.com/google/fonts/raw/main/ofl/zhimangxing/ZhiMangXing-Regular.ttf" \
    "$VENDOR/fonts/ZhiMangXing-Regular.ttf"

log "完成，下一步：cd datakit && uv run huazi-data build && uv run huazi-data fonts && uv run huazi-data ancient"
