import 'package:flutter/material.dart';

/// 整段文字的阅读式预览：横排 / 竖排，不是格子字帖。
class TextPreview extends StatelessWidget {
  const TextPreview({
    super.key,
    required this.text,
    required this.fontFamily,
    this.fontSize = 44,
    this.vertical = false,
    this.charsPerColumn = 12,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final bool vertical;
  final int charsPerColumn;

  static const _noLineStart = '，。、；：？！）」』】》,.;:?!)]}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = text.trim();
    if (body.isEmpty) {
      return Text('输入文字后在这里预览', style: TextStyle(color: scheme.onSurfaceVariant));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: vertical
          ? _vertical(context, body)
          : _horizontal(context, body),
    );
  }

  Widget _horizontal(BuildContext context, String body) {
    return Text(
      body,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.75,
        letterSpacing: 2,
        color: const Color(0xFF1F2328),
      ),
    );
  }

  Widget _vertical(BuildContext context, String body) {
    // 竖排：从右往左，每列 charsPerColumn 字
    final chars = body.split('');
    final columns = <List<String>>[];
    var col = <String>[];
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (c == '\n') {
        columns.add(col);
        col = [];
        continue;
      }
      col.add(c);
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      // 避免标点跑到行首
      if (col.length >= charsPerColumn && !_noLineStart.contains(next)) {
        columns.add(col);
        col = [];
      }
    }
    if (col.isNotEmpty) columns.add(col);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in columns)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  for (final ch in c)
                    Text(
                      ch,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: fontSize,
                        height: 1.35,
                        color: const Color(0xFF1F2328),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
