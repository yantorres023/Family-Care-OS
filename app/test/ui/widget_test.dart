import 'package:family_care/app.dart';
import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/state/care_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../state/store_harness.dart';

Future<Harness> pumpApp(
  WidgetTester tester, {
  bool setUp = true,
  double textScale = 1.0,
  Size size = const Size(400, 800),
}) async {
  Intl.defaultLocale = 'en_US';
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  final h = Harness();
  if (setUp) {
    await h.ready();
  } else {
    await h.store.load();
  }
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: BatonApp(store: h.store),
    ),
  );
  await tester.pumpAndSettle();
  return h;
}

void main() {
  final today = CivilDate(2026, 9, 25);

  testWidgets('onboarding creates the circle and lands on Today', (
    tester,
  ) async {
    final h = await pumpApp(tester, setUp: false);
    expect(find.text('Baton'), findsOneWidget);
    expect(find.textContaining('not a medical'), findsOneWidget);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Continue is disabled until both names are filled.
    final cont = find.widgetWithText(FilledButton, 'Continue');
    expect(tester.widget<FilledButton>(cont).onPressed, isNull);
    await tester.enterText(find.widgetWithText(TextField, 'Their name'), 'Mom');
    await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Ana');
    await tester.pump();
    await tester.tap(cont);
    await tester.pumpAndSettle();

    expect(find.text('Who else helps Mom?'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Luis');
    await tester.tap(find.byTooltip('Add helper'));
    await tester.pump();
    expect(find.widgetWithText(InputChip, 'Luis'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What needs doing for Mom?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Weekly groceries'));
    await tester.tap(find.widgetWithText(FilterChip, 'Pay utility bills'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await tester.pumpAndSettle();

    expect(h.store.isSetUp, isTrue);
    expect(h.store.activeMembers.map((m) => m.name), ['Ana', 'Luis']);
    expect(find.text('For Mom'), findsOneWidget);
    // Starter tasks have no date; Today still shows them so the first
    // screen after setup is never empty.
    expect(find.text('No date yet (2)'), findsOneWidget);
    expect(find.text('Weekly groceries'), findsOneWidget);
    expect(find.text('Pay utility bills'), findsOneWidget);
  });

  testWidgets('Today shows sections, owners, and needs-someone banner', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final s = h.store;
    await s.createItem(
      ItemDraft(
        title: 'Dr. Patel',
        kind: ItemKind.appointment,
        dueDate: today,
        dueMinutes: 10 * 60 + 30,
        assigneeId: h.idOf('Luis'),
      ),
    );
    await s.createItem(
      ItemDraft(title: 'Pick up prescription', dueDate: today),
    );
    await s.createItem(
      ItemDraft(title: 'Pay bill', dueDate: today.addDays(-1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overdue (1)'), findsOneWidget);
    expect(find.text('Today (2)'), findsOneWidget);
    expect(find.text('2 things this week need someone'), findsOneWidget);
    expect(
      find.textContaining('Needs someone', findRichText: true),
      findsNWidgets(2),
    );
    expect(find.byTooltip('Luis is doing this'), findsOneWidget);
    // Overdue is conveyed with text, not only colour.
    expect(
      find.textContaining('Overdue', findRichText: true),
      findsNWidgets(2), // section header + row label
    );
  });

  testWidgets('checking an item completes it; Undo reopens it', (tester) async {
    final h = await pumpApp(tester);
    final item = await h.store.createItem(
      ItemDraft(title: 'Take out bins', dueDate: today),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Mark Take out bins done'));
    await tester.pumpAndSettle();
    expect(h.store.itemById(item.id)!.isDone, isTrue);
    expect(find.text('Done today (1)'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(h.store.itemById(item.id)!.isOpen, isTrue);
  });

  testWidgets('adding a task through the editor', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What needs doing?'),
      'Buy stamps',
    );
    await tester.tap(find.text('Tomorrow'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final created = h.store.liveItems.single;
    expect(created.title, 'Buy stamps');
    expect(created.dueDate, today.addDays(1));
    expect(find.text('Coming up (1)'), findsOneWidget);
  });

  testWidgets('duplicate warning appears before saving', (tester) async {
    final h = await pumpApp(tester);
    await h.store.createItem(ItemDraft(title: 'Buy stamps', dueDate: today));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'What needs doing?'),
      'buy stamps',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Already on the list?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(h.store.liveItems.length, 1);
  });

  testWidgets('handoff note drafted from today and shown on Today', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final i = await h.store.createItem(
      ItemDraft(title: 'Groceries', dueDate: today),
    );
    await h.store.complete(i.id);
    await h.store.createItem(ItemDraft(title: 'Prescription', dueDate: today));
    await tester.pumpAndSettle();
    await tester.tap(find.text('What should the next person know?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Start from today's list"));
    await tester.pump();
    expect(find.textContaining('Done today: Groceries (Ana).'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      h.store.latestHandoff!.body,
      contains('Prescription (needs someone)'),
    );
    expect(find.textContaining('Note from Ana'), findsOneWidget);
  });

  testWidgets('removing a helper from the Family tab releases their tasks', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    final item = await h.store.createItem(
      ItemDraft(title: 'Mow lawn', assigneeId: h.idOf('Luis')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from circle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 open task will be marked'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(h.store.itemById(item.id)!.assigneeId, isNull);
    expect(find.text('Luis'), findsNothing);
  });

  testWidgets('shared-device switcher changes who is acting', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byTooltip('Using Baton as Ana. Tap to switch.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sam'));
    await tester.pumpAndSettle();
    expect(h.store.actor!.name, 'Sam');
  });

  testWidgets('share update sends text through the share service', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await h.store.createItem(ItemDraft(title: 'Groceries', dueDate: today));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Share update with family'));
    await tester.pumpAndSettle();
    expect(h.share.shared.single, contains('Groceries — needs someone'));
  });

  testWidgets('timeline lists activity and notes filter', (tester) async {
    final h = await pumpApp(tester);
    await h.store.addHandoff('Fridge stocked');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Ana left a note'), findsOneWidget);
    expect(find.text('Fridge stocked'), findsWidgets);
    expect(find.textContaining('started coordinating'), findsOneWidget);
    await tester.tap(find.text('Notes only'));
    await tester.pumpAndSettle();
    expect(find.textContaining('started coordinating'), findsNothing);
  });

  testWidgets('settings: delete all data requires typing DELETE', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all data'), 200);
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    final deleteButton = find.widgetWithText(FilledButton, 'Delete');
    expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'DELETE');
    await tester.pump();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(h.store.isSetUp, isFalse);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('large text (200%) renders Today without overflow', (
    tester,
  ) async {
    final h = Harness();
    await h.ready();
    Intl.defaultLocale = 'en_US';
    await h.store.createItem(
      ItemDraft(
        title: 'A very long task title that goes on and on to check wrapping',
        kind: ItemKind.appointment,
        location: 'Some place with a long name, Building 2',
        dueDate: today,
        dueMinutes: 600,
        recurrence: Recurrence.weekly,
        assigneeId: h.idOf('Luis'),
        important: true,
      ),
    );
    await h.store.createItem(ItemDraft(title: 'Needs owner', dueDate: today));
    await h.store.addHandoff('x' * 300);
    tester.view.physicalSize =
        const Size(360, 740) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 740),
          textScaler: TextScaler.linear(2.0),
        ),
        child: BatonApp(store: h.store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final tab in ['Tasks', 'Timeline', 'Family']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('tap targets meet Android guideline on Today', (tester) async {
    final h = await pumpApp(tester);
    await h.store.createItem(ItemDraft(title: 'Groceries', dueDate: today));
    await tester.pumpAndSettle();
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
