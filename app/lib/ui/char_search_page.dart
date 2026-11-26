import 'package:flutter/material.dart';

import 'dart:math';

import '../data/char_repo.dart';
import '../data/repository.dart';
import 'char_page.dart';

class CharSearchPage extends StatefulWidget {
  const CharSearchPage({super.key});

  @override
  State<CharSearchPage> createState() => _CharSearchPageState();
}

class _CharSearchPageState extends State<CharSearchPage> {
  final _controller = TextEditingController();
  final List<String> _recent = [];
  late final List<String> _quick = _loadQuick();
  String _today = '永';

  @override
  void initState() {
    super.initState();
    final days = DateTime.now().difference(DateTime(2020, 1, 1)).inDays;
    _today = _charAtOffset(days % 3755);
  }

  String _charAtOffset(int offset) {
    final rows = Repository.instance.select(
      'SELECT ch FROM char ORDER BY cp LIMIT 1 OFFSET ?',
      [offset],
    );
    return rows.isEmpty ? '永' : rows.first['ch'] as String;
  }

  List<String> _loadQuick() {
    final rows = Repository.instance.select(
      'SELECT ch FROM char WHERE strokes BETWEEN 1 AND 6 ORDER BY strokes, cp LIMIT 72',
    );
    return rows.map((r) => r['ch'] as String).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String ch) {
    if (ch.trim().isEmpty) return;
    final c = ch.trim().substring(0, 1);
    if (_recent.contains(c)) _recent.remove(c);
    _recent.insert(0, c);
    if (_recent.length > 12) _recent.removeLast();
    setState(() {});
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CharPage(char: c)),
    );
  }


  Widget _todayCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = CharRepository.info(_today);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _open(_today),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                _today,
                style: const TextStyle(fontFamily: 'WenKai', fontSize: 56, height: 1.2),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日一字',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 1,
                        )),
                const SizedBox(height: 4),
                Text(
                  [
                    if (info?.pinyin != null) info!.pinyin!,
                    if (info?.structureLabel != null) info!.structureLabel,
                    if (info?.strokes != null) '${info!.strokes} 画',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              final next = _charAtOffset(Random().nextInt(3755));
              setState(() => _today = next);
            },
            child: const Text('换一个'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('查一个字', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '看它的笔顺、结构，以及楷书与行楷两种写法。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        _todayCard(context),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, height: 1.4),
          decoration: InputDecoration(
            counterText: '',
            hintText: '输入一个字',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onSubmitted: _open,
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: () => _open(_controller.text),
          child: const Text('查看写法'),
        ),
        if (_recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('最近', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _recent)
                ActionChip(label: Text(c), onPressed: () => _open(c)),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text('常用 · 笔画少的字', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _quick)
              InkWell(
                onTap: () => _open(c),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(fontFamily: 'WenKai', fontSize: 24),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
