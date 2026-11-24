import 'package:flutter/material.dart';

import '../../data/models.dart';

class ScriptBadge extends StatelessWidget {
  const ScriptBadge({super.key, required this.script, this.carrier});

  final String? script;
  final String? carrier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = scriptLabels[script] ?? '未知书体';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          height: 1.5,
          color: scheme.onSecondaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class WorkCard extends StatelessWidget {
  const WorkCard({
    super.key,
    required this.work,
    required this.onTap,
    this.selected = false,
  });

  final Work work;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.secondaryContainer.withValues(alpha: 0.5) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(work: work),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ScriptBadge(script: work.script),
                        const SizedBox(width: 6),
                        Text(
                          carrierLabels[work.carrier] ?? '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      work.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      work.byline.isEmpty ? '佚名' : work.byline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      work.summary ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.work});
  final Work work;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 84,
        child: Image.asset(
          'assets/thumbs/${work.id}-001.webp',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: scheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, color: scheme.outline),
          ),
        ),
      ),
    );
  }
}
