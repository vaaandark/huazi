import 'package:flutter/material.dart';

import 'char_page.dart';
import 'persons_page.dart';
import 'works_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book, label: '碑帖'),
    (icon: Icons.person_outline, selected: Icons.person, label: '书家'),
    (icon: Icons.brush_outlined, selected: Icons.brush, label: '字'),
    (icon: Icons.settings_outlined, selected: Icons.settings, label: '我的'),
  ];

  Widget _page(int i) => switch (i) {
        0 => const WorksPage(),
        1 => const PersonsPage(),
        2 => const _CharEntryPage(),
        _ => const _MinePage(),
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final titles = ['碑帖库', '书家', '查字', '我的'];

        final body = _page(_index);

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: _Logo(),
                  ),
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Scaffold(
                    appBar: AppBar(title: Text(titles[_index])),
                    body: body,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(titles[_index])),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selected),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: const Text(
        '字',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CharEntryPage extends StatelessWidget {
  const _CharEntryPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '查一个字',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'M2 会把碑帖里切出的真迹单字、篆隶字形和笔顺接到这里。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ch in ['永', '和', '九', '年', '之', '法', '书', '道'])
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CharPage(char: ch)),
                  ),
                  child: Text(ch, style: const TextStyle(fontSize: 20)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MinePage extends StatelessWidget {
  const _MinePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
          leading: Icon(Icons.bookmark_border),
          title: Text('生字本'),
          subtitle: Text('M4 加入'),
        ),
        ListTile(
          leading: Icon(Icons.edit_outlined),
          title: Text('数字临摹'),
          subtitle: Text('M4 加入'),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('数据来源'),
          subtitle: Text('书格 shuge.org · 字形库 hanzi-glyphs-svg · OFL 字体'),
        ),
        ListTile(
          leading: Icon(Icons.verified_outlined),
          title: Text('版本'),
          subtitle: Text('0.1.0 (M1)'),
        ),
      ],
    );
  }
}
