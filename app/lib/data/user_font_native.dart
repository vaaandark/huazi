import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户导入的字体。
///
/// 硬笔行书等字帖字体通常禁止随应用分发，但允许用户在自己设备上使用。
/// 这里只读取用户本地选择的字体文件，不内置、不上传。
class UserFont {
  UserFont._();

  static const family = 'UserFont';
  static String? displayName;
  static ByteData? bytes;

  static bool get available => bytes != null;

  static Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'fonts'));
    await dir.create(recursive: true);
    return dir;
  }

  /// 启动时恢复上次导入的字体
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('user_font_path');
    if (path == null) return;
    final f = File(path);
    if (!f.existsSync()) return;
    final data = await f.readAsBytes();
    displayName = prefs.getString('user_font_name') ?? '我的字体';
    await _register(data);
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

    final dir = await _dir();
    final name = p.basenameWithoutExtension(picked.path);
    final target = File(p.join(dir.path, "user-font${p.extension(picked.path)}"));
    await target.writeAsBytes(data, flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_font_path', target.path);
    await prefs.setString('user_font_name', name);

    displayName = name;
    await _register(data);
    return name;
  }

  static Future<void> _register(Uint8List data) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.view(data.buffer)));
    await loader.load();
    bytes = ByteData.view(data.buffer);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('user_font_path');
    if (path != null) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }
    await prefs.remove('user_font_path');
    await prefs.remove('user_font_name');
    displayName = null;
    bytes = null;
  }
}
