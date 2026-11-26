import 'package:flutter/material.dart';

import 'data/app_info.dart';
import 'data/favorites.dart';
import 'data/settings.dart';
import 'data/repository.dart';
import 'data/user_font.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repository.init();
  await Favorites.init();
  await UserFont.restore();
  await AppInfo.load();
  await AppSettings.load();
  runApp(const HuaziApp());
}

class HuaziApp extends StatelessWidget {
  const HuaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: '字',
        debugShowCheckedModeBanner: false,
        theme: InkTheme.light(),
        darkTheme: InkTheme.dark(),
        themeMode: mode,
        home: const AppShell(),
      ),
    );
  }
}
