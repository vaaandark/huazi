# 架构

`huazi` 分两层：**构建期的数据管线**（Python）和**运行期的应用**（Flutter）。
应用里没有服务端，也没有 webview 套壳。

```
┌──────────────────────────────────────────────┐
│ datakit/  (Python, 只在电脑上跑)               │
│                                              │
│  shuge.py    书格 API → YAML                  │
│  enrich.py   书家/朝代/书体推断                 │
│  glyphdata.py 笔顺 / 部件 / 篆隶字形 / 字体子集  │
│  build_db.py YAML + 二进制 → SQLite            │
└───────────────────┬──────────────────────────┘
                    │  build/huazi.sqlite
                    │  build/thumbs/*.webp
                    │  app/assets/fonts/*.ttf
                    │  build/glyphs-pack.sqlite（可选包）
                    ▼
┌──────────────────────────────────────────────┐
│ app/  (Flutter)                               │
│                                              │
│  assets/db/huazi.sqlite  → 运行时只读打开       │
│  assets/thumbs/          → 本地缩略图           │
│  assets/fonts/           → 文楷 / 志莽          │
└──────────────────────────────────────────────┘
```

## 为什么不在运行时解析原始数据

- 手机端解析 8000 个 YAML/JSON 太慢，且需要重复实现查询逻辑；
- SQLite 的 FTS5 + 索引可以直接支撑筛选与全文搜索；
- 构建期一次性完成「抓取 → 清洗 → 校验 → 编译」，运行时零网络依赖。

## 数据库

主库 `huazi.sqlite`（约 13 MB）是只读的，包含：

| 表 | 用途 |
|---|---|
| `work` | 碑帖元数据（书家、朝代、书体、载体、形制、拓本、许可…） |
| `work_image` | 图片（本地缩略图路径 + 远端原图 URL） |
| `person` | 书家 |
| `char` | 6763 字：拼音、部首、结构、IDS 分解、笔画数 |
| `stroke` | 笔顺 JSON（gzip 压缩的 BLOB） |
| `work_fts` | FTS5 全文索引（标题 / 书家 / 简介 / 释文） |

可选包 `glyphs-pack.sqlite`（约 37 MB）单独存放篆隶字形：

| 表 | 用途 |
|---|---|
| `glyph` | `(cp, script, seq)` → gzip 后的 SVG 文本 |

## 平台适配

同一份 `lib/` 通过**条件导入**适配五个平台：

| 能力 | 原生（Android/Linux/Windows/macOS） | Web |
|---|---|---|
| 打开数据库 | 拷到应用目录，`sqlite3` FFI | `sqlite3.wasm` + 自定义只读内存 VFS |
| 保存 PDF | 写文件 / 系统分享 | Blob + `<a download>` |
| 导入字体 | 读文件 + 持久化 | `<input type=file>` + `FontLoader`，不落盘 |
| 篆隶包 | 下载到应用目录 | 不提供 |

关键文件：

```
lib/data/database.dart        facade（条件导入）
lib/data/db_open_native.dart  FFI + 版本化拷贝
lib/data/db_open_web.dart     WasmSqlite3 + ReadOnlyVfs
lib/util/save_pdf*.dart
lib/data/user_font*.dart
lib/data/ancient_pack*.dart
```

### Web 为什么能直接读 SQLite

不做 IndexedDB，也不做 OPFS。数据是只读的，所以实现一个 `VirtualFileSystem`，
把 `assets/db/huazi.sqlite` 的字节当作一个文件暴露给 SQLite：

```dart
final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.base.resolve('sqlite3.wasm'));
sqlite3.registerVirtualFileSystem(_ReadOnlyDb(bytes), makeDefault: true);
return sqlite3.open('/huazi.sqlite', mode: OpenMode.readOnly);
```

`xRead` 直接从 `Uint8List` 拷贝，`xWrite` 抛 `SQLITE_READONLY`。

## 渲染

**笔顺**：`hanzi-writer-data` 的笔画是 1024×1024、y 轴向上的 SVG path。
把每笔包成 `<svg viewBox="0 -124 1024 1024">`，用 `flutter_svg` 画，
已完成的笔画填墨色、当前笔填朱砂、未到的填淡灰，做成「分步 + 自动播放」。

**篆隶**：`hanzi-glyphs-svg` 的 SVG 存在 SQLite BLOB 里（gzip），按需解压渲染。

**字帖 PDF**：`pdf` 包排版，字体用子集化的 TTF 嵌入，保证在手机上打印时字形正确。
版式规则（每行一字、首格实写、描红档位）在 `lib/pdf/worksheet_pdf.dart`，
界面预览 `lib/ui/widgets/worksheet_preview.dart` 与它保持一致。

## 数据版本

构建时写 `build/manifest.json`（版本号 = 构建时间戳）。应用启动时对比
应用目录里的 `data.version`，不一致才重新拷贝内置库，避免升级后读到旧数据。

## CI

- `build.yml`：Android release APK + Windows release + macOS debug（无证书）+ `flutter test`
- `pages.yml`：`flutter build web --wasm` → GitHub Pages

macOS 的 release 构建需要开发者证书，因此 CI 用 debug（ad-hoc 签名）做冒烟验证。
