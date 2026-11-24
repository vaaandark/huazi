/// Web 版不提供 37MB 的篆隶包（体积不划算），相关入口显示为不可用。
class AncientPack {
  AncientPack._();

  static bool get supported => false;

  static bool get installed => false;

  static Future<bool> ensureOpen() async => false;

  static Future<void> download(void Function(double progress) onProgress) async {
    throw UnsupportedError('网页版暂不提供篆隶字形包');
  }

  static List<AncientGlyph> glyphs(int cp) => const [];

  static int count() => 0;
}

class AncientGlyph {
  final String script;
  final int seq;
  final String svg;
  const AncientGlyph({required this.script, required this.seq, required this.svg});

  String get scriptLabel => script == 'zhuan' ? '篆书' : '隶书';
}
