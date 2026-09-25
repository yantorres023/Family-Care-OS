import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final today = CivilDate(2026, 9, 25);

  test('non-recurring or undated items have no next date', () {
    expect(nextDueDate(item(due: today), today), isNull);
    expect(nextDueDate(item(recurrence: Recurrence.weekly), today), isNull);
  });

  test('steps by rule from the due date', () {
    CivilDate? next(Recurrence r) =>
        nextDueDate(item(due: today, recurrence: r), today);
    expect(next(Recurrence.daily), CivilDate(2026, 9, 26));
    expect(next(Recurrence.weekly), CivilDate(2026, 10, 2));
    expect(next(Recurrence.biweekly), CivilDate(2026, 10, 9));
    expect(next(Recurrence.monthly), CivilDate(2026, 10, 25));
  });

  test('completing early keeps the schedule anchored to the due date', () {
    final due = today.addDays(3);
    expect(
      nextDueDate(item(due: due, recurrence: Recurrence.weekly), today),
      due.addDays(7),
    );
  });

  test('overdue recurring item rolls forward to today or later', () {
    // Weekly, due 3 weeks + 2 days ago.
    final due = today.addDays(-23);
    final next = nextDueDate(
      item(due: due, recurrence: Recurrence.weekly),
      today,
    )!;
    expect(next.isBefore(today), isFalse);
    expect(due.daysUntil(next) % 7, 0);
    expect(next, CivilDate(2026, 9, 30));
  });

  test('overdue daily item lands on today', () {
    final next = nextDueDate(
      item(due: today.addDays(-10), recurrence: Recurrence.daily),
      today,
    );
    expect(next, today);
  });

  test('monthly on the 31st keeps its anchor across short months', () {
    var current = item(
      due: CivilDate(2026, 1, 31),
      recurrence: Recurrence.monthly,
      anchorDay: 31,
    );
    final seen = <CivilDate>[];
    for (var k = 0; k < 4; k++) {
      final next = nextDueDate(current, CivilDate(2026, 1, 1))!;
      seen.add(next);
      current = current.copyWith(dueDate: next);
    }
    expect(seen, [
      CivilDate(2026, 2, 28),
      CivilDate(2026, 3, 31),
      CivilDate(2026, 4, 30),
      CivilDate(2026, 5, 31),
    ]);
  });

  test('monthly without explicit anchor uses due day', () {
    expect(
      nextDueDate(
        item(due: CivilDate(2026, 1, 15), recurrence: Recurrence.monthly),
        CivilDate(2026, 1, 1),
      ),
      CivilDate(2026, 2, 15),
    );
  });

  test('recurrence across DST boundary is date-exact', () {
    final next = nextDueDate(
      item(due: CivilDate(2026, 3, 7), recurrence: Recurrence.daily),
      CivilDate(2026, 3, 1),
    );
    expect(next, CivilDate(2026, 3, 8));
  });
}
