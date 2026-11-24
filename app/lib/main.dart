import 'package:flutter/material.dart';

import 'data/favorites.dart';
import 'data/repository.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repository.init();
  await Favorites.init();
  runApp(const HuaziApp());
}

class HuaziApp extends StatelessWidget {
  const HuaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '字',
      debugShowCheckedModeBanner: false,
      theme: InkTheme.light(),
      darkTheme: InkTheme.dark(),
      home: const AppShell(),
    );
  }
}
