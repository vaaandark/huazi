import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'widgets/work_card.dart';
import 'work_detail_page.dart';

class WorksPage extends StatefulWidget {
  const WorksPage({super.key, this.initialWorkId, this.initialQuery = ''});

  final String? initialWorkId;
  final String initialQuery;

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage> {
  final _repo = Repository.instance;
  final _search = TextEditingController();

  WorkFilter _filter = const WorkFilter();
  List<Work> _works = const [];
  List<String> _dynasties = const [];
  List<String> _carriers = const [];
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _filter = WorkFilter(query: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) _search.text = widget.initialQuery;
    _dynasties = _repo.distinct('dynasty');
    _carriers = _repo.distinct('carrier');
    _selectedId = widget.initialWorkId;
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _works = _repo.works(filter: _filter);
      if (_selectedId != null && !_works.any((w) => w.id == _selectedId)) {
        _selectedId = _works.isEmpty ? null : _works.first.id;
      }
      _selectedId ??= _works.isEmpty ? null : _works.first.id;
    });
  }

  void _setScript(String? s) {
    _filter = s == null
        ? _filter.copyWith(clearScript: true)
        : _filter.copyWith(script: s);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 920;
        final list = _buildList(context, wide);
        if (!wide) return list;

        final selected = _selectedId == null ? null : _repo.work(_selectedId!);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 340, child: list),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? const Center(child: Text('选择左侧的碑帖'))
                  : WorkDetailPage(
                      key: ValueKey(selected.id),
                      work: selected,
                      embedded: true,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, bool wide) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索帖名、书家、内容',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _search.clear();
                        _filter = _filter.copyWith(query: '');
                        _reload();
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            onChanged: (v) {
              _filter = _filter.copyWith(query: v);
              _reload();
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _scriptChip(context, null, '全部'),
              for (final e in scriptLabels.entries)
                _scriptChip(context, e.key, e.value),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _filter.dynasty,
                  hint: const Text('朝代'),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部朝代')),
                    for (final d in _dynasties)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) {
                    _filter = v == null
                        ? _filter.copyWith(clearDynasty: true)
                        : _filter.copyWith(dynasty: v);
                    _reload();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _filter.carrier,
                  hint: const Text('载体'),
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部载体')),
                    for (final c in _carriers)
                      DropdownMenuItem(
                        value: c,
                        child: Text(carrierLabels[c] ?? c),
                      ),
                  ],
                  onChanged: (v) {
                    _filter = v == null
                        ? _filter.copyWith(clearCarrier: true)
                        : _filter.copyWith(carrier: v);
                    _reload();
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
            '${_works.length} 种碑帖',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _works.isEmpty
              ? const Center(child: Text('没有匹配的碑帖'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _works.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 84,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, i) {
                    final w = _works[i];
                    return WorkCard(
                      work: w,
                      selected: wide && w.id == _selectedId,
                      onTap: () {
                        if (wide) {
                          setState(() => _selectedId = w.id);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                body: SafeArea(child: WorkDetailPage(work: w)),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _scriptChip(BuildContext context, String? key, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _filter.script == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? scheme.secondaryContainer : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _setScript(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
