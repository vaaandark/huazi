import 'dart:convert';
import 'dart:io';

import 'repository.dart';

class CharInfo {
  final int cp;
  final String ch;
  final String? pinyin;
  final String? radical;
  final String? decomposition;
  final String? etymologyHint;
  final int? strokes;

  const CharInfo({
    required this.cp,
    required this.ch,
    this.pinyin,
    this.radical,
    this.decomposition,
    this.etymologyHint,
    this.strokes,
  });

  factory CharInfo.fromRow(Map<String, Object?> r) => CharInfo(
        cp: r['cp'] as int,
        ch: r['ch'] as String,
        pinyin: r['pinyin'] as String?,
        radical: r['radical'] as String?,
        decomposition: r['decomposition'] as String?,
        etymologyHint: r['etymology_hint'] as String?,
        strokes: r['strokes'] as int?,
      );

  String get structureLabel {
    final d = decomposition ?? '';
    if (d.startsWith('⿰')) return '左右结构';
    if (d.startsWith('⿱')) return '上下结构';
    if (d.startsWith('⿴') || d.startsWith('⿵') || d.startsWith('⿶')) return '包围结构';
    if (d.startsWith('⿶') || d.startsWith('⿷') || d.startsWith('⿸')) return '半包围结构';
    if (d.startsWith('⿲') || d.startsWith('⿳')) return '三合结构';
    if (d.startsWith('⿻')) return '框架结构';
    return '独体字';
  }

  /// 分解式转成可读的部件：⿰氵去 → 氵 + 去
  String get partsLabel {
    final d = decomposition;
    if (d == null || d.isEmpty || d == '？') return '';
    final body = d.startsWith('⿰') || d.startsWith('⿱') || d.startsWith('⿴') ||
            d.startsWith('⿵') || d.startsWith('⿶') || d.startsWith('⿷') ||
            d.startsWith('⿸') || d.startsWith('⿹') || d.startsWith('⿺')
        ? d.substring(1)
        : d;
    return body.split('').where((c) => c.trim().isNotEmpty).join(' + ');
  }
}

class CharRepository {
  static CharInfo? info(String ch) {
    if (ch.isEmpty) return null;
    final rows = Repository.instance
        .select('SELECT * FROM char WHERE cp = ?', [ch.runes.first]);
    return rows.isEmpty ? null : CharInfo.fromRow(rows.first);
  }

  /// 返回笔画数组（SVG path，坐标系 1024×1024，y 向上）
  static List<String>? strokes(String ch) {
    final rows = Repository.instance
        .select('SELECT data FROM stroke WHERE cp = ?', [ch.runes.first]);
    if (rows.isEmpty) return null;
    final blob = rows.first['data'] as List<int>;
    try {
      final text = utf8.decode(gzip.decode(blob));
      final map = jsonDecode(text) as Map<String, dynamic>;
      return (map['strokes'] as List).cast<String>();
    } catch (_) {
      return null;
    }
  }
}
