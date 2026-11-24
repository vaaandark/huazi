# 数据

## 一句话

**`data/works/*.yaml` 是这个仓库唯一需要长期维护的数据资产**，其余（字形、笔顺、字体）
都可以由脚本重新拉取和生成。

## 碑帖 YAML

一条碑帖一个文件，字段如下（`id` 必须与文件名一致）：

```yaml
id: jiu-cheng-gong
title: 九成宫醴泉铭
aliases: [九成宫碑]
author: 欧阳询            # 书家
writer: 魏征              # 撰文
carver: 刻工不详
dynasty: 唐
era: 贞观六年（632）
script: kai               # zhuan | li | kai | xing | cao
carrier: beike            # beike|muzhi|moya|zaoxiang|ketie|moji|xiejing
lines: 24
chars_per_line: 50
total_chars: 1108
holder: 故宫博物院（李祺本）
rubbing: 宋拓
layout: 碑高 2.7 米，24 行，满行 50 字
summary: >
  欧阳询七十六岁所书，「欧体」第一代表作……
description: |
  更长的著录文字……
transcription: |
  释文全文，逐字可点进单字页
rights: 公有领域
images:
  - seq: 1
    remote: https://www.shuge.org/wp-content/uploads/...
    thumb: cache/img/jiu-cheng-gong-001.webp
    license: 公有领域（原作），扫描件来自书格
sources:
  - name: 书格
    url: https://www.shuge.org/view/...
status: reviewed          # draft | reviewed
notes: 书格未收。图源可参考故宫博物院数字文物库。
```

### `carrier` 为什么重要

练字的人区分「临碑」和「临帖」：碑刻是刀刻后拓的，笔锋被刀工改变；墨迹能看到原始的起收和墨色。
所以筛选器把载体单列，而不是塞进标签里。

## 许可

- **不镜像高清原图**：只缓存 640px 缩略图，原图保留原始 URL 与许可。
- 书格各条的图像协议不统一，常见 CC BY 4.0 与 CC BY-NC 4.0，逐条写入 `rights`。
- 抓取遵守 `robots.txt`（不访问 `/dl/`），请求间隔 ≥1s。
- 汇总清单由脚本生成，见 [NOTICE.md](../NOTICE.md)。

## 增删改一条碑帖

```bash
# 从书格批量导入草稿（已存在的跳过）
cd datakit && uv run huazi-data import

# 只导入某几条（资源集合 id：25=书法 28=碑拓）
uv run huazi-data import --entries 25 --limit 5

# 补全书家/朝代/书体（基于著录文字推断，拿不准会留空）
uv run huazi-data enrich

# 校验：必填字段、枚举、重复 id、图片许可
uv run huazi-data validate

# 重新编译数据库
uv run huazi-data build
```

手工补一条名碑（书格没有的）可以直接写 YAML，参考 `tool/seed_core_works.py`。

校验规则（`huazi-data validate`）：

- `id` 与文件名一致，全局唯一
- `script` / `carrier` 必须是枚举值
- `author` / `dynasty` / `script` / `carrier` / `summary` 缺失 → 警告
- 图片缺 `license` → 警告
- 没有任何图片 → 警告（会生成纸色占位封面）

## 字形与笔顺

```bash
bash tool/fetch-vendor.sh     # 稀疏检出字形库、下载笔顺/结构/字体
cd datakit
uv run huazi-data build       # 主库（含字元与笔顺）
uv run huazi-data fonts       # 字体子集化 → app/assets/fonts
uv run huazi-data ancient     # 篆隶字形包 → build/glyphs-pack.sqlite
```

| 数据 | 来源 | 说明 |
|---|---|---|
| 篆隶字形 | `zhouyongh/hanzi-glyphs-svg` | 稀疏检出 `glyphs/{seal,clerical,kaishu}` + `glyph-ids.csv` 账本；简体先转繁再查 |
| 笔顺 | `hanzi-writer-data` | 6763 字，JSON 存为 gzip BLOB |
| 结构 | `Make Me a Hanzi` | IDS 分解、部首、拼音 |
| 字体 | LXGW 文楷 GB / 志莽行书 | `pyftsubset` 裁到 6763 字 + ASCII，约 3–4 MB/款 |

## 可选包

体积大的数据不进安装包，放到 GitHub Release，应用内按需下载：

| 包 | 体积 | 说明 |
|---|---|---|
| 篆隶字形 `glyphs-pack.sqlite` | 37 MB | 12,313 个字形，覆盖 4719 字 |
| 硬笔行书 `RamegaZhangQingpingYingbiXingshu.ttf` | 10 MB | 原文件未修改，用户主动下载 |

字体包的授权比较特殊（免费商用，但禁止修改再发布），所以**不做子集化**、**不内置**，
并在界面上写明授权与使用边界。

## 字表

`huazi-data chars` 生成三份，均来自 GB2312，不需要外部数据：

- `6763.txt` 全部一二级汉字
- `3755.txt` 一级（常用）
- `3008.txt` 二级
