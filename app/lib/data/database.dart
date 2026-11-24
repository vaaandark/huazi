import 'package:sqlite3/common.dart';

import 'db_open_native.dart'
    if (dart.library.js_interop) 'db_open_web.dart';

/// 打开内置只读数据库。平台差异在 db_open_*.dart 里。
class AppDatabase {
  AppDatabase._(this.db);
  final CommonDatabase db;

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance!;

  static Future<AppDatabase> open() async {
    if (_instance != null) return _instance!;
    final db = await openAppDatabase();
    _instance = AppDatabase._(db);
    return _instance!;
  }

  CommonDatabase get raw => db;
}
