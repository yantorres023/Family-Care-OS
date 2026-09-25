import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/today.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final today = CivilDate(2026, 9, 25);

  test('buckets items by due date', () {
    final view = TodayView.build([
      item(id: 'over', due: today.addDays(-2)),
      item(id: 'today', due: today),
      item(id: 'soon', due: today.addDays(3)),
      item(id: 'edge', due: today.addDays(7)),
      item(id: 'far', due: today.addDays(8)),
      item(id: 'nodate'),
    ], today);
    expect(view.overdue.map((i) => i.id), ['over']);
    expect(view.today.map((i) => i.id), ['today']);
    expect(view.upcoming.map((i) => i.id), ['soon', 'edge']);
    expect(view.later.map((i) => i.id), ['far', 'nodate']);
  });

  test('deleted items are ignored; done items only count if done today', () {
    final view = TodayView.build([
      item(id: 'deleted', due: today, deletedAt: t0),
      item(
        id: 'doneToday',
        status: ItemStatus.done,
        completedAt: DateTime(2026, 9, 25, 8),
      ),
      item(
        id: 'doneYesterday',
        status: ItemStatus.done,
        completedAt: DateTime(2026, 9, 24, 23),
      ),
    ], today);
    expect(view.today, isEmpty);
    expect(view.doneToday.map((i) => i.id), ['doneToday']);
    expect(view.isEmpty, isFalse);
  });

  test('timed before all-day, by time, important first, then title', () {
    final view = TodayView.build([
      item(id: 'allDayB', title: 'b', due: today),
      item(id: 'allDayA', title: 'a', due: today),
      item(id: 'allDayImportant', title: 'z', due: today, important: true),
      item(id: 'late', due: today, minutes: 15 * 60),
      item(id: 'early', due: today, minutes: 9 * 60),
    ], today);
    expect(view.today.map((i) => i.id), [
      'early',
      'late',
      'allDayImportant',
      'allDayA',
      'allDayB',
    ]);
  });

  test('needsSomeone lists unassigned items within the window', () {
    final view = TodayView.build([
      item(id: 'a', due: today),
      item(id: 'b', due: today, assignee: 'm'),
      item(id: 'c', due: today.addDays(-1)),
      item(id: 'd', due: today.addDays(20)),
      item(id: 'e'),
    ], today);
    expect(view.needsSomeone.map((i) => i.id).toSet(), {'a', 'c'});
  });

  test('empty view', () {
    expect(TodayView.build([], today).isEmpty, isTrue);
  });
}
