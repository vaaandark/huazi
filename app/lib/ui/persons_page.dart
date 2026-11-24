import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import 'works_page.dart';

class PersonsPage extends StatefulWidget {
  const PersonsPage({super.key});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  late final List<Person> _persons = Repository.instance.persons();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: _persons.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final p = _persons[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              p.name.substring(0, 1),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          title: Text(p.name),
          subtitle: Text(
            [p.dynasty, '${p.workCount} 种碑帖'].where((e) => e != null).join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(p.name)),
                  body: WorksPage(initialQuery: p.name),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
