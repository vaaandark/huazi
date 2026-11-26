import 'package:package_info_plus/package_info_plus.dart';

/// 应用版本信息（来自 pubspec 的 version，运行时读取）。
class AppInfo {
  AppInfo._();

  static String version = '';
  static String build = '';

  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } catch (_) {
      version = '';
    }
  }

  static String get label {
    if (version.isEmpty) return '开发版';
    return build.isEmpty ? 'v$version' : 'v$version ($build)';
  }
}
