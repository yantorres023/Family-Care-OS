import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/today.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import 'home_shell.dart';

enum TaskFilter { all, mine, needsSomeone, done }

/// Every open item (and recent history), filterable.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _filter = TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final actorId = store.actor?.id;
    final List<CareItem> items;
    switch (_filter) {
      case TaskFilter.all:
        items = store.liveItems.where((i) => i.isOpen).toList()
          ..sort(compareByDue);
      case TaskFilter.mine:
        items =
            store.liveItems
                .where((i) => i.isOpen && i.assigneeId == actorId)
                .toList()
              ..sort(compareByDue);
      case TaskFilter.needsSomeone:
        items =
            store.liveItems
                .where((i) => i.isOpen && i.assigneeId == null)
                .toList()
              ..sort(compareByDue);
      case TaskFilter.done:
        final cutoff = store.now.subtract(const Duration(days: 30));
        items =
            store.liveItems
                .where((i) => i.isDone && i.completedAt!.isAfter(cutoff))
                .toList()
              ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: const [ActorButton()],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in TaskFilter.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(switch (f) {
                        TaskFilter.all => 'All open',
                        TaskFilter.mine => 'Mine',
                        TaskFilter.needsSomeone => 'Needs someone',
                        TaskFilter.done => 'Done (30 days)',
                      }),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? ListView(
                    children: [
                      EmptyState(
                        icon: Icons.inbox_outlined,
                        title: switch (_filter) {
                          TaskFilter.all => 'No open tasks',
                          TaskFilter.mine => 'Nothing on your plate',
                          TaskFilter.needsSomeone => 'Everything has an owner',
                          TaskFilter.done => 'Nothing done yet',
                        },
                        message: 'Tap Add to create a task or appointment.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    itemBuilder: (_, i) => ItemTile(item: items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
