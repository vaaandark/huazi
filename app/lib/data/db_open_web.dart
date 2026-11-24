import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:sqlite3/common.dart';

import 'package:sqlite3/wasm.dart';

/// Web 端：把内置 SQLite 文件放进自定义只读 VFS，直接由 sqlite3.wasm 打开。
/// 数据只读，不需要 IndexedDB 或 OPFS。
Future<CommonDatabase> openAppDatabase() async {
  final data = await rootBundle.load('assets/db/huazi.sqlite');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  final sqlite3 = await WasmSqlite3.loadFromUrl(
    Uri.base.resolve('sqlite3.wasm'),
  );
  sqlite3.registerVirtualFileSystem(_ReadOnlyDb(bytes), makeDefault: true);
  return sqlite3.open(_ReadOnlyDb.fileName, mode: OpenMode.readOnly);
}

final class _ReadOnlyDb extends BaseVirtualFileSystem {
  _ReadOnlyDb(this.bytes) : super(name: 'huazi-readonly');

  static const fileName = '/huazi.sqlite';
  final Uint8List bytes;

  @override
  XOpenResult xOpen(Sqlite3Filename path, int flags) {
    if (path.path != fileName) {
      throw const VfsException(14); // SQLITE_CANTOPEN
    }
    return (outFlags: 0, file: _ReadOnlyFile(bytes));
  }

  @override
  void xDelete(String path, int syncDir) {}

  @override
  int xAccess(String path, int flags) => path == fileName ? 1 : 0;

  @override
  String xFullPathName(String path) => path;

  @override
  void xSleep(Duration duration) {}
}

final class _ReadOnlyFile extends BaseVfsFile {
  _ReadOnlyFile(this._bytes);
  final Uint8List _bytes;

  @override
  int readInto(Uint8List buffer, int offset) {
    if (offset >= _bytes.length) return 0;
    final n = buffer.length < _bytes.length - offset
        ? buffer.length
        : _bytes.length - offset;
    buffer.setRange(0, n, _bytes, offset);
    return n;
  }

  @override
  int xFileSize() => _bytes.length;

  @override
  void xClose() {}

  @override
  void xSync(int flags) {}

  @override
  void xLock(int mode) {}

  @override
  void xUnlock(int mode) {}

  @override
  int xCheckReservedLock() => 0;

  @override
  void xWrite(Uint8List buffer, int fileOffset) =>
      throw const VfsException(8); // SQLITE_READONLY

  @override
  void xTruncate(int size) =>
      throw const VfsException(8); // SQLITE_READONLY
}
