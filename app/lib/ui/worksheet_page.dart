import 'package:flutter/material.dart';

import '../pdf/worksheet_pdf.dart';
import '../util/save_pdf.dart';
import 'widgets/worksheet_preview.dart';

class WorksheetPage extends StatefulWidget {
  const WorksheetPage({super.key, this.initialText});

  final String? initialText;

  @override
  State<WorksheetPage> createState() => _WorksheetPageState();
}

class _WorksheetPageState extends State<WorksheetPage> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.initialText ?? '永和九年岁在癸丑',
    );
  }
  GridStyle _grid = GridStyle.tian;
  double _trace = 0.28;
  String _font = 'assets/fonts/wenkai.ttf';
  bool _busy = false;

  static const _common =
      '的一是在不了有和人这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转更单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严龙飞';

  static const _radicals = '氵扌木讠忄阝艹竹灬心亻彳辶宀广门刂卩阝忄';

  static const _strokes = '一丨丿丶乙亅';

  static const _qianziwen = '天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await WorksheetPdf.build(
        WorksheetOptions(
          text: _text.text,
          grid: _grid,
          traceAlpha: _trace,
          fontAsset: _font,
        ),
      );
      final now = DateTime.now();
      final name =
          '字帖-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.pdf';
      final result = await savePdf(bytes, name);
      if (!mounted) return;
      setState(() => _busy = false);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('字帖已生成'),
          content: SelectableText(result),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('好')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('生成失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Text('生成字帖', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'A4 排版，每行练一个字：首格实写，其余按描红档位排。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'WenKai', fontSize: 20, height: 1.6),
          decoration: InputDecoration(
            labelText: '练习内容',
            hintText: '输入要练的字或整段文字',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _preset('基本笔画', _strokes),
            _preset('常用偏旁', _radicals),
            _preset('常用 100 字', _common.substring(0, 60)),
            _preset('千字文', _qianziwen),
          ],
        ),
        const SizedBox(height: 20),
        _sectionTitle(context, '格子'),
        Wrap(
          spacing: 8,
          children: [
            for (final g in GridStyle.values)
              ChoiceChip(
                label: Text(g.label),
                selected: _grid == g,
                onSelected: (_) => setState(() => _grid = g),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(context, '描红档位'),
        Wrap(
          spacing: 8,
          children: [
            for (final (label, v) in [('空临', 0.0), ('浅描', 0.22), ('描红', 0.5)])
              ChoiceChip(
                label: Text(label),
                selected: _trace == v,
                onSelected: (_) => setState(() => _trace = v),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle(context, '字体'),
        Wrap(
          spacing: 8,
          children: [
            for (final (label, v) in [
              ('文楷 · 标准楷', 'assets/fonts/wenkai.ttf'),
              ('小赖 · 手写楷', 'assets/fonts/xiaolai.ttf'),
              ('志莽 · 行书', 'assets/fonts/xingshu.ttf'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _font == v,
                onSelected: (_) => setState(() => _font = v),
              ),
          ],
        ),
        const SizedBox(height: 24),
        WorksheetPreview(
          text: _text.text,
          grid: _grid,
          traceAlpha: _trace,
          fontFamily: _font.contains('xingshu')
              ? 'XingShu'
              : _font.contains('xiaolai')
                  ? 'Xiaolai'
                  : 'WenKai',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _generate,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_busy ? '生成中…' : '生成 A4 字帖 PDF'),
        ),
        const SizedBox(height: 10),
        Text(
          '生成后可直接下载/保存，用阅读器打开打印。',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _preset(String label, String text) => ActionChip(
        label: Text(label),
        onPressed: () => setState(() {
          _text.text = text;
          _text.selection = TextSelection.collapsed(offset: text.length);
        }),
      );
}
