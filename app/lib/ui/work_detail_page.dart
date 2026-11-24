import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'char_page.dart';
import 'worksheet_page.dart';
import 'widgets/work_card.dart';

class WorkDetailPage extends StatefulWidget {
  const WorkDetailPage({
    super.key,
    required this.work,
    this.embedded = false,
  });

  final Work work;
  final bool embedded;

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  late List<WorkImage> _images;
  int _page = 0;
  final _pageController = PageController();
  final _zoom = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _images = Repository.instance.images(widget.work.id);
    _zoom.addListener(() {
      final z = _zoom.value.getMaxScaleOnAxis();
      final zoomed = z > 1.01;
      if (zoomed != _zoomed && mounted) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _page + delta;
    if (next < 0 || next >= _images.length) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.work;
    final body = CustomScrollView(
      slivers: [
        if (!widget.embedded)
          SliverAppBar(
            pinned: true,
            title: Text(w.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: '加入生字本',
                icon: const Icon(Icons.bookmark_border),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('收藏功能在 M4 加入')),
                ),
              ),
            ],
          ),
        if (_images.isNotEmpty)
          SliverToBoxAdapter(child: _gallery(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  ScriptBadge(script: w.script),
                  const SizedBox(width: 8),
                  Text(
                    carrierLabels[w.carrier] ?? '',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (w.rubbing != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      w.rubbing!,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                w.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                w.byline.isEmpty ? '佚名' : w.byline,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              if (w.summary != null) ...[
                const SizedBox(height: 16),
                Text(
                  w.summary!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.75),
                ),
              ],
              const SizedBox(height: 20),
              _metaTable(context, w),
              if (w.transcription != null && w.transcription!.trim().isNotEmpty)
                _transcription(context, w.transcription!),
              if (w.description != null && w.description!.trim().isNotEmpty)
                _description(context, w.description!),
              const SizedBox(height: 24),
              _rights(context, w),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return body;
    return Scaffold(body: body);
  }

  Widget _gallery(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              // 桌面端限制高度，保证标题和元数据不被挤出首屏
              final h = (c.maxWidth * 3 / 4).clamp(200.0, widget.embedded ? 380.0 : 460.0);
              return SizedBox(
                height: h,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
                    const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
                  },
                  child: Focus(
                    autofocus: true,
                    child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _images.length,
                      onPageChanged: (i) {
                        _zoom.value = Matrix4.identity();
                        setState(() {
                          _page = i;
                          _zoomed = false;
                        });
                      },
                      itemBuilder: (context, i) => _pageImage(context, _images[i]),
                    ),
                    if (_page > 0)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _navButton(Icons.chevron_left, () => _go(-1)),
                        ),
                      ),
                    if (_page < _images.length - 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _navButton(Icons.chevron_right, () => _go(1)),
                        ),
                      ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_page + 1} / ${_images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '左右拖动 / ← → 键翻页 · 轻点看高清原图（需联网）',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageImage(BuildContext context, WorkImage img) {
    final asset = img.assetPath;
    final child = asset == null
        ? const Center(child: Icon(Icons.broken_image_outlined))
        : Image.asset(asset, fit: BoxFit.contain);
    return GestureDetector(
      onTap: img.remote == null ? null : () => _openFull(context, img),
      child: InteractiveViewer(
        transformationController: _zoom,
        minScale: 1,
        maxScale: 3,
        // 未放大时把横向拖动让给 PageView，放大后才用于平移
        panEnabled: _zoomed,
        child: child,
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  void _openFull(BuildContext context, WorkImage img) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullImagePage(remote: img.remote!, caption: widget.work.title),
      ),
    );
  }

  Widget _metaTable(BuildContext context, Work w) {
    final rows = <(String, String)>[
      if (w.dynasty != null) ('朝代', w.dynasty!),
      if (w.lines != null) ('行数', '${w.lines} 行'),
      if (w.charsPerLine != null) ('行字', '满行 ${w.charsPerLine} 字'),
      if (w.layout != null) ('形制', w.layout!),
      if (w.holder != null) ('收藏', w.holder!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    width: 48,
                    child: Text(
                      k,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(v, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _transcription(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('释文', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(widget.work.title)),
                      body: WorksheetPage(
                        initialText: text.replaceAll(RegExp(r'^[\s\S]*?释文\s*'), ''),
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('练这一段'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              runSpacing: 6,
              children: [
                for (final ch in text.split(''))
                  _charCell(context, ch),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点任意字可查它的各种写法',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  static final _punct = RegExp(r'[\s，。、；：？！「」『』（）《》〈〉…—\-·,.!?;:()\[\]“”‘’]');

  Widget _charCell(BuildContext context, String ch) {
    if (ch.trim().isEmpty) return const SizedBox(width: 6);
    final isPunct = _punct.hasMatch(ch);
    final style = TextStyle(
      fontSize: 20,
      height: 1.45,
      color: isPunct
          ? Theme.of(context).colorScheme.outline
          : Theme.of(context).colorScheme.onSurface,
    );
    if (isPunct) return Text(ch, style: style);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CharPage(char: ch)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Text(ch, style: style),
      ),
    );
  }

  Widget _description(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text('详细著录', style: Theme.of(context).textTheme.titleSmall),
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _rights(BuildContext context, Work w) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('来源与许可', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            [
              '图源：书格 shuge.org',
              if (w.rights != null) '协议：${w.rights}',
              '原作多为公有领域，扫描件版权归原机构',
            ].join('\n'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _FullImagePage extends StatelessWidget {
  const _FullImagePage({required this.remote, required this.caption});

  final String remote;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(caption, style: const TextStyle(fontSize: 14)),
      ),
      body: InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: Image.network(
            remote,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final total = progress.expectedTotalBytes;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      value: total == null
                          ? null
                          : progress.cumulativeBytesLoaded / total,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '正在载入高清原图…',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '无法载入原图，请检查网络',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
