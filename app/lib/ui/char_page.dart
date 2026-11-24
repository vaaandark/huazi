import 'package:flutter/material.dart';

import 'widgets/practice_grid.dart';

class CharPage extends StatelessWidget {
  const CharPage({super.key, required this.char});

  final String char;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(char)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PracticeGrid(
                    child: Center(
                      child: Text(
                        char,
                        style: const TextStyle(fontSize: 120, height: 1.1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PracticeGrid(
                    mi: true,
                    child: Center(
                      child: Text(
                        char,
                        style: const TextStyle(fontSize: 120, height: 1.1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('各种写法', style: Theme.of(context).textTheme.titleMedium),
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
                Text(
                  '楷 / 行 / 草 由内置字体渲染，篆 / 隶来自字形库（M2 接入）。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.7),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前版本（M1）先完成碑帖库；字页在 M2 补齐真迹与多字形对比。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.7,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
