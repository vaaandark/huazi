import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 浏览器直接下载，不依赖文件系统。
Future<String> savePdf(Uint8List bytes, String name) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return '已下载 $name';
}
