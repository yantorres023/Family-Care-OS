import '../core/civil_date.dart';
import 'models.dart';

/// How many days ahead "Coming up" covers.
const upcomingWindowDays = 7;

/// The Today screen, computed from raw items. Pure, so it is unit-tested.
class TodayView {
  TodayView._({
    required this.date,
    required this.overdue,
    required this.today,
    required this.upcoming,
    required this.later,
    required this.doneToday,
    required this.needsSomeone,
  });

  /// Buckets live (non-deleted) items relative to [date].
  factory TodayView.build(Iterable<CareItem> items, CivilDate date) {
    final overdue = <CareItem>[];
    final today = <CareItem>[];
    final upcoming = <CareItem>[];
    final later = <CareItem>[];
    final doneToday = <CareItem>[];
    final horizon = date.addDays(upcomingWindowDays);

    for (final item in items) {
      if (item.isDeleted) continue;
      if (item.isDone) {
        final at = item.completedAt;
        if (at != null && CivilDate.fromDateTime(at) == date) {
          doneToday.add(item);
        }
        continue;
      }
      final due = item.dueDate;
      if (due == null || due.isAfter(horizon)) {
        later.add(item);
      } else if (due.isBefore(date)) {
        overdue.add(item);
      } else if (due == date) {
        today.add(item);
      } else {
        upcoming.add(item);
      }
    }

    overdue.sort(compareByDue);
    today.sort(compareByDue);
    upcoming.sort(compareByDue);
    later.sort(compareByDue);
    doneToday.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    final needsSomeone = [
      ...overdue,
      ...today,
      ...upcoming,
    ].where((i) => i.assigneeId == null).toList();

    return TodayView._(
      date: date,
      overdue: overdue,
      today: today,
      upcoming: upcoming,
      later: later,
      doneToday: doneToday,
      needsSomeone: needsSomeone,
    );
  }

  /// The day this view was built for.
  final CivilDate date;
  final List<CareItem> overdue;
  final List<CareItem> today;
  final List<CareItem> upcoming;

  /// No date, or beyond the upcoming window.
  final List<CareItem> later;
  final List<CareItem> doneToday;

  /// Open items due within the window (or overdue) that nobody has taken.
  final List<CareItem> needsSomeone;

  bool get isEmpty =>
      overdue.isEmpty && today.isEmpty && upcoming.isEmpty && doneToday.isEmpty;
}

/// Sort: dated before undated; by date; timed before all-day on the same
/// date, by time; then important first; then by title for stability.
int compareByDue(CareItem a, CareItem b) {
  final ad = a.dueDate, bd = b.dueDate;
  if (ad == null && bd != null) return 1;
  if (ad != null && bd == null) return -1;
  if (ad != null && bd != null) {
    final c = ad.compareTo(bd);
    if (c != 0) return c;
  }
  final am = a.dueMinutes, bm = b.dueMinutes;
  if (am != null && bm == null) return -1;
  if (am == null && bm != null) return 1;
  if (am != null && bm != null && am != bm) return am.compareTo(bm);
  if (a.important != b.important) return a.important ? -1 : 1;
  final t = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return t != 0 ? t : a.id.compareTo(b.id);
}
