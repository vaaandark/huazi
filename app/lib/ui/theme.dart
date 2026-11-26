import 'package:flutter/material.dart';

/// 纸墨配色
class InkTheme {
  static const paper = Color(0xFFFAF7F0);
  static const paperDark = Color(0xFF1B1A17);
  static const ink = Color(0xFF1F2328);
  static const cinnabar = Color(0xFFB2412E);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cinnabar,
      brightness: Brightness.light,
      surface: paper,
    );
    return _base(scheme, paper);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: cinnabar,
      brightness: Brightness.dark,
    );
    return _base(scheme, paperDark);
  }

  static ThemeData _base(ColorScheme scheme, Color bg) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      // 内置文楷作为全局 UI 字体：网页版不必依赖下载 Noto 兜底
      fontFamily: 'WenKai',
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
      ),
    );
  }
}
