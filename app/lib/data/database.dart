import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// 首次启动（或数据版本变化）时把内置数据库拷到应用目录，之后离线查询。
class AppDatabase {
  AppDatabase._(this.db);
  final Database db;

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance!;

  static Future<AppDatabase> open() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationSupportDirectory();
    final target = File(p.join(dir.path, 'huazi.sqlite'));
    final stamp = File(p.join(dir.path, 'data.version'));

    // 数据版本来自 assets/db/manifest.json，构建 datakit 时生成
    var version = '0';
    try {
      final manifest = await rootBundle.loadString('assets/db/manifest.json');
      version = (jsonDecode(manifest) as Map)['version']?.toString() ?? '0';
    } catch (_) {}

    final current = stamp.existsSync() ? stamp.readAsStringSync() : '';
    if (!target.existsSync() || current != version) {
      final data = await rootBundle.load('assets/db/huazi.sqlite');
      await target.parent.create(recursive: true);
      await target.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      await stamp.writeAsString(version, flush: true);
    }

    final db = sqlite3.open(target.path, mode: OpenMode.readOnly);
    _instance = AppDatabase._(db);
    return _instance!;
  }

  Database get raw => db;
}
