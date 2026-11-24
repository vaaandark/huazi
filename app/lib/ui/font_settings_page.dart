import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../data/user_font.dart';

class FontSettingsPage extends StatefulWidget {
  const FontSettingsPage({super.key});

  @override
  State<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends State<FontSettingsPage> {
  bool _busy = false;
  bool _downloading = false;
  double _progress = 0;
  late final TextEditingController _name =
      TextEditingController(text: UserFont.displayName ?? '');
  late final TextEditingController _url = TextEditingController();

  @override
  void initState() {
    super.initState();
    UserFont.downloadUrl().then((v) {
      if (mounted && v != null) _url.text = v;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _busy = true);
    try {
      final name = await UserFont.import();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _name.text = UserFont.displayName ?? '';
      });
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

  Future<void> _downloadRecommended() async {
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      final name = await UserFont.downloadRecommended((v) {
        if (mounted) setState(() => _progress = v);
      });
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _name.text = UserFont.displayName ?? '';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('已安装「$name」')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      final msg = e.toString().replaceFirst('SocketException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text('下载失败：$msg'),
          action: SnackBarAction(
            label: '改用本地文件',
            onPressed: _import,
          ),
        ),
      );
    }
  }

  Future<void> _saveName() async {
    await UserFont.rename(_name.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('名称已保存')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: UserFont.revision,
      builder: (context, _) {
        final name = UserFont.displayName;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('字体', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              kIsWeb
                  ? '选择你本机合法持有的 .ttf / .otf 字体，浏览器内即时加载，'
                      '不会上传到任何服务器；刷新后需重新选择。'
                  : '硬笔行书、硬笔楷书这类字帖字体，通常不允许随应用分发。'
                      '导入你自己合法持有的 .ttf / .otf 即可使用，文件只保存在本机。',
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
                    name == null ? '当前未导入字体' : '当前字体',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  if (name != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: '名称（可改）',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _saveName(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: _saveName,
                          child: const Text('保存'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                            _name.text = '';
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
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              Text('推荐字体包', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('瑞美加张清平硬笔行书',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('免费商用',
                              style: Theme.of(context).textTheme.labelSmall),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '张清平逐字书写 GB2312 全部 6763 字，中性笔行书。\n'
                      '原文件未经修改，点一下按需下载，不随安装包内置。',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.7,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '授权：作者声明免费商用，禁止修改再发布、禁止收费转售；'
                      '应用于软件/APP 属于原作者未明确的场景，请自行评估。',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.outline,
                            height: 1.6,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _url,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: '下载地址（可选，网络受限时填镜像）',
                        hintText: '留空使用默认 GitHub 地址',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: '保存地址',
                          icon: const Icon(Icons.save_outlined, size: 18),
                          onPressed: () async {
                            await UserFont.setDownloadUrl(_url.text);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('下载地址已保存')),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_downloading)
                      LinearProgressIndicator(
                        value: _progress == 0 ? null : _progress,
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: _downloadRecommended,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('下载并安装（10MB）'),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              kIsWeb
                  ? '提示：导入后，单字页、字帖和临摹都能选「我的字体」。'
                  : '提示：导入后，单字页、字帖和临摹都能选「我的字体」。'
                      '导出的 PDF 会嵌入该字体，仅用于你自己生成的字帖。',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.7,
                  ),
            ),
          ],
        );
      },
    );
  }
}
