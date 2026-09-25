import 'package:family_care/core/civil_date.dart';
import 'package:family_care/data/care_repository.dart';
import 'package:family_care/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Behaviour every [CareRepository] must have. Run against each
/// implementation (and, later, the cloud-sync one).
void repositoryContract(String name, Future<CareRepository> Function() create) {
  group('$name contract', () {
    late CareRepository repo;
    setUp(() async => repo = await create());
    tearDown(() => repo.close());

    test('empty on first load', () async {
      final s = await repo.load();
      expect(s.circle, isNull);
      expect(s.members, isEmpty);
      expect(s.items, isEmpty);
    });

    test('round-trips every field', () async {
      final circle = Circle(
        id: 'c1',
        careRecipientName: 'Mamá 👵',
        createdAt: t0,
        updatedAt: t0,
      );
      final m = member(
        'm1',
        "Zoë O'Brien",
        role: Role.coordinator,
      ).copyWith(removedAt: t0.add(const Duration(days: 1)));
      final full = CareItem(
        id: 'i1',
        seriesId: 's1',
        kind: ItemKind.appointment,
        title: 'Café "visit" <b>; DROP TABLE items;--',
        notes: 'x' * Limits.notesMax,
        location: 'Clinic, 2nd floor',
        assigneeId: 'm1',
        dueDate: CivilDate(2026, 2, 28),
        dueMinutes: 630,
        recurrence: Recurrence.monthly,
        anchorDay: 31,
        important: true,
        status: ItemStatus.done,
        completedAt: t0.add(const Duration(hours: 2)),
        completedById: 'm1',
        createdById: 'm1',
        createdAt: t0,
        updatedAt: t0.add(const Duration(hours: 2)),
        deletedAt: t0.add(const Duration(hours: 3)),
      );
      final h = HandoffNote(
        id: 'h1',
        authorId: 'm1',
        body: 'Line 1\nLine 2 — ✓',
        createdAt: t0,
      );
      final e = ActivityEvent(
        id: 'e1',
        type: ActivityType.itemCompleted,
        actorId: 'm1',
        summary: 'done',
        createdAt: t0,
        itemId: 'i1',
        memberId: 'm1',
        handoffId: 'h1',
      );
      await repo.apply(
        ChangeSet()
          ..circle = circle
          ..members.add(m)
          ..items.add(full)
          ..handoffs.add(h)
          ..activity.add(e)
          ..settings['k'] = 'v',
      );
      final s = await repo.load();
      expect(s.circle!.careRecipientName, 'Mamá 👵');
      final lm = s.members.single;
      expect(lm.name, "Zoë O'Brien");
      expect(lm.role, Role.coordinator);
      expect(lm.removedAt, m.removedAt);
      final li = s.items.single;
      expect(li.title, full.title);
      expect(li.notes.length, Limits.notesMax);
      expect(li.location, full.location);
      expect(li.kind, ItemKind.appointment);
      expect(li.assigneeId, 'm1');
      expect(li.dueDate, CivilDate(2026, 2, 28));
      expect(li.dueMinutes, 630);
      expect(li.recurrence, Recurrence.monthly);
      expect(li.anchorDay, 31);
      expect(li.important, isTrue);
      expect(li.status, ItemStatus.done);
      expect(li.completedAt, full.completedAt);
      expect(li.completedById, 'm1');
      expect(li.deletedAt, full.deletedAt);
      expect(s.handoffs.single.body, h.body);
      final le = s.activity.single;
      expect(le.type, ActivityType.itemCompleted);
      expect(le.itemId, 'i1');
      expect(le.handoffId, 'h1');
      expect(s.settings, {'k': 'v'});
    });

    test('apply upserts by id', () async {
      await repo.apply(ChangeSet()..items.add(item(id: 'a', title: 'one')));
      await repo.apply(ChangeSet()..items.add(item(id: 'a', title: 'two')));
      final s = await repo.load();
      expect(s.items.single.title, 'two');
    });

    test('wipe removes everything', () async {
      await repo.apply(
        ChangeSet()
          ..members.add(member('m', 'M'))
          ..items.add(item())
          ..settings['a'] = 'b',
      );
      await repo.wipe();
      final s = await repo.load();
      expect(s.members, isEmpty);
      expect(s.items, isEmpty);
      expect(s.settings, isEmpty);
    });

    test('handoffs and activity load oldest first', () async {
      await repo.apply(
        ChangeSet()
          ..handoffs.addAll([
            HandoffNote(
              id: 'b',
              authorId: 'm',
              body: 'later',
              createdAt: t0.add(const Duration(minutes: 5)),
            ),
            HandoffNote(id: 'a', authorId: 'm', body: 'first', createdAt: t0),
          ]),
      );
      final s = await repo.load();
      expect(s.handoffs.map((h) => h.body), ['first', 'later']);
    });
  });
}
