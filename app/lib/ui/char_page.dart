import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/ancient_pack.dart';
import '../data/favorites.dart';
import '../data/user_font.dart';
import '../data/char_repo.dart';
import 'trace_page.dart';
import 'widgets/practice_grid.dart';

class CharPage extends StatefulWidget {
  const CharPage({super.key, required this.char});

  final String char;

  @override
  State<CharPage> createState() => _CharPageState();
}

class _CharPageState extends State<CharPage> {
  late final CharInfo? _info;
  late final List<String>? _strokes;

  int _step = 0;
  bool _packReady = false;
  bool _downloading = false;
  double _packProgress = 0;
  bool _mi = false;
  String _font = 'WenKai';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _info = CharRepository.info(widget.char);
    _strokes = CharRepository.strokes(widget.char);
    if (_strokes != null && _strokes.isNotEmpty) {
      _step = _strokes.length; // 默认显示完整字形
    }
    AncientPack.ensureOpen().then((v) {
      if (mounted) setState(() => _packReady = v);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    if (_strokes == null || _strokes.isEmpty) return;
    setState(() => _step = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 620), (t) {
      if (!mounted) return;
      setState(() => _step++);
      if (_step >= _strokes.length) {
        t.cancel();
        setState(() => _step = _strokes.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strokes = _strokes;
    final total = strokes?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.char),
        actions: [
          IconButton(
            tooltip: '临摹',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TracePage(char: widget.char)),
            ),
          ),
          IconButton(
            tooltip: Favorites.instance.contains(widget.char) ? '移出生字本' : '加入生字本',
            icon: Icon(
              Favorites.instance.contains(widget.char)
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
            onPressed: () async {
              final added = await Favorites.instance.toggle(widget.char);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(added ? '已加入生字本' : '已移出生字本')),
              );
            },
          ),
          IconButton(
            tooltip: _mi ? '切换田字格' : '切换米字格',
            icon: Icon(_mi ? Icons.grid_4x4 : Icons.grid_3x3),
            onPressed: () => setState(() => _mi = !_mi),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: AspectRatio(
                aspectRatio: 1,
                child: PracticeGrid(
                  mi: _mi,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: strokes == null || strokes.isEmpty
                        ? _fallback(context)
                        : SvgPicture.string(
                            _svg(strokes, _step, scheme),
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  onPressed: _step <= 0 ? null : () => setState(() => _step--),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '上一笔',
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: _play,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('笔顺'),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  onPressed: _step >= total ? null : () => setState(() => _step++),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '下一笔',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _step == 0
                    ? '共 $total 笔'
                    : '第 $_step / $total 笔',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _infoCard(context),
          const SizedBox(height: 20),
          _fontCompare(context),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) => Center(
        child: Text(
          widget.char,
          style: TextStyle(fontFamily: _font, fontSize: 120, height: 1.1),
        ),
      );

  String _svg(List<String> strokes, int step, ColorScheme scheme) {
    final done = step.clamp(0, strokes.length);
    final current = done < strokes.length ? done : -1;
    final b = StringBuffer(
      '<svg viewBox="0 -124 1024 1024" xmlns="http://www.w3.org/2000/svg">'
      '<g transform="translate(0,900) scale(1,-1)">',
    );
    for (var i = 0; i < strokes.length; i++) {
      final color = i < done
          ? '#1F2328'
          : i == current
              ? '#B2412E'
              : '#DED9CE';
      b.write('<path d="${strokes[i]}" fill="$color"/>');
    }
    b.write('</g></svg>');
    return b.toString();
  }

  Widget _infoCard(BuildContext context) {
    final info = _info;
    final scheme = Theme.of(context).colorScheme;
    if (info == null) {
      return Text(
        '这个字暂未收录笔顺数据。',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }
    final rows = <(String, String)>[
      if (info.pinyin != null) ('拼音', info.pinyin!),
      if (info.strokes != null) ('笔画', '${info.strokes} 画'),
      ('结构', info.structureLabel),
      if (info.partsLabel.isNotEmpty) ('部件', info.partsLabel),
      if (info.decomposition != null && info.decomposition != '？')
        ('分解', info.decomposition!),
      if (info.radical != null) ('部首', info.radical!),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      k,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (info.etymologyHint != null &&
              RegExp(r'[\u4e00-\u9fa5]').hasMatch(info.etymologyHint!))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                info.etymologyHint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.6,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ancientSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (!AncientPack.supported) {
      return Text(
        '篆隶字形包体积较大，网页版不提供；桌面版与手机版可按需下载。',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    }
    if (!_packReady) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('篆书 · 隶书', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              '篆隶字形包约 37MB，按需下载，装一次即可离线看。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 10),
            if (_downloading)
              LinearProgressIndicator(value: _packProgress == 0 ? null : _packProgress)
            else
              FilledButton.tonalIcon(
                onPressed: _downloadPack,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('下载篆隶字形包'),
              ),
          ],
        ),
      );
    }

    final glyphs = AncientPack.glyphs(widget.char.runes.first);
    if (glyphs.isEmpty) {
      return Text(
        '这个字暂无可用的篆隶字形。',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('篆书 · 隶书', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final g in glyphs)
              Container(
                width: 108,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 86,
                      child: g.svg.isEmpty
                          ? const SizedBox.shrink()
                          : SvgPicture.string(g.svg, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      g.scriptLabel,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadPack() async {
    setState(() {
      _downloading = true;
      _packProgress = 0;
    });
    try {
      await AncientPack.download((v) {
        if (mounted) setState(() => _packProgress = v);
      });
      if (mounted) {
        setState(() {
          _packReady = true;
          _downloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败：$e')),
        );
      }
    }
  }

  Widget _fontCompare(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('写法对比', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: UserFont.revision,
          builder: (context, _) => Row(
            children: [
              _fontTile(context, 'wenkai', '硬笔楷 · 文楷'),
              const SizedBox(width: 10),
              _fontTile(context, 'xingshu', '毛笔行书 · 志莽'),
              if (UserFont.available) ...[
                const SizedBox(width: 10),
                _fontTile(context, 'user', UserFont.displayName ?? '我的字体'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ancientSection(context),
      ],
    );
  }

  Widget _fontTile(BuildContext context, String family, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _font == family;
    final f = switch (family) {
      'wenkai' => 'WenKai',
      'xingshu' => 'XingShu',
      'user' => 'UserFont',
      _ => null,
    };
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _font = f ?? 'WenKai'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.char,
                style: TextStyle(fontFamily: f, fontSize: 64, height: 1.25),
              ),
              const SizedBox(height: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
