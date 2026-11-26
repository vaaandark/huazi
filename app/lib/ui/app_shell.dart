import 'package:flutter/material.dart';

import 'char_search_page.dart';
import '../data/favorites.dart';
import 'favorites_page.dart';
import 'font_settings_page.dart';
import 'worksheet_page.dart';
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
    (icon: Icons.picture_as_pdf_outlined, selected: Icons.picture_as_pdf, label: '练字'),
    (icon: Icons.settings_outlined, selected: Icons.settings, label: '我的'),
  ];

  Widget _page(int i) => switch (i) {
        0 => const WorksPage(),
        1 => const PersonsPage(),
        2 => const CharSearchPage(),
        3 => const WorksheetPage(),
        _ => const _MinePage(),
      };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final titles = ['碑帖库', '书家', '查字', '练字', '我的'];

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

class _MinePage extends StatelessWidget {
  const _MinePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListenableBuilder(
          listenable: Favorites.revision,
          builder: (context, _) => ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('生字本'),
            subtitle: Text(
              Favorites.instance.chars.isEmpty
                  ? '收藏常练的字'
                  : '已收藏 ${Favorites.instance.chars.length} 个字',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('生字本')),
                  body: const FavoritesPage(),
                ),
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.font_download_outlined),
          title: const Text('导入字体'),
          subtitle: const Text('用自己合法持有的硬笔行书/楷书'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('导入字体')),
                body: const FontSettingsPage(),
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('数字临摹'),
          subtitle: const Text('单字页右上角的笔形图标进入'),
          onTap: null,
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('数据来源'),
          subtitle: Text('书格 shuge.org · hanzi-glyphs-svg · Make Me a Hanzi · OFL 字体'),
        ),
        const ListTile(
          leading: Icon(Icons.verified_outlined),
          title: Text('版本'),
          subtitle: Text('0.3.0 (M3 / M4)'),
        ),
      ],
    );
  }
}
