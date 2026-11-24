import 'package:flutter/material.dart';

import '../../pdf/worksheet_pdf.dart';
import 'practice_grid.dart';

/// 字帖实时预览：版式与 PDF 保持一致（每行一字，首格实写）。
class WorksheetPreview extends StatefulWidget {
  const WorksheetPreview({
    super.key,
    required this.text,
    required this.grid,
    required this.traceAlpha,
    required this.fontFamily,
    this.cols = 10,
    this.rows = 12,
    this.vertical = false,
  });

  final String text;
  final GridStyle grid;
  final double traceAlpha;
  final String fontFamily;
  final int cols;
  final int rows;
  final bool vertical;

  @override
  State<WorksheetPreview> createState() => _WorksheetPreviewState();
}

class _WorksheetPreviewState extends State<WorksheetPreview> {
  int _page = 0;

  List<String> get _chars =>
      widget.text.replaceAll(RegExp(r'\s'), '').split('');

  int get _pageCount {
    final perPage = widget.vertical
        ? widget.cols * widget.rows
        : widget.rows;
    return (_chars.length / perPage).ceil().clamp(1, 999);
  }

  @override
  void didUpdateWidget(covariant WorksheetPreview old) {
    super.didUpdateWidget(old);
    if (_page >= _pageCount) _page = _pageCount - 1;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('预览', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (_pageCount > 1) ...[
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _page <= 0 ? null : () => setState(() => _page--),
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              Text('${_page + 1} / $_pageCount',
                  style: Theme.of(context).textTheme.labelSmall),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed:
                    _page >= _pageCount - 1 ? null : () => setState(() => _page++),
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final sheetW = c.maxWidth.clamp(0.0, 520.0);
            final sheetH = sheetW * 297 / 210;
            final cellW = (sheetW - 20) / widget.cols;
            return Center(
              child: Container(
                width: sheetW,
                height: sheetH,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF6),
                  border: Border.all(color: scheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.vertical
                    ? Row(
                        children: [
                          for (var c = widget.cols - 1; c >= 0; c--)
                            Expanded(
                              child: Column(
                                children: [
                                  for (var r = 0; r < widget.rows; r++)
                                    Expanded(
                                      child: _cell(
                                        context,
                                        _charAtColumn(c),
                                        r == 0,
                                        cellW,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          for (var r = 0; r < widget.rows; r++)
                            Expanded(
                              child: Row(
                                children: [
                                  for (var col = 0; col < widget.cols; col++)
                                    Expanded(
                                      child: _cell(
                                        context,
                                        _charAt(r),
                                        col == 0,
                                        cellW,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          '这只是预览，导出 PDF 的版式一致。',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  String _charAt(int row) {
    final i = _page * widget.rows + row;
    final chars = _chars;
    return i < chars.length ? chars[i] : '';
  }

  String _charAtColumn(int col) {
    final perPage = widget.cols * widget.rows;
    final i = _page * perPage + col * widget.rows;
    final chars = _chars;
    return i < chars.length ? chars[i] : '';
  }

  Widget _cell(BuildContext context, String ch, bool demo, double cellW) {
    final traceColor = widget.traceAlpha >= 0.4
        ? const Color(0xFFC08A80)
        : const Color(0xFFC9C5BC);
    final content = Container(
      alignment: Alignment.center,
      decoration: widget.grid == GridStyle.plain
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFFDCD6CA), width: 0.6),
            )
          : null,
      child: ch.isEmpty || (!demo && widget.traceAlpha == 0)
          ? null
          : Text(
              ch,
              style: TextStyle(
                fontFamily: widget.fontFamily,
                fontSize: (cellW * 0.74).clamp(8.0, 40.0),
                height: 1.1,
                color: demo ? const Color(0xFF1F2328) : traceColor,
              ),
            ),
    );

    if (widget.grid == GridStyle.plain) return content;
    return PracticeGrid(
      mi: widget.grid == GridStyle.mi,
      color: const Color(0x33B2412E),
      child: content,
    );
  }
}
