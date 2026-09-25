import '../core/formatting.dart';
import 'models.dart';
import 'today.dart';

/// Drafts a handoff note from today's state so writing one takes seconds:
///
///   Done today: Groceries (Luis), Laundry.
///   Still to do: Pick up prescription (needs someone).
///   Coming up: Tomorrow, 10:30 AM Dr. Patel (Ana).
///
/// The user edits it before saving; nothing is saved automatically.
String suggestHandoff(TodayView view, Map<String, Member> members) {
  String who(String? id) {
    final m = members[id];
    return m == null ? '' : ' (${m.name})';
  }

  const maxPerLine = 6;
  final lines = <String>[];
  if (view.doneToday.isNotEmpty) {
    final done = view.doneToday
        .take(maxPerLine)
        .map((i) => '${i.title}${who(i.completedById)}');
    lines.add('Done today: ${done.join(', ')}.');
  }
  final pending = [...view.overdue, ...view.today];
  if (pending.isNotEmpty) {
    final items = pending.take(maxPerLine).map((i) {
      final owner = members[i.assigneeId];
      return '${i.title} (${owner?.name ?? 'needs someone'})';
    });
    lines.add('Still to do: ${items.join(', ')}.');
  }
  if (view.upcoming.isNotEmpty) {
    final next = view.upcoming.first;
    final when = formatDue(next.dueDate, next.dueMinutes, view.date);
    lines.add('Coming up: $when — ${next.title}${who(next.assigneeId)}.');
  }
  return lines.join('\n');
}
