import 'package:flutter/material.dart';

import '../data/favorites.dart';
import 'char_page.dart';
import 'worksheet_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<String> _chars = Favorites.instance.chars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_chars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '生字本还是空的。\n在单字页点右上角的书签，把常练的字收进来。',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.8),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text('${_chars.length} 个字',
                style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('练这些字')),
                    body: WorksheetPage(initialText: _chars.join()),
                  ),
                ),
              ),
              icon: const Icon(Icons.edit_note, size: 18),
              label: const Text('用这些字练字'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in _chars)
              Dismissible(
                key: ValueKey(c),
                direction: DismissDirection.up,
                onDismissed: (_) async {
                  await Favorites.instance.remove(c);
                  setState(() => _chars = Favorites.instance.chars);
                },
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CharPage(char: c)),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      c,
                      style: const TextStyle(fontFamily: 'WenKai', fontSize: 30),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '上滑可删除',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
