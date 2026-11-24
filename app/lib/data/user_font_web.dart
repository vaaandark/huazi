import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 网页版：不走网络下载（GitHub Release 没有 CORS 头），
/// 改为让用户从本地选择字体文件，读字节后注册到 CanvasKit。
class UserFont {
  UserFont._();

  static const family = 'UserFont';
  static String? displayName;
  static ByteData? bytes;

  static final ValueNotifier<int> revision = ValueNotifier(0);

  static bool get available => bytes != null;

  static void _bump() => revision.value++;

  /// 浏览器不做持久化，刷新后需要重新选择。
  static Future<void> restore() async {}

  static Future<String?> downloadUrl() async => null;

  static Future<void> setDownloadUrl(String? url) async {}

  static Future<void> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    displayName = trimmed;
    _bump();
  }

  static Future<String> downloadRecommended(
    void Function(double progress) onProgress,
  ) async {
    throw UnsupportedError('网页版请用「选择字体文件」导入本地字体');
  }

  static Future<String?> import() async {
    const typeGroup = XTypeGroup(
      label: '字体',
      extensions: ['ttf', 'otf', 'TTF', 'OTF'],
    );
    final picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked == null) return null;
    final data = await picked.readAsBytes();
    if (data.length < 4096) throw const FormatException('文件太小，可能不是字体');

    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(data.buffer)));
    await loader.load();
    bytes = ByteData.view(data.buffer);
    displayName = picked.name
        .replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '');
    _bump();
    return displayName;
  }

  static Future<void> clear() async {
    displayName = null;
    bytes = null;
    _bump();
  }
}
