import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 保存 PDF：Android/iOS 调系统分享，桌面存到文档目录并返回路径。
Future<String> savePdf(Uint8List bytes, String name) async {
  final dir = await getApplicationDocumentsDirectory();
  final out = Directory(p.join(dir.path, 'huazi'));
  await out.create(recursive: true);
  final file = File(p.join(out.path, name));
  await file.writeAsBytes(bytes, flush: true);

  if (Platform.isAndroid || Platform.isIOS) {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], text: '字帖'),
    );
    return '已生成，可通过系统分享保存或打印';
  }
  return file.path;
}
