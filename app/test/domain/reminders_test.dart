import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/reminders.dart';
import 'package:family_care/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers.dart';

void main() {
  Intl.defaultLocale = 'en_US';
  const planner = ReminderPlanner();
  final now = DateTime(2026, 9, 25, 9);
  final today = CivilDate(2026, 9, 25);

  List<PlannedReminder> plan(
    List<CareItem> items, {
    ReminderSettings settings = const ReminderSettings(),
    DateTime? at,
  }) => planner.plan(
    items: items,
    meId: 'me',
    settings: settings,
    now: at ?? now,
    careRecipientName: 'Mom',
  );

  test('only open, dated items assigned to me', () {
    final r = plan([
      item(id: 'mine', due: today, minutes: 15 * 60, assignee: 'me'),
      item(id: 'theirs', due: today, minutes: 15 * 60, assignee: 'x'),
      item(id: 'open', due: today, minutes: 15 * 60),
      item(id: 'undated', assignee: 'me'),
      item(
        id: 'done',
        due: today,
        minutes: 15 * 60,
        assignee: 'me',
        status: ItemStatus.done,
      ),
      item(
        id: 'deleted',
        due: today,
        minutes: 15 * 60,
        assignee: 'me',
        deletedAt: now,
      ),
    ]);
    expect(r.map((x) => x.itemId), ['mine']);
  });

  test('timed items fire leadMinutes early; all-day at allDayMinutes', () {
    final r = plan([
      item(id: 'timed', due: today, minutes: 15 * 60, assignee: 'me'),
      item(id: 'allday', due: today.addDays(1), assignee: 'me'),
    ]);
    expect(r[0].date, today);
    expect(r[0].minutes, 14 * 60);
    expect(r[1].date, today.addDays(1));
    expect(r[1].minutes, 9 * 60);
  });

  test('lead time crossing midnight moves to the previous day', () {
    final r = plan([
      item(due: today.addDays(1), minutes: 30, assignee: 'me'),
    ], settings: const ReminderSettings(leadMinutes: 60));
    expect(r.single.date, today);
    expect(r.single.minutes, 23 * 60 + 30);
  });

  test('past reminders are skipped; beyond horizon skipped', () {
    final r = plan([
      item(id: 'past', due: today, minutes: 9 * 60 + 30, assignee: 'me'),
      item(id: 'far', due: today.addDays(31), assignee: 'me'),
      item(id: 'overdue', due: today.addDays(-1), assignee: 'me'),
    ]);
    expect(r, isEmpty);
  });

  test('disabled settings plan nothing', () {
    expect(
      plan([
        item(due: today.addDays(1), assignee: 'me'),
      ], settings: const ReminderSettings(enabled: false)),
      isEmpty,
    );
  });

  test('private lock screen hides titles and names by default', () {
    final r = plan([
      item(
        title: 'Pick up Mom\'s prescription',
        due: today,
        minutes: 15 * 60,
        assignee: 'me',
      ),
    ]);
    expect(r.single.title, 'Care reminder');
    expect(r.single.body, isNot(contains('prescription')));
    expect(r.single.body, isNot(contains('Mom')));
    expect(plain(r.single.body), contains('Today, 3:00 PM'));
  });

  test('non-private shows title and recipient', () {
    final r = plan([
      item(title: 'Groceries', due: today.addDays(1), assignee: 'me'),
    ], settings: const ReminderSettings(privateLockScreen: false));
    expect(r.single.title, 'Groceries');
    // Relative wording is computed for the day it fires.
    expect(r.single.body, 'Today · for Mom');
  });

  test('capped at maxReminders with unique ids', () {
    final items = [
      for (var i = 0; i < 100; i++)
        item(due: today.addDays(1 + i % 25), assignee: 'me'),
    ];
    final r = plan(items);
    expect(r.length, ReminderPlanner.maxReminders);
    expect(r.map((x) => x.id).toSet().length, r.length);
  });

  test('daily digest counts items for each day with items', () {
    final r = plan(
      [
        item(due: today.addDays(1), assignee: 'x'),
        item(due: today.addDays(1)),
        item(due: today.addDays(3), assignee: 'me'),
      ],
      settings: const ReminderSettings(
        dailyDigest: true,
        privateLockScreen: false,
      ),
    );
    final digests = r.where((x) => x.itemId == null).toList();
    expect(digests.map((d) => d.date), [today.addDays(1), today.addDays(3)]);
    expect(digests.first.body, contains('2 things planned for Mom today'));
    expect(digests.first.body, contains('1 needs someone'));
  });

  group('time zones', () {
    setUpAll(tzdata.initializeTimeZones);

    test('wall-clock time survives spring-forward (New York)', () {
      final ny = tz.getLocation('America/New_York');
      final r = PlannedReminder(
        id: 1,
        date: CivilDate(2026, 3, 8),
        minutes: 10 * 60,
        title: 't',
        body: 'b',
      );
      final z = zonedTimeFor(r, ny);
      expect(z.hour, 10);
      expect(z.timeZoneOffset, const Duration(hours: -4));
      final before = zonedTimeFor(
        PlannedReminder(
          id: 2,
          date: CivilDate(2026, 3, 7),
          minutes: 10 * 60,
          title: 't',
          body: 'b',
        ),
        ny,
      );
      expect(before.timeZoneOffset, const Duration(hours: -5));
      // 23 hours apart in absolute time, same wall clock.
      expect(z.difference(before), const Duration(hours: 23));
    });

    test('non-existent time in the DST gap resolves forward', () {
      final ny = tz.getLocation('America/New_York');
      final z = zonedTimeFor(
        PlannedReminder(
          id: 1,
          date: CivilDate(2026, 3, 8),
          minutes: 2 * 60 + 30,
          title: 't',
          body: 'b',
        ),
        ny,
      );
      expect(z.hour, 3);
      expect(z.minute, 30);
    });

    test('fall-back ambiguous hour still yields a valid instant (London)', () {
      final london = tz.getLocation('Europe/London');
      final z = zonedTimeFor(
        PlannedReminder(
          id: 1,
          date: CivilDate(2026, 10, 25),
          minutes: 60 + 30,
          title: 't',
          body: 'b',
        ),
        london,
      );
      expect(z.hour, 1);
      expect(z.minute, 30);
    });
  });

  test('settings round-trip and reject garbage', () {
    const s = ReminderSettings(
      enabled: false,
      leadMinutes: 15,
      privateLockScreen: false,
      dailyDigest: true,
      dailyDigestMinutes: 7 * 60,
    );
    final back = ReminderSettings.fromMap(s.toMap());
    expect(back.enabled, isFalse);
    expect(back.leadMinutes, 15);
    expect(back.privateLockScreen, isFalse);
    expect(back.dailyDigest, isTrue);
    expect(back.dailyDigestMinutes, 7 * 60);
    final bad = ReminderSettings.fromMap({
      'reminders.leadMinutes': '-5',
      'reminders.digestMinutes': 'abc',
    });
    expect(bad.leadMinutes, 60);
    expect(bad.dailyDigestMinutes, 8 * 60);
  });
}
