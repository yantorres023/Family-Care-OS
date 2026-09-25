import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../domain/permissions.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import 'item_editor_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final item = store.itemById(itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.delete_outline,
          title: 'This task was removed',
          message: 'It may have been deleted or completed on another visit.',
        ),
      );
    }
    final theme = Theme.of(context);
    final today = store.today;
    final actor = store.actor;
    final owner = store.memberById(item.assigneeId);
    final creator = store.memberById(item.createdById);
    final history = store.timeline.where((e) => e.itemId == item.id).toList();

    final canEdit = store.can(Permission.editItem, item: item);
    final canDelete = store.can(Permission.deleteItem, item: item);
    final canComplete = store.can(Permission.completeItem, item: item);
    final canTake =
        item.isOpen &&
        actor != null &&
        item.assigneeId != actor.id &&
        store.policy.canAssign(actor, item, actor.id);
    final canRelease =
        item.isOpen &&
        actor != null &&
        item.assigneeId == actor.id &&
        store.policy.canAssign(actor, item, null);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.kind.label),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => ItemEditorScreen(itemId: item.id),
                ),
              ),
            ),
          if (canDelete)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final go = await confirm(
                  context,
                  title: 'Delete "${item.title}"?',
                  message: item.isRecurring
                      ? 'This removes this occurrence. Future repeats won\'t '
                            'be created.'
                      : 'It will disappear from everyone\'s list. The '
                            'timeline keeps a record that it was removed.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
                if (!go || !context.mounted) return;
                final ok = await runAction(
                  context,
                  () => store.deleteItem(item.id),
                );
                if (ok && context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (item.important)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.priority_high,
                    color: theme.colorScheme.error,
                    semanticLabel: 'Important',
                  ),
                ),
              Expanded(
                child: Text(item.title, style: theme.textTheme.headlineSmall),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.isDone
                ? 'Done ${formatTimestamp(item.completedAt!, today)}'
                      ' by ${store.memberById(item.completedById)?.name ?? '—'}'
                : 'Open',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'When',
            value: formatDue(item.dueDate, item.dueMinutes, today),
          ),
          if (item.isRecurring)
            _InfoRow(
              icon: Icons.repeat,
              label: 'Repeats',
              value: item.recurrence.label,
            ),
          if (item.location.isNotEmpty)
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Where',
              value: item.location,
            ),
          _InfoRow(
            icon: Icons.person_outline,
            label: "Who's doing it",
            value: owner?.name ?? 'Needs someone',
            trailing: owner == null ? null : MemberAvatar(member: owner),
          ),
          if (item.notes.isNotEmpty)
            _InfoRow(icon: Icons.notes, label: 'Notes', value: item.notes),
          _InfoRow(
            icon: Icons.history_toggle_off,
            label: 'Added',
            value:
                '${formatTimestamp(item.createdAt, today)}'
                '${creator == null ? '' : ' by ${creator.name}'}',
          ),
          const SizedBox(height: 16),
          if (canComplete)
            FilledButton.icon(
              onPressed: () async {
                await toggleDone(context, item);
                if (context.mounted && item.isOpen) Navigator.of(context).pop();
              },
              icon: Icon(item.isDone ? Icons.undo : Icons.check),
              label: Text(item.isDone ? 'Reopen' : 'Mark done'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          const SizedBox(height: 8),
          if (canTake)
            OutlinedButton.icon(
              onPressed: () => runAction(
                context,
                () => store.assign(item.id, actor.id),
                success: "You're on it.",
              ),
              icon: const Icon(Icons.pan_tool_outlined),
              label: const Text("I'll do it"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          if (canRelease)
            OutlinedButton.icon(
              onPressed: () => runAction(
                context,
                () => store.assign(item.id, null),
                success: 'Marked as needing someone.',
              ),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text("I can't do this"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          if (item.isOpen && item.assigneeId == null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  runAction(context, () => store.askForHelp(item.id)),
              icon: const Icon(Icons.forum_outlined),
              label: const Text('Ask the family chat'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
          if (history.isNotEmpty) ...[
            const SectionHeader('History'),
            for (final e in history)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(e.summary),
                subtitle: Text(formatTimestamp(e.createdAt, today)),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label, style: Theme.of(context).textTheme.labelMedium),
        subtitle: SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: trailing,
      ),
    );
  }
}
