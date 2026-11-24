import 'dart:typed_data';

/// 网页版没有本地文件系统，导入字体暂不支持（可用于桌面/手机版）。
class UserFont {
  UserFont._();

  static const family = 'UserFont';
  static String? displayName;
  static ByteData? bytes;

  static bool get available => false;

  static Future<void> restore() async {}

  static Future<String?> import() async {
    throw UnsupportedError('网页版暂不支持导入本地字体，请使用桌面版或手机版');
  }

  static Future<void> clear() async {}
}
