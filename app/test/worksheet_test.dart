import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:huazi/pdf/worksheet_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('生成 A4 字帖 PDF', () async {
    final bytes = await WorksheetPdf.build(
      const WorksheetOptions(
        text: '永和九年岁在癸丑',
        grid: GridStyle.tian,
        traceAlpha: 0.28,
      ),
    );
    expect(bytes.length, greaterThan(1000));
    final out = File('${Directory.systemTemp.path}/huazi_worksheet.pdf');
    out.writeAsBytesSync(bytes);
    expect(out.lengthSync(), greaterThan(1000));
  });
}
