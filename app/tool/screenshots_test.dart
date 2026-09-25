// Renders store-screenshot drafts with real fonts.
// Run: flutter test tool/screenshots_test.dart
// Output: ../release/screenshots/*.png (sample data, clearly fictional).
import 'dart:io';

import 'package:family_care/app.dart';
import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';
import 'package:family_care/state/care_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../test/state/store_harness.dart';

const _cache = '/opt/flutter-sdk/flutter/bin/cache';

Future<void> _loadFonts() async {
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final f = File(
      '$_cache/dart-sdk/bin/resources/devtools/assets/packages/'
      'devtools_app_shared/fonts/Roboto/Roboto-$w.ttf',
    );
    if (f.existsSync()) {
      roboto.addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    }
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.view(
          File('$_cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
              .readAsBytesSync()
              .buffer,
        ),
      ),
    );
  await icons.load();
}

Future<Harness> _seed() async {
  final h = Harness(now: DateTime(2026, 9, 25, 16, 20));
  final s = h.store;
  await h.ready(helpers: ['Luis', 'Sam']);
  final today = CivilDate(2026, 9, 25);
  final luis = h.idOf('Luis');
  final sam = h.idOf('Sam');
  final me = s.me!.id;
  final groceries = await s.createItem(
    ItemDraft(
      title: 'Weekly groceries',
      dueDate: today,
      recurrence: Recurrence.weekly,
      assigneeId: luis,
    ),
  );
  await s.createItem(
    ItemDraft(
      title: 'Eye check-up',
      kind: ItemKind.appointment,
      dueDate: today.addDays(1),
      dueMinutes: 10 * 60 + 30,
      location: 'Riverside Vision Centre',
      assigneeId: me,
    ),
  );
  await s.createItem(
    ItemDraft(title: 'Pick up prescription', dueDate: today, important: true),
  );
  await s.createItem(
    ItemDraft(
      title: 'Pay electricity bill',
      dueDate: today.addDays(-1),
      recurrence: Recurrence.monthly,
      assigneeId: sam,
    ),
  );
  await s.createItem(
    ItemDraft(
      title: 'Evening check-in call',
      dueDate: today,
      dueMinutes: 19 * 60,
      recurrence: Recurrence.daily,
      assigneeId: sam,
    ),
  );
  await s.createItem(
    ItemDraft(title: 'Fix the garden gate', dueDate: today.addDays(4)),
  );
  await s.setActor(luis);
  await s.complete(groceries.id);
  await s.addHandoff(
    'Groceries delivered and put away. Mom was in good spirits. '
    'Prescription still needs picking up before Saturday.',
  );
  await s.setActor(me);
  return h;
}

void main() {
  const size = Size(390, 844);
  final out = Directory('../release/screenshots')..createSync(recursive: true);

  setUpAll(_loadFonts);

  Future<void> shot(
    WidgetTester tester,
    String name,
    Future<void> Function(WidgetTester) navigate,
  ) async {
    Intl.defaultLocale = 'en_US';
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final h = await tester.runAsync(_seed);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('root'),
        child: BatonApp(store: h!.store),
      ),
    );
    await tester.pumpAndSettle();
    await navigate(tester);
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('root')),
      matchesGoldenFile('${out.absolute.path}/$name.png'),
    );
  }

  setUp(() => autoUpdateGoldenFiles = true);

  testWidgets('01_today', (t) => shot(t, '01_today', (_) async {}));
  testWidgets(
    '02_tasks',
    (t) => shot(t, '02_tasks', (t) async => t.tap(find.text('Tasks'))),
  );
  testWidgets(
    '03_timeline',
    (t) => shot(t, '03_timeline', (t) async => t.tap(find.text('Timeline'))),
  );
  testWidgets(
    '04_family',
    (t) => shot(t, '04_family', (t) async => t.tap(find.text('Family'))),
  );
  testWidgets(
    '05_item',
    (t) => shot(
      t,
      '05_item',
      (t) async => t.tap(find.text('Pick up prescription')),
    ),
  );
}
