# 字 · huazi

离线中文书法练习工具。碑帖库 + 字形对比 + 字帖导出，毛笔与硬笔双模式。
Android 与桌面端共用一套 Flutter 代码，数据全部内置，断网可用。

当前进度：**M1 — 碑帖库**。

## 现在能做什么

- 50 种碑帖离线浏览，按 **书体 / 朝代 / 载体** 三维筛选，支持搜索
- 详情页看高清图（缩略图本地、原图联网）、形制、收藏地、来源与许可
- 释文逐字可点，进入单字页
- 书家列表
- 手机单栏、桌面主从分栏自适应

## 目录

```
huazi/
├── datakit/          Python 数据管线（不进 app）
│   └── src/huazi_datakit/
│       ├── shuge.py      书格 API 客户端 + 页面解析
│       ├── enrich.py     书家/朝代/书体推断
│       ├── build_db.py   编译 SQLite
│       └── cli.py        命令行入口
├── tool/
│   ├── setup-toolchain.sh   免 root 装 Flutter/JDK/Android SDK
│   └── seed_core_works.py   补齐核心名碑
├── data/
│   ├── works/*.yaml   ★ 唯一需要长期维护的资产
│   ├── texts/         释文
│   └── charlists/     6763 / 3755 / 3008 字表
├── app/               Flutter
│   ├── lib/data/      SQLite 访问
│   └── lib/ui/        页面
└── build/             datakit 产物
```

## 快速开始

```bash
make setup          # Python 依赖（uv）
make data           # 从书格拉碑帖元数据 → data/works/*.yaml
make views          # 补写九成宫、玄秘塔、兰亭序等
make thumbs         # 下载缩略图（约 5 分钟）
make build          # 编译 SQLite 并同步到 app 资源
make run            # 跑 Linux 桌面版
make apk            # 打 Android 包
```

环境安装（Ubuntu / WSL，免 root）：

```bash
bash tool/setup-toolchain.sh
# 桌面构建还需要：
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev \
  libblkid-dev liblzma-dev libglu1-mesa-dev libgl1-mesa-dev
```

## WSL 下调试

图形走 WSLg，窗口直接出现在 Windows 桌面，但只有软件渲染（llvmpipe）：

```bash
export GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1
flutter run -d linux
```

Android 真机建议用无线调试（WSL 看不到 USB）：

```bash
adb pair 192.168.x.x:PORT
adb connect 192.168.x.x:5555
```

## 数据来源与许可

| 数据 | 来源 | 许可 |
|---|---|---|
| 碑帖元数据与缩略图 | [书格](https://www.shuge.org) | 逐条记录在 YAML 的 `rights` 字段 |
| 核心名碑元数据 | 手工整理 | 公有领域事实性信息 |
| 字形（M2） | `zhouyongh/hanzi-glyphs-svg` | CC0 / OFL / CC BY 4.0 |
| 笔顺（M2） | `hanzi-writer-data` | Arphic Public License |
| 字体（M2） | LXGW 文楷、志莽行书等 | OFL 1.1 |

书格各条的图像协议并不统一，常见 **CC BY 4.0** 与 **CC BY-NC 4.0**，已逐条写入
`data/works/*.yaml` 的 `rights` 字段，并在 app 详情页展示。**不镜像高清原图**，
只缓存 640px 缩略图并保留原始链接。

## 路线

| | 内容 |
|---|---|
| M1 | 碑帖库 ✓ |
| M2 | 单字页：篆隶字形、笔顺、楷行字体对比 |
| M3 | 字帖导出（米字格/田字格）+ 欧颜柳真迹切字 |
| M4 | 数字临摹、生字本、高清图缓存 |
