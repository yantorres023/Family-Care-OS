import '../core/civil_date.dart';
import 'models.dart';

/// The occurrence after [from] for [rule]. [anchorDay] keeps monthly
/// items on their intended day (31st → last day of shorter months).
CivilDate stepOccurrence(CivilDate from, Recurrence rule, {int? anchorDay}) {
  return switch (rule) {
    Recurrence.none => from,
    Recurrence.daily => from.addDays(1),
    Recurrence.weekly => from.addDays(7),
    Recurrence.biweekly => from.addDays(14),
    Recurrence.monthly => from.addMonths(1, anchorDay: anchorDay),
  };
}

/// Due date for the occurrence that follows [current] once it is completed.
///
/// Steps forward from the current due date, then keeps stepping while the
/// result is before [today]. Completing a task that is three weeks overdue
/// therefore schedules the next one in the future instead of creating a pile
/// of overdue copies (DECISIONS D-010).
///
/// Returns null for non-recurring items or items without a due date.
CivilDate? nextDueDate(CareItem current, CivilDate today) {
  final due = current.dueDate;
  if (!current.isRecurring || due == null) return null;
  final anchor = current.anchorDay ?? due.day;
  var next = stepOccurrence(due, current.recurrence, anchorDay: anchor);
  // Bounded loop: daily recurrence years overdue is still < 10k iterations,
  // but guard against pathological input anyway.
  var guard = 0;
  while (next.isBefore(today) && guard < 100000) {
    next = stepOccurrence(next, current.recurrence, anchorDay: anchor);
    guard++;
  }
  return next;
}
