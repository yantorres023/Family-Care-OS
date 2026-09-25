import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/permissions.dart';
import '../../services/analytics.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import 'family_screen.dart';
import 'item_detail_screen.dart';
import 'item_editor_screen.dart';
import 'tasks_screen.dart';
import 'timeline_screen.dart';
import 'today_screen.dart';

/// Today · Tasks · Timeline · Family.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<String>? _opens;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _opens ??= StoreScope.read(context).notificationOpens.listen(_openItem);
  }

  @override
  void dispose() {
    _opens?.cancel();
    super.dispose();
  }

  void _openItem(String itemId) {
    if (!mounted) return;
    final store = StoreScope.read(context);
    if (itemId.isEmpty || store.itemById(itemId) == null) {
      setState(() => _index = 0);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ItemDetailScreen(itemId: itemId)),
    );
  }

  void _select(int i) {
    if (i == 2 && _index != 2) {
      StoreScope.read(context).analytics.track(AnalyticsEvent.timelineViewed);
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final pages = const [
      TodayScreen(),
      TasksScreen(),
      TimelineScreen(),
      FamilyScreen(),
    ];
    final showFab = _index <= 1 && store.can(Permission.createItem);
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const ItemEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          const NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: 'Family',
            tooltip: 'Family and settings',
          ),
        ],
      ),
    );
  }
}

/// App-bar button showing who is using the app; opens the switcher when
/// more than one person is in the circle (shared-device mode).
class ActorButton extends StatelessWidget {
  const ActorButton({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final actor = store.actor;
    if (actor == null || store.activeMembers.length < 2) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: 'Using Baton as ${actor.name}. Tap to switch.',
        onPressed: () => showActorSwitcher(context),
        icon: MemberAvatar(member: actor, radius: 16),
      ),
    );
  }
}

Future<void> showActorSwitcher(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final store = StoreScope.of(sheetContext);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                "Who's using Baton?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'On a shared family phone or tablet, pick your name so tasks '
                'and notes show who did them.',
              ),
            ),
            for (final m in store.activeMembers)
              ListTile(
                leading: MemberAvatar(member: m),
                title: Text(m.name),
                subtitle: Text(m.role.label),
                trailing: m.id == store.actor?.id
                    ? const Icon(Icons.check, semanticLabel: 'Current')
                    : null,
                onTap: () async {
                  await runAction(sheetContext, () => store.setActor(m.id));
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      );
    },
  );
}
