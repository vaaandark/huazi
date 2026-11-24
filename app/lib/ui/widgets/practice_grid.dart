import 'package:flutter/material.dart';

/// 田字格 / 米字格，后续字帖生成复用。
class PracticeGrid extends StatelessWidget {
  const PracticeGrid({
    super.key,
    required this.child,
    this.mi = false,
    this.color = const Color(0x33B2412E),
  });

  final Widget child;
  final bool mi;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(mi: mi, color: color),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.mi, required this.color});

  final bool mi;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, p);

    final dash = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    // 十字
    _dashedLine(canvas, Offset(size.width / 2, 0), Offset(size.width / 2, size.height), dash);
    _dashedLine(canvas, Offset(0, size.height / 2), Offset(size.width, size.height / 2), dash);
    if (mi) {
      _dashedLine(canvas, Offset.zero, Offset(size.width, size.height), dash);
      _dashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), dash);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashLen = 4.0;
    const gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = (d + dashLen).clamp(0.0, total).toDouble();
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.mi != mi || old.color != color;
}
