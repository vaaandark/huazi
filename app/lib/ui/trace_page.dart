import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'char_page.dart';
import 'widgets/practice_grid.dart';

/// 数字临摹：在半透明范字上用手指/鼠标写，用来找结构感觉。
class TracePage extends StatefulWidget {
  const TracePage({super.key, required this.char});

  final String char;

  @override
  State<TracePage> createState() => _TracePageState();
}

class _TracePageState extends State<TracePage> {
  final List<List<Offset>> _strokes = [];
  bool _mi = false;
  String _family = 'WenKai';

  void _start(Offset p) => setState(() => _strokes.add([p]));

  void _extend(Offset p) => setState(() => _strokes.last.add(p));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('临摹 ${widget.char}'),
        actions: [
          IconButton(
            tooltip: '换字体',
            icon: const Icon(Icons.font_download_outlined),
            onPressed: () => setState(
              () => _family = _family == 'WenKai' ? 'XingShu' : 'WenKai',
            ),
          ),
          IconButton(
            tooltip: _mi ? '田字格' : '米字格',
            icon: Icon(_mi ? Icons.grid_4x4 : Icons.grid_3x3),
            onPressed: () => setState(() => _mi = !_mi),
          ),
          IconButton(
            tooltip: '清除',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_strokes.clear),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PracticeGrid(
                    mi: _mi,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        return GestureDetector(
                          onPanStart: (d) => _start(d.localPosition),
                          onPanUpdate: (d) => _extend(d.localPosition),
                          onPanEnd: (_) {},
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: Opacity(
                                  opacity: 0.18,
                                  child: Text(
                                    widget.char,
                                    style: TextStyle(
                                      fontFamily: _family,
                                      fontSize: c.maxWidth * 0.82,
                                      height: 1.15,
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                painter: _InkPainter(
                                  strokes: _strokes,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Text(
              '在格子里照着淡字写一遍。写歪了按右上角清除重来。',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter({required this.strokes, required this.color});
  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (var i = 1; i < s.length; i++) {
        path.lineTo(s[i].dx, s[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter old) => true;
}
