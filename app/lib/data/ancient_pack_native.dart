import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// 篆隶字形包：体积较大，首次使用时从 GitHub Release 下载。
class AncientPack {
  AncientPack._();

  static const _url =
      'https://github.com/vaaandark/huazi/releases/download/data-v1/glyphs-pack.sqlite';

  static Database? _db;
  static File? _file;

  static bool get supported => true;

  static bool get installed => _file?.existsSync() ?? false;

  static Future<File> _target() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    return _file = File(p.join(dir.path, 'glyphs-pack.sqlite'));
  }

  static Future<bool> ensureOpen() async {
    if (_db != null) return true;
    final f = await _target();
    if (!f.existsSync()) return false;
    _db = sqlite3.open(f.path, mode: OpenMode.readOnly);
    return true;
  }

  /// 下载并安装，onProgress 收到 0..1
  static Future<void> download(void Function(double progress) onProgress) async {
    final target = await _target();
    final tmp = File('${target.path}.part');
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(_url));
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final total = res.contentLength;
      final sink = tmp.openWrite();
      var received = 0;
      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress(received / total);
      }
      await sink.flush();
      await sink.close();
      if (target.existsSync()) target.deleteSync();
      tmp.renameSync(target.path);
      _db = null;
      await ensureOpen();
    } finally {
      client.close();
    }
  }

  static List<AncientGlyph> glyphs(int cp) {
    final db = _db;
    if (db == null) return const [];
    final rows = db.select(
      'SELECT script, seq, svg FROM glyph WHERE cp = ? '
      "ORDER BY CASE script WHEN 'zhuan' THEN 0 ELSE 1 END, seq",
      [cp],
    );
    return rows.map((r) {
      final blob = r['svg'] as List<int>;
      String svg;
      try {
        svg = utf8.decode(gzip.decode(blob));
      } catch (_) {
        svg = '';
      }
      return AncientGlyph(
        script: r['script'] as String,
        seq: r['seq'] as int,
        svg: svg,
      );
    }).toList();
  }

  static int count() {
    final db = _db;
    if (db == null) return 0;
    return db.select('SELECT COUNT(*) AS n FROM glyph').first['n'] as int;
  }
}

class AncientGlyph {
  final String script;
  final int seq;
  final String svg;
  const AncientGlyph({required this.script, required this.seq, required this.svg});

  String get scriptLabel => script == 'zhuan' ? '篆书' : '隶书';
}
