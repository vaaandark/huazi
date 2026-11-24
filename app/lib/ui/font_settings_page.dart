import 'package:flutter/material.dart';

import '../data/user_font.dart';

class FontSettingsPage extends StatefulWidget {
  const FontSettingsPage({super.key});

  @override
  State<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends State<FontSettingsPage> {
  bool _busy = false;

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final name = await UserFont.import();
      if (!mounted) return;
      setState(() => _busy = false);
      if (name != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('已导入「$name」')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = UserFont.displayName;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('导入字体', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '硬笔行书、硬笔楷书这类字帖字体，通常不允许随应用分发。'
          '在「设置」里导入你自己合法持有的 .ttf / .otf 文件即可使用，'
          '文件只保存在本机。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.7,
              ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? '当前未导入字体' : '当前字体：$name',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (name != null) ...[
                const SizedBox(height: 12),
                Text(
                  '永和九年岁在癸丑',
                  style: const TextStyle(
                    fontFamily: UserFont.family,
                    fontSize: 30,
                    height: 1.6,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _import,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file, size: 18),
                    label: Text(name == null ? '选择字体文件' : '换一个'),
                  ),
                  if (name != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () async {
                        await UserFont.clear();
                        if (!mounted) return;
                        setState(() {});
                      },
                      child: const Text('移除'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '提示：导入后，单字页、字帖和临摹都能选「我的字体」。'
          '导出的 PDF 会嵌入该字体，仅用于你自己生成的字帖。',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.7,
              ),
        ),
      ],
    );
  }
}
