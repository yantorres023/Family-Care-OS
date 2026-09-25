import 'dart:io';

import 'package:family_care/data/in_memory_care_repository.dart';
import 'package:family_care/data/sqlite_care_repository.dart';
import 'package:family_care/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'repository_contract.dart';

void main() {
  sqfliteFfiInit();

  repositoryContract('InMemory', () async => InMemoryCareRepository());
  repositoryContract(
    'Sqlite',
    () => SqliteCareRepository.open(databaseFactoryFfi, inMemoryDatabasePath),
  );

  group('Sqlite migrations', () {
    test('v1 database with data upgrades to latest without loss', () async {
      final dir = await Directory.systemTemp.createTemp('baton_mig');
      final path = '${dir.path}/care.db';
      // Build a v1 database exactly as the first release would have.
      final v1 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) => migrations.first(db),
        ),
      );
      await v1.insert('items', {
        'id': 'old',
        'series_id': 'old',
        'kind': 'task',
        'title': 'From v1',
        'status': 'open',
        'due_date': '2026-09-25',
        'created_by_id': 'm',
        'created_at': 0,
        'updated_at': 0,
      });
      await v1.close();

      final repo = await SqliteCareRepository.open(databaseFactoryFfi, path);
      final snap = await repo.load();
      expect(snap.items.single.title, 'From v1');
      expect(snap.items.single.important, isFalse);
      // v2 table exists and works.
      await repo.appendEvent('task_created', '{}', DateTime(2026));
      expect(await repo.eventCounts(), {'task_created': 1});
      await repo.close();
      await dir.delete(recursive: true);
    });

    test('opening a newer schema with an older app fails loudly', () async {
      final dir = await Directory.systemTemp.createTemp('baton_down');
      final path = '${dir.path}/care.db';
      final future = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: schemaVersion + 1,
          onCreate: (db, _) async {},
        ),
      );
      await future.close();
      await expectLater(
        SqliteCareRepository.open(databaseFactoryFfi, path),
        throwsA(anything),
      );
      await dir.delete(recursive: true);
    });

    test('corrupt enum and date values degrade safely', () async {
      final dir = await Directory.systemTemp.createTemp('baton_corrupt');
      final path = '${dir.path}/care.db';
      var repo = await SqliteCareRepository.open(databaseFactoryFfi, path);
      await repo.close();
      final raw = await databaseFactoryFfi.openDatabase(path);
      await raw.insert('members', {
        'id': 'm',
        'name': 'Future',
        'role': 'superadmin',
        'color_index': 0,
        'created_at': 0,
        'updated_at': 0,
      });
      await raw.insert('items', {
        'id': 'x',
        'series_id': 'x',
        'kind': 'hologram',
        'title': 'Odd',
        'status': 'archived',
        'recurrence': 'hourly',
        'due_date': '2026-13-45',
        'due_minutes': 600,
        'created_by_id': 'm',
        'created_at': 0,
        'updated_at': 0,
      });
      await raw.close();
      repo = await SqliteCareRepository.open(databaseFactoryFfi, path);
      final snap = await repo.load();
      // Unknown role → least privilege.
      expect(snap.members.single.role, Role.viewer);
      final i = snap.items.single;
      expect(i.kind, ItemKind.task);
      expect(i.status, ItemStatus.open);
      expect(i.recurrence, Recurrence.none);
      expect(i.dueDate, isNull);
      expect(i.dueMinutes, isNull);
      await repo.close();
      await dir.delete(recursive: true);
    });

    test('analytics log is capped', () async {
      final repo = await SqliteCareRepository.open(
        databaseFactoryFfi,
        inMemoryDatabasePath,
      );
      for (var i = 0; i < SqliteCareRepository.maxAnalyticsRows + 25; i++) {
        await repo.appendEvent('e', '{}', DateTime(2026));
      }
      expect(
        (await repo.eventCounts())['e'],
        SqliteCareRepository.maxAnalyticsRows,
      );
      await repo.close();
    });
  });
}
