import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../domain/permissions.dart';
import '../../domain/recurrence.dart';
import '../../state/store_scope.dart';
import '../screens/item_detail_screen.dart';
import 'common.dart';

/// One task/appointment row. Status is conveyed by icon + text, not colour.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, this.showDate = true});

  final CareItem item;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final today = store.today;
    final owner = store.memberById(item.assigneeId);
    final overdue =
        item.isOpen && item.dueDate != null && item.dueDate!.isBefore(today);
    final canToggle = store.can(Permission.completeItem, item: item);

    final details = <String>[
      if (showDate || item.dueMinutes != null)
        showDate
            ? formatDue(item.dueDate, item.dueMinutes, today)
            : formatTimeOfDay(item.dueMinutes!),
      if (item.kind == ItemKind.appointment && item.location.isNotEmpty)
        item.location,
    ];

    // One wrapping Text.rich so nothing overflows at large text sizes.
    WidgetSpan icon(IconData data, [Color? color]) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.only(right: 3),
        child: Icon(data, size: 16, color: color),
      ),
    );
    final spans = <InlineSpan>[];
    void gap() {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '  ·  '));
    }

    if (overdue) {
      spans
        ..add(icon(Icons.error_outline, theme.colorScheme.error))
        ..add(
          TextSpan(
            text: 'Overdue',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
    if (details.isNotEmpty) {
      gap();
      spans.add(TextSpan(text: details.join(' · ')));
    }
    if (item.isRecurring) {
      gap();
      spans
        ..add(icon(Icons.repeat))
        ..add(TextSpan(text: item.recurrence.shortLabel));
    }
    if (item.isOpen && owner == null) {
      gap();
      spans
        ..add(icon(Icons.person_search_outlined, theme.colorScheme.tertiary))
        ..add(
          TextSpan(
            text: 'Needs someone',
            style: TextStyle(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
    if (item.isDone && item.completedById != null) {
      gap();
      spans.add(
        TextSpan(
          text: 'Done by ${store.memberById(item.completedById)?.name ?? '—'}',
        ),
      );
    }
    final subtitle = spans.isEmpty
        ? null
        : Text.rich(TextSpan(children: spans));

    return MergeSemantics(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ItemDetailScreen(itemId: item.id),
          ),
        ),
        leading: Checkbox(
          value: item.isDone,
          semanticLabel: item.isDone
              ? 'Done: ${item.title}. Tap to reopen'
              : 'Mark ${item.title} done',
          onChanged: canToggle ? (_) => toggleDone(context, item) : null,
        ),
        title: Row(
          children: [
            if (item.kind == ItemKind.appointment)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.event_outlined,
                  size: 18,
                  semanticLabel: 'Appointment',
                ),
              ),
            if (item.important)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.priority_high,
                  size: 18,
                  color: theme.colorScheme.error,
                  semanticLabel: 'Important',
                ),
              ),
            Expanded(
              child: Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: item.isDone
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            ),
          ],
        ),
        subtitle: subtitle,
        trailing: item.isDone || owner == null
            ? null
            : Tooltip(
                message: '${owner.name} is doing this',
                child: MemberAvatar(member: owner),
              ),
      ),
    );
  }
}

/// Completes or reopens [item], offering Undo and telling the user when the
/// next occurrence of a repeating item is due.
Future<void> toggleDone(BuildContext context, CareItem item) async {
  final store = StoreScope.read(context);
  final messenger = ScaffoldMessenger.of(context);
  if (item.isDone) {
    await runAction(context, () => store.reopen(item.id));
    return;
  }
  CareItem? next;
  final ok = await runAction(context, () async {
    next = await store.complete(item.id);
  });
  if (!ok) return;
  final nextDate = next?.dueDate ?? nextDueDate(item, store.today);
  final message = next != null && nextDate != null
      ? 'Done. Next one: ${formatRelativeDate(nextDate, store.today)}.'
      : 'Marked "${item.title}" done.';
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => store.reopen(item.id),
        ),
      ),
    );
}
