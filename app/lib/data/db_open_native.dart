import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

/// 桌面/移动端：首次启动或数据版本变化时把内置库拷到应用目录。
Future<CommonDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final target = File(p.join(dir.path, 'huazi.sqlite'));
  final stamp = File(p.join(dir.path, 'data.version'));

  var version = '0';
  try {
    final manifest = await rootBundle.loadString('assets/db/manifest.json');
    version = _versionOf(manifest);
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

  return sqlite3.open(target.path, mode: OpenMode.readOnly);
}

String _versionOf(String manifest) {
  final i = manifest.indexOf('"version"');
  if (i < 0) return '0';
  final start = manifest.indexOf('"', i + 9);
  final end = manifest.indexOf('"', start + 1);
  if (start < 0 || end < 0) return '0';
  return manifest.substring(start + 1, end);
}
