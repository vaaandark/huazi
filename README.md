# 字 · huazi

离线的中文书法练习工具。碑帖库、单字字形对比、A4 字帖生成，毛笔与硬笔两条线。
Android 与桌面端共用一套 Flutter 代码，数据全部内置，**断网可用**。

[![build](https://github.com/vaaandark/huazi/actions/workflows/build.yml/badge.svg)](https://github.com/vaaandark/huazi/actions/workflows/build.yml)

## 功能

**碑帖库**（44 种）
- 按 书体 / 朝代 / 载体（碑刻·刻帖·墨迹·墓志…）三维筛选，支持搜索
- 详情页大图翻页缩放，点图看联网高清原图
- 书家、行数、满行字数、形制、收藏地、拓本类型
- 释文逐字可点，直达单字页

**单字页**
- 6763 字：笔顺分步演示（可自动播放）、笔画数、结构类型、部件分解、部首、拼音
- 楷书 / 行楷两种写法并排对比
- 篆书 · 隶书字形（1.2 万字形，覆盖 4719 字，按需下载 37MB 字形包）
- 田字格 / 米字格切换

**字帖**
- A4 排版，每行一字：首格实写，其余描红
- 田字格 / 米字格 / 方格；空临 / 浅描 / 描红三档
- 楷书、行楷两套字体
- 内置预设：基本笔画、常用偏旁、常用 60 字、千字文
- 导出 PDF，Android 直接调系统分享/打印

**其他**
- 生字本（收藏常练的字）
- 数字临摹：半透明范字上直接写
- 手机底部导航 / 桌面主从分栏自适应

## 截图

> 见 [docs/screenshots](docs/screenshots)

## 在线试用

**https://vaaandark.top/huazi/** — Flutter WASM 版，无需安装。
数据内置在 14MB 的 SQLite 里，由 `sqlite3.wasm` 通过自定义只读 VFS 直接打开。
（网页版不提供 37MB 的篆隶字形包下载。）

## 安装

从 [Releases](https://github.com/vaaandark/huazi/releases) 下载：

| 平台 | 文件 |
|---|---|
| Android (arm64) | `huazi-android-arm64.apk` |
| Android 模拟器 (x86_64) | `huazi-android-x86_64.apk` |
| Linux x64 | `huazi-linux-x64.tar.gz` |
| Windows / macOS | 由 GitHub Actions 构建，见 Actions 产物 |

## 开发

```bash
bash tool/setup-toolchain.sh      # Flutter + JDK + Android SDK（免 root）
bash tool/fetch-vendor.sh         # 第三方数据（字形/笔顺/字体）
make setup data views thumbs build
make run                          # 桌面版
make apk                          # Android 包
```

### WSL 下调试

WSLg 会直接把窗口映射到 Windows 桌面，但只有软件渲染：

```bash
export GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1
flutter run -d linux
```

Android 真机走无线调试（WSL 看不到 USB）：

```bash
adb pair 192.168.x.x:PORT && adb connect 192.168.x.x:5555
```

## 结构

```
huazi/
├── datakit/                  Python 数据管线
│   └── src/huazi_datakit/
│       ├── shuge.py          书格 API 客户端 + 页面解析
│       ├── enrich.py         书家/朝代/书体推断
│       ├── glyphdata.py      笔顺、部件、篆隶字形、字体子集
│       ├── ancient_pack.py   篆隶字形包
│       └── build_db.py       编译 SQLite
├── tool/
│   ├── setup-toolchain.sh    免 root 装工具链
│   ├── fetch-vendor.sh       拉第三方数据
│   └── seed_core_works.py    补齐核心名碑
├── data/
│   ├── works/*.yaml          ★ 唯一需要长期维护的资产
│   └── charlists/            6763 / 3755 / 3008 字表
├── app/                      Flutter（Android/Linux/Windows/WASM）
│   ├── lib/data/             SQLite、篆隶包、生字本
│   ├── lib/pdf/              字帖排版
│   └── lib/ui/               页面
└── build/                    datakit 产物
```

## 数据来源与许可

| 数据 | 来源 | 许可 |
|---|---|---|
| 碑帖元数据与缩略图 | [书格](https://www.shuge.org) | 逐条记录在 YAML `rights` 字段 |
| 核心名碑元数据 | 手工整理 | 公有领域事实性信息 |
| 篆隶字形 | [hanzi-glyphs-svg](https://github.com/zhouyongh/hanzi-glyphs-svg) | CC0 / OFL 1.1 |
| 笔顺 | [hanzi-writer-data](https://github.com/chanind/hanzi-writer-data) | Arphic Public License |
| 结构/部件 | [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) | LGPL / Arphic |
| 字体 | LXGW 文楷 GB、志莽行书 | SIL OFL 1.1 |

代码以 MIT 释出；数据另有许可，详见 [NOTICE.md](NOTICE.md)。
部分碑帖图像为 **CC BY-NC 4.0**，本项目仅作个人练习与非商业用途。

**不镜像高清原图**：只缓存 640px 缩略图，保留原始链接。

## 路线

| | 内容 | 状态 |
|---|---|---|
| M1 | 碑帖库 | ✅ |
| M2 | 单字页（笔顺/结构/篆隶包） | ✅ |
| M3 | 字帖生成 | ✅ |
| M4 | 生字本、数字临摹 | ✅ |
| M5 | 欧颜柳真迹单字切图 | 待拓本图源 |
| M6 | 分级课程（小学 300/1600/2500） | 待字表数据 |
