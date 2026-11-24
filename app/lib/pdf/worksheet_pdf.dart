import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum GridStyle { tian, mi, plain }

extension GridStyleLabel on GridStyle {
  String get label => switch (this) {
        GridStyle.tian => '田字格',
        GridStyle.mi => '米字格',
        GridStyle.plain => '方格',
      };
}

class WorksheetOptions {
  final String text;
  final GridStyle grid;
  final double traceAlpha; // 0 = 空临，0.28 = 浅描，0.55 = 描红
  final String fontAsset;
  final int cols;
  final int rows;
  final ByteData? fontBytes; // 用户导入字体时直接给字节
  final bool vertical; // true = 竖排（每列一字，从右往左）

  const WorksheetOptions({
    required this.text,
    this.grid = GridStyle.tian,
    this.traceAlpha = 0.28,
    this.fontAsset = 'assets/fonts/wenkai.ttf',
    this.cols = 10,
    this.rows = 12,
    this.fontBytes,
    this.vertical = false,
  });

  String get traceLabel => traceAlpha == 0
      ? '空临'
      : traceAlpha < 0.4
          ? '浅描'
          : '描红';

  String get directionLabel => vertical ? '竖排' : '横排';
}

/// A4 字帖。
/// 横排：每行练一个字，首格实写，其余描红。
/// 竖排：每列练一个字，从右往左，首格（最上）实写。
class WorksheetPdf {
  static Future<Uint8List> build(WorksheetOptions opt) async {
    final data = opt.fontBytes ?? await rootBundle.load(opt.fontAsset);
    final font = pw.Font.ttf(data);
    final doc = pw.Document();

    final chars = opt.text.replaceAll(RegExp(r'\s'), '').split('');
    final perPage = opt.vertical ? opt.cols * opt.rows : opt.rows;
    final pageCount = (chars.length / perPage).ceil().clamp(1, 999);

    for (var p = 0; p < pageCount; p++) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 28),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '字帖 · ${opt.directionLabel} · ${opt.grid.label} · ${opt.traceLabel}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    ' huazi ',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Expanded(
                child: opt.vertical
                    ? _verticalGrid(opt, font, chars, p)
                    : _horizontalGrid(opt, font, chars, p),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${p + 1} / $pageCount',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  static pw.Widget _horizontalGrid(
    WorksheetOptions opt,
    pw.Font font,
    List<String> chars,
    int page,
  ) {
    return pw.Column(
      children: [
        for (var r = 0; r < opt.rows; r++)
          pw.Expanded(
            child: pw.Row(
              children: [
                for (var c = 0; c < opt.cols; c++)
                  pw.Expanded(
                    child: _cell(
                      opt,
                      font,
                      _charAt(chars, page * opt.rows + r),
                      c == 0,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static pw.Widget _verticalGrid(
    WorksheetOptions opt,
    pw.Font font,
    List<String> chars,
    int page,
  ) {
    // 从右往左：第一列放在最右
    return pw.Row(
      children: [
        for (var c = opt.cols - 1; c >= 0; c--)
          pw.Expanded(
            child: pw.Column(
              children: [
                for (var r = 0; r < opt.rows; r++)
                  pw.Expanded(
                    child: _cell(
                      opt,
                      font,
                      _charAt(chars, page * opt.cols + c),
                      r == 0,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _charAt(List<String> chars, int i) =>
      i >= 0 && i < chars.length ? chars[i] : '';

  static pw.Widget _cell(
    WorksheetOptions opt,
    pw.Font font,
    String ch,
    bool isDemo,
  ) {
    final color = isDemo
        ? PdfColors.black
        : opt.traceAlpha >= 0.4
            ? const PdfColor(0.78, 0.55, 0.50) // 描红：淡朱
            : const PdfColor(0.78, 0.78, 0.76); // 浅描：淡灰
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Stack(
        children: [
          if (opt.grid != GridStyle.plain)
            pw.Positioned.fill(
              child: pw.CustomPaint(
                painter: (canvas, size) => _drawGrid(canvas, size, opt.grid),
              ),
            ),
          if (ch.isNotEmpty && (isDemo || opt.traceAlpha > 0))
            pw.Center(
              child: pw.Text(
                ch,
                style: pw.TextStyle(font: font, fontSize: 36, color: color),
              ),
            ),
        ],
      ),
    );
  }

  static void _drawGrid(PdfGraphics canvas, PdfPoint size, GridStyle style) {
    canvas
      ..setColor(PdfColors.grey400)
      ..setLineWidth(0.35);

    void line(double x1, double y1, double x2, double y2) {
      canvas
        ..moveTo(x1, y1)
        ..lineTo(x2, y2)
        ..strokePath();
    }

    line(0, size.y / 2, size.x, size.y / 2);
    line(size.x / 2, 0, size.x / 2, size.y);
    if (style == GridStyle.mi) {
      line(0, 0, size.x, size.y);
      line(size.x, 0, 0, size.y);
    }
  }
}
