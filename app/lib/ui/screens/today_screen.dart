import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatting.dart';
import '../../domain/permissions.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import 'handoff_editor_screen.dart';
import 'home_shell.dart';
import 'item_editor_screen.dart';

/// Answers: what needs to happen today, who is doing it, what changed.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  static const _maxUndated = 5;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final view = store.todayView;
    final name = store.circle!.careRecipientName;
    final dateLabel = DateFormat.MMMMEEEEd().format(store.now);
    final undated = view.undated;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For $name', overflow: TextOverflow.ellipsis),
            Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share update with family',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _share(context),
          ),
          const ActorButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const _HandoffCard(),
          if (view.needsSomeone.isNotEmpty)
            _NeedsSomeoneBanner(count: view.needsSomeone.length),
          if (view.isEmpty && undated.isEmpty)
            EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'Nothing planned this week',
              message:
                  'Add the next thing that needs doing for $name — a visit, '
                  'a bill, a pickup.',
              action: store.can(Permission.createItem)
                  ? FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          fullscreenDialog: true,
                          builder: (_) => const ItemEditorScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add something'),
                    )
                  : null,
            ),
          if (view.overdue.isNotEmpty) ...[
            SectionHeader(
              'Overdue',
              count: view.overdue.length,
              icon: Icons.error_outline,
            ),
            for (final i in view.overdue) ItemTile(item: i),
          ],
          if (view.today.isNotEmpty) ...[
            SectionHeader('Today', count: view.today.length),
            for (final i in view.today) ItemTile(item: i, showDate: false),
          ],
          if (view.upcoming.isNotEmpty) ...[
            SectionHeader('Coming up', count: view.upcoming.length),
            for (final i in view.upcoming) ItemTile(item: i),
          ],
          if (undated.isNotEmpty) ...[
            SectionHeader(
              'No date yet',
              count: undated.length,
              icon: Icons.event_busy_outlined,
            ),
            for (final i in undated.take(_maxUndated)) ItemTile(item: i),
            if (undated.length > _maxUndated)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '…and ${undated.length - _maxUndated} more on the Tasks tab.',
                ),
              ),
          ],
          if (view.doneToday.isNotEmpty) ...[
            SectionHeader(
              'Done today',
              count: view.doneToday.length,
              icon: Icons.check_circle_outline,
            ),
            for (final i in view.doneToday) ItemTile(item: i, showDate: false),
          ],
          if (!view.isEmpty || undated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Send update to family chat'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final store = StoreScope.read(context);
    await runAction(context, store.shareDailyUpdate);
  }
}

class _HandoffCard extends StatelessWidget {
  const _HandoffCard();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final note = store.latestHandoff;
    final canWrite = store.can(Permission.addHandoff);

    void write() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const HandoffEditorScreen(),
      ),
    );

    if (note == null) {
      if (!canWrite) return const SizedBox.shrink();
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: ListTile(
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: const Text('What should the next person know?'),
          subtitle: const Text('Leave a quick note after a visit or call.'),
          onTap: write,
        ),
      );
    }

    final author = store.memberById(note.authorId);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (author != null) MemberAvatar(member: author, radius: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note from ${author?.name ?? 'someone'} · '
                    '${formatTimestamp(note.createdAt, store.today)}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.body,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
            if (canWrite)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: write,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('New note'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NeedsSomeoneBanner extends StatelessWidget {
  const _NeedsSomeoneBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.person_search_outlined,
          color: scheme.onTertiaryContainer,
        ),
        title: Text(
          count == 1
              ? '1 thing this week needs someone'
              : '$count things this week need someone',
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        subtitle: Text(
          'Take one, or share the list to ask the family.',
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
      ),
    );
  }
}
