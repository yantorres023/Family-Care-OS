import 'package:family_care/core/civil_date.dart';
import 'package:family_care/data/in_memory_care_repository.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/reminders.dart';
import 'package:family_care/services/analytics.dart';
import 'package:family_care/state/care_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_harness.dart';

void main() {
  final today = CivilDate(2026, 9, 25);

  group('setup', () {
    test('creates circle, owner, helpers and starter tasks', () async {
      final h = Harness();
      final s = await h.ready(
        helpers: ['Luis', ' luis ', '', 'Sam', 'Ana'],
        tasks: ['Groceries', 'groceries ', 'Pay bills'],
      );
      expect(s.isSetUp, isTrue);
      expect(s.circle!.careRecipientName, 'Mom');
      expect(s.me!.name, 'Ana');
      expect(s.me!.role, Role.owner);
      // Duplicates and blanks (and a helper named like me) are dropped.
      expect(s.activeMembers.map((m) => m.name), ['Ana', 'Luis', 'Sam']);
      expect(s.liveItems.map((i) => i.title).toSet(), {
        'Groceries',
        'Pay bills',
      });
      expect(h.analytics.count(AnalyticsEvent.familyCreated), 1);
      expect(h.analytics.count(AnalyticsEvent.memberInvited), 2);
      expect(h.analytics.count(AnalyticsEvent.taskCreated), 2);
    });

    test('validates names', () async {
      final h = Harness();
      await h.store.load();
      expect(
        () => h.store.setUp(careRecipientName: ' ', myName: 'Ana'),
        throwsA(isA<ValidationFailed>()),
      );
      expect(
        () => h.store.setUp(careRecipientName: 'Mom', myName: 'x' * 61),
        throwsA(isA<ValidationFailed>()),
      );
      expect(h.store.isSetUp, isFalse);
    });

    test('state persists across reload', () async {
      final h = Harness();
      await h.ready(tasks: ['Groceries']);
      final again = Harness(repo: h.repo);
      await again.store.load();
      expect(again.store.isSetUp, isTrue);
      expect(again.store.liveItems.single.title, 'Groceries');
    });
  });

  group('items', () {
    test('create validates title, notes, recurrence and assignee', () async {
      final s = await Harness().ready();
      expect(
        () => s.createItem(const ItemDraft(title: '  ')),
        throwsA(isA<ValidationFailed>()),
      );
      expect(
        () => s.createItem(ItemDraft(title: 'x' * (Limits.titleMax + 1))),
        throwsA(isA<ValidationFailed>()),
      );
      expect(
        () => s.createItem(
          ItemDraft(title: 'n', notes: 'x' * (Limits.notesMax + 1)),
        ),
        throwsA(isA<ValidationFailed>()),
      );
      expect(
        () => s.createItem(
          const ItemDraft(title: 'r', recurrence: Recurrence.weekly),
        ),
        throwsA(isA<ValidationFailed>()),
      );
      expect(
        () => s.createItem(const ItemDraft(title: 'a', assigneeId: 'nobody')),
        throwsA(isA<ValidationFailed>()),
      );
      // Max-length values are accepted.
      final ok = await s.createItem(
        ItemDraft(title: 'x' * Limits.titleMax, notes: 'y' * Limits.notesMax),
      );
      expect(ok.notes.length, Limits.notesMax);
    });

    test('create with owner logs activity and tracks events', () async {
      final h = Harness();
      final s = await h.ready();
      final item = await s.createItem(
        ItemDraft(
          title: 'Dr. visit',
          kind: ItemKind.appointment,
          location: 'Clinic',
          dueDate: today,
          dueMinutes: 600,
          assigneeId: h.idOf('Luis'),
        ),
      );
      expect(item.location, 'Clinic');
      expect(s.timeline.first.summary, 'Ana added "Dr. visit" for Luis');
      expect(h.analytics.count(AnalyticsEvent.eventCreated), 1);
      expect(h.analytics.count(AnalyticsEvent.taskAssigned), 1);
    });

    test('location is dropped for plain tasks', () async {
      final s = await Harness().ready();
      final i = await s.createItem(
        const ItemDraft(title: 'Groceries', location: 'Shop'),
      );
      expect(i.location, '');
    });

    test('duplicate detection ignores case, spacing and done items', () async {
      final s = await Harness().ready();
      final a = await s.createItem(
        ItemDraft(title: 'Pick up  Prescription', dueDate: today),
      );
      expect(
        s.findDuplicate(
          ItemDraft(title: 'pick up prescription ', dueDate: today),
        ),
        isNotNull,
      );
      expect(
        s.findDuplicate(
          ItemDraft(title: 'pick up prescription', dueDate: today.addDays(1)),
        ),
        isNull,
      );
      expect(
        s.findDuplicate(
          ItemDraft(title: 'pick up prescription', dueDate: today),
          ignoreId: a.id,
        ),
        isNull,
      );
      await s.complete(a.id);
      expect(
        s.findDuplicate(
          ItemDraft(title: 'Pick up prescription', dueDate: today),
        ),
        isNull,
      );
    });

    test('complete then reopen', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(ItemDraft(title: 'Bins', dueDate: today));
      await s.complete(i.id);
      expect(s.itemById(i.id)!.isDone, isTrue);
      expect(s.itemById(i.id)!.completedById, s.me!.id);
      expect(s.todayView.doneToday.single.id, i.id);
      // Completing twice is a no-op.
      expect(await s.complete(i.id), isNull);
      await s.reopen(i.id);
      expect(s.itemById(i.id)!.isOpen, isTrue);
      expect(s.itemById(i.id)!.completedAt, isNull);
      expect(h.analytics.count(AnalyticsEvent.taskCompleted), 1);
    });

    test(
      'recurring completion spawns next occurrence with same owner',
      () async {
        final h = Harness();
        final s = await h.ready();
        final luis = h.idOf('Luis');
        final i = await s.createItem(
          ItemDraft(
            title: 'Groceries',
            dueDate: today,
            recurrence: Recurrence.weekly,
            assigneeId: luis,
          ),
        );
        final next = await s.complete(i.id);
        expect(next, isNotNull);
        expect(next!.dueDate, today.addDays(7));
        expect(next.assigneeId, luis);
        expect(next.seriesId, i.seriesId);
        expect(s.liveItems.where((x) => x.isOpen).single.id, next.id);
      },
    );

    test('overdue recurring completion does not pile up', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(
        ItemDraft(
          title: 'Water plants',
          dueDate: today.addDays(-30),
          recurrence: Recurrence.daily,
        ),
      );
      final next = await s.complete(i.id);
      expect(next!.dueDate, today);
      expect(s.liveItems.where((x) => x.isOpen).length, 1);
    });

    test(
      'reopening a recurring item removes the untouched next copy',
      () async {
        final s = await Harness().ready();
        final i = await s.createItem(
          ItemDraft(
            title: 'Pills pickup',
            dueDate: today,
            recurrence: Recurrence.monthly,
          ),
        );
        final next = await s.complete(i.id);
        await s.reopen(i.id);
        expect(s.itemById(next!.id), isNull);
        expect(s.liveItems.where((x) => x.isOpen).single.id, i.id);
        // Completing again spawns exactly one new occurrence.
        await s.complete(i.id);
        expect(s.liveItems.where((x) => x.isOpen).length, 1);
      },
    );

    test('monthly anchor day is kept when editing', () async {
      final s = await Harness(now: DateTime(2026, 1, 20, 9)).ready();
      final i = await s.createItem(
        ItemDraft(
          title: 'Rent',
          dueDate: CivilDate(2026, 1, 31),
          recurrence: Recurrence.monthly,
        ),
      );
      expect(i.anchorDay, 31);
      final feb = await s.complete(i.id);
      expect(feb!.dueDate, CivilDate(2026, 2, 28));
      expect(feb.anchorDay, 31);
    });

    test('update edits fields and logs assignment change', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(ItemDraft(title: 'Old', dueDate: today));
      await s.updateItem(
        i.id,
        ItemDraft(
          title: 'New',
          dueDate: today.addDays(1),
          dueMinutes: 540,
          assigneeId: h.idOf('Sam'),
          important: true,
        ),
      );
      final u = s.itemById(i.id)!;
      expect(u.title, 'New');
      expect(u.dueDate, today.addDays(1));
      expect(u.dueMinutes, 540);
      expect(u.important, isTrue);
      expect(
        s.timeline.map((e) => e.summary),
        contains('Ana asked Sam to do "New"'),
      );
      // Clearing the date also clears the time.
      await s.updateItem(i.id, const ItemDraft(title: 'New'));
      expect(s.itemById(i.id)!.dueDate, isNull);
      expect(s.itemById(i.id)!.dueMinutes, isNull);
    });

    test('delete is a soft delete and hidden everywhere', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(ItemDraft(title: 'X', dueDate: today));
      await s.deleteItem(i.id);
      expect(s.itemById(i.id), isNull);
      expect(s.todayView.today, isEmpty);
      final stored = (await h.repo.load()).items.single;
      expect(stored.deletedAt, isNotNull);
      expect(() => s.complete(i.id), throwsA(isA<CareException>()));
    });

    test('failed write leaves state unchanged', () async {
      final h = Harness();
      final s = await h.ready();
      h.repo.failNextApply = Exception('disk full');
      await expectLater(
        s.createItem(const ItemDraft(title: 'Lost')),
        throwsException,
      );
      expect(s.liveItems.where((i) => i.title == 'Lost'), isEmpty);
    });
  });

  group('members and permissions', () {
    test(
      'removing a member unassigns their open items, keeps history',
      () async {
        final h = Harness();
        final s = await h.ready();
        final luis = h.idOf('Luis');
        final a = await s.createItem(
          ItemDraft(title: 'A', dueDate: today, assigneeId: luis),
        );
        final b = await s.createItem(
          ItemDraft(title: 'B', dueDate: today, assigneeId: luis),
        );
        await s.complete(b.id);
        final released = await s.removeMember(luis);
        expect(released, 1);
        expect(s.itemById(a.id)!.assigneeId, isNull);
        // Completed history still points at Luis.
        expect(s.itemById(b.id)!.assigneeId, luis);
        expect(s.memberById(luis)!.isActive, isFalse);
        expect(s.activeMembers.map((m) => m.name), isNot(contains('Luis')));
        expect(s.todayView.needsSomeone.map((i) => i.id), contains(a.id));
        expect(() => s.assign(a.id, luis), throwsA(isA<ValidationFailed>()));
      },
    );

    test('recurring task of a removed member continues unassigned', () async {
      final h = Harness();
      final s = await h.ready();
      final luis = h.idOf('Luis');
      final i = await s.createItem(
        ItemDraft(
          title: 'Weekly call',
          dueDate: today,
          recurrence: Recurrence.weekly,
          assigneeId: luis,
        ),
      );
      await s.setActor(luis);
      // Mark done by Luis on the shared device, then Luis is removed.
      await s.complete(i.id);
      await s.setActor(s.me!.id);
      await s.removeMember(luis);
      final next = s.liveItems.firstWhere((x) => x.isOpen);
      expect(next.assigneeId, isNull);
    });

    test('owner cannot be removed; ownership can be transferred', () async {
      final h = Harness();
      final s = await h.ready();
      expect(() => s.removeMember(s.me!.id), throwsA(isA<PermissionDenied>()));
      await s.transferOwnership(h.idOf('Sam'));
      expect(s.memberById(h.idOf('Sam'))!.role, Role.owner);
      expect(s.me!.role, Role.coordinator);
      // Former owner (now coordinator) can no longer delete all data.
      expect(s.deleteAllData, throwsA(isA<PermissionDenied>()));
    });

    test('acting as a helper enforces helper permissions', () async {
      final h = Harness();
      final s = await h.ready();
      final luis = h.idOf('Luis');
      final sam = h.idOf('Sam');
      final samsTask = await s.createItem(
        ItemDraft(title: "Sam's", dueDate: today, assigneeId: sam),
      );
      final open = await s.createItem(ItemDraft(title: 'Open', dueDate: today));
      await s.setActor(luis);
      expect(s.actor!.name, 'Luis');
      expect(() => s.complete(samsTask.id), throwsA(isA<PermissionDenied>()));
      expect(() => s.assign(open.id, sam), throwsA(isA<PermissionDenied>()));
      expect(() => s.addMember('Zed'), throwsA(isA<PermissionDenied>()));
      expect(
        () => s.createItem(ItemDraft(title: 'for sam', assigneeId: sam)),
        throwsA(isA<PermissionDenied>()),
      );
      // Allowed: claim, complete own, write a handoff.
      await s.assign(open.id, luis);
      await s.complete(open.id);
      await s.addHandoff('Mom is fine');
      expect(s.latestHandoff!.authorId, luis);
      expect(s.timeline.first.summary, 'Luis left a note');
    });

    test('viewer cannot change anything', () async {
      final h = Harness();
      final s = await h.ready();
      final v = await s.addMember('Grandpa Joe', role: Role.viewer);
      await s.setActor(v.id);
      expect(
        () => s.createItem(const ItemDraft(title: 'x')),
        throwsA(isA<PermissionDenied>()),
      );
      expect(() => s.addHandoff('hi'), throwsA(isA<PermissionDenied>()));
    });

    test('removing the acting member falls back to me', () async {
      final h = Harness();
      final s = await h.ready();
      await s.setActor(h.idOf('Luis'));
      await s.setActor(s.me!.id);
      await s.setActor(h.idOf('Luis'));
      // Switch back to owner to remove Luis.
      await s.setActor(s.me!.id);
      await s.removeMember(h.idOf('Luis'));
      expect(s.actor!.id, s.me!.id);
    });

    test('add member validates duplicates and role limits', () async {
      final s = await Harness().ready();
      expect(() => s.addMember('luis'), throwsA(isA<ValidationFailed>()));
      expect(
        () => s.addMember('Kim', role: Role.owner),
        throwsA(isA<PermissionDenied>()),
      );
      final kim = await s.addMember('Kim', role: Role.coordinator);
      expect(kim.role, Role.coordinator);
      // Colour indices stay unique.
      expect(
        s.activeMembers.map((m) => m.colorIndex).toSet().length,
        s.activeMembers.length,
      );
    });

    test('change role and rename', () async {
      final h = Harness();
      final s = await h.ready();
      await s.changeRole(h.idOf('Luis'), Role.coordinator);
      expect(s.memberById(h.idOf('Luis'))!.role, Role.coordinator);
      await s.renameMember(h.idOf('Luis'), 'Luis M.');
      expect(s.memberById(h.idOf('Luis M.'))!.name, 'Luis M.');
      expect(
        () => s.changeRole(s.me!.id, Role.member),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('handoff', () {
    test('validates and records', () async {
      final h = Harness();
      final s = await h.ready();
      expect(() => s.addHandoff('   '), throwsA(isA<ValidationFailed>()));
      expect(
        () => s.addHandoff('x' * (Limits.handoffMax + 1)),
        throwsA(isA<ValidationFailed>()),
      );
      final n = await s.addHandoff(
        '  Mom already went to the appointment.\nPrescription pickup pending.  ',
      );
      expect(n.body, startsWith('Mom already'));
      expect(s.latestHandoff!.id, n.id);
      expect(s.handoffById(s.timeline.first.handoffId)!.id, n.id);
      expect(h.analytics.count(AnalyticsEvent.handoffAdded), 1);
    });
  });

  group('reminders', () {
    test(
      'rescheduled after changes; only mine; permission asked once',
      () async {
        final h = Harness();
        final s = await h.ready();
        expect(h.notifications.permissionRequests, 0);
        await s.createItem(
          ItemDraft(
            title: 'Mine',
            dueDate: today.addDays(1),
            assigneeId: s.me!.id,
          ),
        );
        expect(h.notifications.permissionRequests, 1);
        expect(h.notifications.scheduled.length, 1);
        await s.createItem(
          ItemDraft(
            title: 'Mine too',
            dueDate: today.addDays(2),
            assigneeId: s.me!.id,
          ),
        );
        expect(h.notifications.permissionRequests, 1);
        expect(h.notifications.scheduled.length, 2);
        await s.createItem(
          ItemDraft(
            title: 'Theirs',
            dueDate: today.addDays(1),
            assigneeId: h.idOf('Luis'),
          ),
        );
        expect(h.notifications.scheduled.length, 2);
      },
    );

    test('completing or reassigning cancels the reminder', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(
        ItemDraft(
          title: 'Mine',
          dueDate: today.addDays(1),
          assigneeId: s.me!.id,
        ),
      );
      expect(h.notifications.scheduled, hasLength(1));
      await s.assign(i.id, h.idOf('Luis'));
      expect(h.notifications.scheduled, isEmpty);
      await s.assign(i.id, s.me!.id);
      await s.complete(i.id);
      expect(h.notifications.scheduled, isEmpty);
    });

    test('app works when notification permission is denied', () async {
      final h = Harness();
      h.notifications.permissionGranted = false;
      final s = await h.ready();
      await s.createItem(
        ItemDraft(
          title: 'Mine',
          dueDate: today.addDays(1),
          assigneeId: s.me!.id,
        ),
      );
      expect(await s.notificationsEnabled(), isFalse);
      expect(s.liveItems.single.title, 'Mine');
    });

    test('disabling reminders clears schedule', () async {
      final h = Harness();
      final s = await h.ready();
      await s.createItem(
        ItemDraft(
          title: 'Mine',
          dueDate: today.addDays(1),
          assigneeId: s.me!.id,
        ),
      );
      await s.updateReminderSettings(const ReminderSettings(enabled: false));
      expect(h.notifications.scheduled, isEmpty);
      expect(s.reminderSettings.enabled, isFalse);
    });

    test('notification opens are tracked', () async {
      final h = Harness();
      await h.ready();
      h.notifications.simulateOpen('item');
      await Future<void>.delayed(Duration.zero);
      expect(h.analytics.count(AnalyticsEvent.notificationOpened), 1);
    });
  });

  group('sharing and data rights', () {
    test('share daily update and ask for help', () async {
      final h = Harness();
      final s = await h.ready();
      final i = await s.createItem(
        ItemDraft(title: 'Pick up prescription', dueDate: today),
      );
      expect(await s.shareDailyUpdate(), isTrue);
      expect(h.share.shared.single, contains('Pick up prescription'));
      await s.askForHelp(i.id);
      expect(h.share.shared.last, contains('Can someone help'));
      expect(h.analytics.count(AnalyticsEvent.updateShared), 1);
      expect(h.analytics.count(AnalyticsEvent.helpRequested), 1);
      h.share.nextResult = false;
      await s.shareDailyUpdate();
      expect(h.analytics.count(AnalyticsEvent.updateShared), 1);
    });

    test('handoff older than 48h is not shared', () async {
      final h = Harness();
      final s = await h.ready();
      await s.addHandoff('Old news');
      h.clock.advance(const Duration(hours: 49));
      expect(s.dailyUpdateText(), isNot(contains('Old news')));
    });

    test('export contains all data as JSON', () async {
      final h = Harness();
      final s = await h.ready(tasks: ['Groceries']);
      await s.addHandoff('note');
      expect(await s.exportData(), isTrue);
      final exported = h.share.shared.single;
      expect(exported, startsWith('baton-export-2026-09-25.json'));
      expect(exported, contains('"careRecipientName": "Mom"'));
      expect(exported, contains('"title": "Groceries"'));
      expect(exported, contains('"body": "note"'));
    });

    test('delete all data wipes storage and reminders', () async {
      final h = Harness();
      final s = await h.ready();
      await s.createItem(
        ItemDraft(
          title: 'Mine',
          dueDate: today.addDays(1),
          assigneeId: s.me!.id,
        ),
      );
      await s.deleteAllData();
      expect(s.isSetUp, isFalse);
      expect(h.notifications.scheduled, isEmpty);
      final snap = await h.repo.load();
      expect(snap.items, isEmpty);
      expect(snap.members, isEmpty);
    });
  });

  test('load error is surfaced, not thrown', () async {
    final repo = _BrokenRepo();
    final h = Harness(repo: repo);
    await h.store.load();
    expect(h.store.isLoaded, isTrue);
    expect(h.store.loadError, isNotNull);
  });
}

class _BrokenRepo extends InMemoryCareRepository {
  @override
  Future<Never> load() async => throw StateError('corrupt');
}
