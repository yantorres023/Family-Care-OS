import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/handoff_suggestion.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/today.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers.dart';

void main() {
  Intl.defaultLocale = 'en_US';
  final today = CivilDate(2026, 9, 25);
  final members = {'a': member('a', 'Ana'), 'l': member('l', 'Luis')};

  test('summarises done, pending and next', () {
    final view = TodayView.build([
      item(
        title: 'Groceries',
        status: ItemStatus.done,
        completedAt: DateTime(2026, 9, 25, 10),
        completedBy: 'l',
      ),
      item(title: 'Pick up prescription', due: today),
      item(title: 'Call bank', due: today, assignee: 'a'),
      item(
        title: 'Dr. Patel',
        due: today.addDays(1),
        minutes: 630,
        assignee: 'a',
      ),
    ], today);
    final text = plain(suggestHandoff(view, members));
    expect(
      text,
      'Done today: Groceries (Luis).\n'
      'Still to do: Call bank (Ana), Pick up prescription (needs someone).\n'
      'Coming up: Tomorrow, 10:30 AM — Dr. Patel (Ana).',
    );
  });

  test('empty when nothing is happening', () {
    expect(suggestHandoff(TodayView.build([], today), members), '');
  });
}
