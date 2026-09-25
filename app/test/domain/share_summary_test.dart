import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/share_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers.dart';

void main() {
  Intl.defaultLocale = 'en_US';
  final today = CivilDate(2026, 9, 25);
  final circle = Circle(
    id: 'c',
    careRecipientName: 'Mom',
    createdAt: t0,
    updatedAt: t0,
  );
  final members = {
    'a': member('a', 'Ana', role: Role.owner),
    'l': member('l', 'Luis'),
  };

  test('daily update lists sections, owners and unassigned', () {
    final text = plain(
      const ShareSummary().dailyUpdate(
        circle: circle,
        today: today,
        items: [
          item(
            title: 'Dr. Patel',
            kind: ItemKind.appointment,
            due: today,
            minutes: 10 * 60 + 30,
            assignee: 'a',
            location: 'Main St Clinic',
          ),
          item(title: 'Pick up prescription', due: today),
          item(
            title: 'Pay electric bill',
            due: today.addDays(-2),
            assignee: 'l',
          ),
          item(title: 'Groceries', due: today.addDays(1), assignee: 'l'),
          item(
            title: 'Laundry',
            status: ItemStatus.done,
            completedAt: DateTime(2026, 9, 25, 8),
            completedBy: 'l',
          ),
        ],
        membersById: members,
        latestHandoff: HandoffNote(
          id: 'h',
          authorId: 'a',
          body: 'Mom slept well. Fridge is stocked.',
          createdAt: DateTime(2026, 9, 25, 8, 30),
        ),
      ),
    );
    expect(text, startsWith('Mom — update for Fri, Sep 25'));
    expect(
      text,
      contains('TODAY\n• 10:30 AM: Dr. Patel (Main St Clinic) — Ana'),
    );
    expect(text, contains('• Pick up prescription — needs someone'));
    expect(text, contains('OVERDUE\n• Wed, Sep 23: Pay electric bill'));
    expect(text, contains('Pay electric bill — Luis'));
    expect(text, contains('COMING UP\n• Tomorrow: Groceries — Luis'));
    expect(text, contains('DONE TODAY\n✓ Laundry — Luis'));
    expect(text, contains('NOTE FROM Ana'));
    expect(text, contains('Mom slept well.'));
    expect(text, contains('1 thing still needs someone'));
    expect(text, endsWith('— Sent with Baton'));
  });

  test('never includes item notes', () {
    final text = plain(
      const ShareSummary().dailyUpdate(
        circle: circle,
        today: today,
        items: [item(title: 'Visit', due: today, notes: 'SECRET-NOTE')],
        membersById: members,
      ),
    );
    expect(text, isNot(contains('SECRET-NOTE')));
  });

  test('empty state and footer toggle', () {
    final text = plain(
      const ShareSummary(includeFooter: false).dailyUpdate(
        circle: circle,
        today: today,
        items: const [],
        membersById: members,
      ),
    );
    expect(text, contains('Nothing scheduled for the next week.'));
    expect(text, isNot(contains('Baton')));
  });

  test('caps long sections', () {
    final text = plain(
      const ShareSummary().dailyUpdate(
        circle: circle,
        today: today,
        items: [for (var i = 0; i < 15; i++) item(title: 'T$i', due: today)],
        membersById: members,
      ),
    );
    expect(text, contains('…and 5 more'));
  });

  test('special characters and emoji pass through untouched', () {
    final text = plain(
      const ShareSummary().dailyUpdate(
        circle: circle.copyWith(careRecipientName: 'Mamá 👵'),
        today: today,
        items: [item(title: 'Café & "pan" <dulce>', due: today)],
        membersById: members,
      ),
    );
    expect(text, startsWith('Mamá 👵 — update'));
    expect(text, contains('Café & "pan" <dulce>'));
  });

  test('ask for help message', () {
    final text = plain(
      const ShareSummary().askForHelp(
        circle: circle,
        item: item(
          title: 'Drive to eye exam',
          kind: ItemKind.appointment,
          due: today.addDays(1),
          minutes: 14 * 60,
          location: 'Vision Center',
        ),
        today: today,
      ),
    );
    expect(text, contains('Can someone help with this for Mom?'));
    expect(text, contains('• Drive to eye exam'));
    expect(text, contains('Tomorrow, 2:00 PM'));
    expect(text, contains('Vision Center'));
    expect(text, contains('Reply here if you can take it.'));
  });
}
