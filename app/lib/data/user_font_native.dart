import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

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

  /// 字体变化时自增，界面用 ListenableBuilder 监听即可立即刷新
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static const defaultDownloadUrl =
      'https://github.com/vaaandark/huazi/releases/download/fonts-v1/RamegaZhangQingpingYingbiXingshu.ttf';

  static bool get available => bytes != null;

  static void _bump() => revision.value++;

  /// 自定义下载地址（网络受限时填镜像）
  static Future<String?> downloadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('font_download_url');
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  static Future<void> setDownloadUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove('font_download_url');
    } else {
      await prefs.setString('font_download_url', url.trim());
    }
    _bump();
  }

  /// 给导入的字体改一个好记的名字
  static Future<void> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_font_name', trimmed);
    displayName = trimmed;
    _bump();
  }

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
    _bump();
  }

  /// 从发布页下载可选字体包（不做任何修改，原样保存）
  static Future<String> downloadRecommended(
    void Function(double progress) onProgress,
  ) async {
    final custom = await downloadUrl();
    final url = custom ?? defaultDownloadUrl;
    const name = '硬笔行书 · 张清平';

    final dir = await _dir();
    final target = File(p.join(dir.path, 'ramega-xingshu.ttf'));
    final tmp = File('${target.path}.part');

    final client = HttpClient();
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || uri.host.isEmpty) {
        throw HttpException('地址无效');
      }
      final req = await client.getUrl(uri);
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
    } on SocketException catch (e) {
      throw SocketException(
        '连不上 ${Uri.parse(url).host}。可能是网络限制，'
        '可以在「下载地址」里换一个镜像，或改成手动导入字体文件。(${e.osError?.message ?? e.message})',
      );
    } finally {
      client.close();
    }

    final data = await target.readAsBytes();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_font_path', target.path);
    await prefs.setString('user_font_name', name);
    displayName = name;
    await _register(data);
    _bump();
    return name;
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
    _bump();
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
    _bump();
  }
}
