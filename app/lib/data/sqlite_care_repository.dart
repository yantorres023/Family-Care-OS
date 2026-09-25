import 'package:sqflite_common/sqlite_api.dart';

import '../core/civil_date.dart';
import '../domain/models.dart';
import '../services/analytics.dart';
import 'care_repository.dart';

/// Ordered schema migrations. Index i upgrades from version i+1 to i+2.
/// Never edit a shipped migration; append a new one.
final List<Future<void> Function(DatabaseExecutor db)> migrations = [
  // v1: initial schema.
  (db) async {
    await db.execute('''
      CREATE TABLE circles (
        id TEXT PRIMARY KEY,
        care_recipient_name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE members (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        color_index INTEGER NOT NULL,
        is_device_owner INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        removed_at INTEGER
      )''');
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        series_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        assignee_id TEXT,
        due_date TEXT,
        due_minutes INTEGER,
        recurrence TEXT NOT NULL DEFAULT 'none',
        anchor_day INTEGER,
        status TEXT NOT NULL DEFAULT 'open',
        completed_at INTEGER,
        completed_by_id TEXT,
        created_by_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )''');
    await db.execute('CREATE INDEX items_due ON items (due_date)');
    await db.execute('''
      CREATE TABLE handoffs (
        id TEXT PRIMARY KEY,
        author_id TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE activity (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        actor_id TEXT NOT NULL,
        summary TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        item_id TEXT,
        member_id TEXT,
        handoff_id TEXT
      )''');
    await db.execute('CREATE INDEX activity_created ON activity (created_at)');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
  },
  // v2: "important" flag on items; on-device analytics log.
  (db) async {
    await db.execute(
      'ALTER TABLE items ADD COLUMN important INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute('''
      CREATE TABLE analytics_events (
        seq INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        props TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )''');
  },
];

int get schemaVersion => migrations.length;

/// Local, on-device storage (DECISIONS D-005, D-008).
class SqliteCareRepository implements CareRepository, AnalyticsStore {
  SqliteCareRepository._(this._db);

  final Database _db;

  static const maxAnalyticsRows = 1000;

  /// Opens (creating or migrating) the database at [path].
  static Future<SqliteCareRepository> open(
    DatabaseFactory factory,
    String path,
  ) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          for (final m in migrations.take(version)) {
            await m(db);
          }
        },
        onUpgrade: (db, from, to) async {
          for (var v = from; v < to; v++) {
            await migrations[v](db);
          }
        },
        onDowngrade: (db, from, to) async {
          // A downgrade means an older app build opened newer data. Refuse
          // rather than silently corrupting it.
          throw StateError(
            'Database schema v$from is newer than this app (v$to).',
          );
        },
      ),
    );
    return SqliteCareRepository._(db);
  }

  @override
  Future<CareSnapshot> load() async {
    final circles = await _db.query('circles', limit: 1);
    final members = await _db.query('members', orderBy: 'created_at');
    final items = await _db.query('items');
    final handoffs = await _db.query('handoffs', orderBy: 'created_at');
    final activity = await _db.query('activity', orderBy: 'created_at');
    final settings = await _db.query('settings');
    return CareSnapshot(
      circle: circles.isEmpty ? null : _circleFrom(circles.first),
      members: members.map(_memberFrom).toList(),
      items: items.map(_itemFrom).toList(),
      handoffs: handoffs.map(_handoffFrom).toList(),
      activity: activity.map(_activityFrom).toList(),
      settings: {
        for (final row in settings)
          row['key']! as String: row['value']! as String,
      },
    );
  }

  @override
  Future<void> apply(ChangeSet changes) async {
    if (changes.isEmpty) return;
    await _db.transaction((txn) async {
      final batch = txn.batch();
      const replace = ConflictAlgorithm.replace;
      if (changes.circle != null) {
        batch.insert(
          'circles',
          _circleTo(changes.circle!),
          conflictAlgorithm: replace,
        );
      }
      for (final m in changes.members) {
        batch.insert('members', _memberTo(m), conflictAlgorithm: replace);
      }
      for (final i in changes.items) {
        batch.insert('items', _itemTo(i), conflictAlgorithm: replace);
      }
      for (final h in changes.handoffs) {
        batch.insert('handoffs', _handoffTo(h), conflictAlgorithm: replace);
      }
      for (final a in changes.activity) {
        batch.insert('activity', _activityTo(a), conflictAlgorithm: replace);
      }
      changes.settings.forEach((key, value) {
        batch.insert('settings', {
          'key': key,
          'value': value,
        }, conflictAlgorithm: replace);
      });
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> wipe() async {
    await _db.transaction((txn) async {
      for (final table in [
        'circles',
        'members',
        'items',
        'handoffs',
        'activity',
        'settings',
        'analytics_events',
      ]) {
        await txn.delete(table);
      }
    });
  }

  @override
  Future<void> close() => _db.close();

  // --- AnalyticsStore -----------------------------------------------------

  @override
  Future<void> appendEvent(String name, String props, DateTime at) async {
    await _db.insert('analytics_events', {
      'name': name,
      'props': props,
      'created_at': at.millisecondsSinceEpoch,
    });
    // Keep the log bounded.
    await _db.execute(
      'DELETE FROM analytics_events WHERE seq <= '
      '(SELECT MAX(seq) FROM analytics_events) - ?',
      [maxAnalyticsRows],
    );
  }

  @override
  Future<Map<String, int>> eventCounts() async {
    final rows = await _db.rawQuery(
      'SELECT name, COUNT(*) AS n FROM analytics_events GROUP BY name',
    );
    return {for (final r in rows) r['name']! as String: r['n']! as int};
  }

  // --- Mapping ------------------------------------------------------------

  static int _ms(DateTime d) => d.millisecondsSinceEpoch;
  static int? _msOrNull(DateTime? d) => d?.millisecondsSinceEpoch;
  static DateTime _dt(Object? v) =>
      DateTime.fromMillisecondsSinceEpoch(v! as int);
  static DateTime? _dtOrNull(Object? v) =>
      v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  static Map<String, Object?> _circleTo(Circle c) => {
    'id': c.id,
    'care_recipient_name': c.careRecipientName,
    'created_at': _ms(c.createdAt),
    'updated_at': _ms(c.updatedAt),
  };

  static Circle _circleFrom(Map<String, Object?> r) => Circle(
    id: r['id']! as String,
    careRecipientName: r['care_recipient_name']! as String,
    createdAt: _dt(r['created_at']),
    updatedAt: _dt(r['updated_at']),
  );

  static Map<String, Object?> _memberTo(Member m) => {
    'id': m.id,
    'name': m.name,
    'role': m.role.name,
    'color_index': m.colorIndex,
    'is_device_owner': m.isDeviceOwner ? 1 : 0,
    'created_at': _ms(m.createdAt),
    'updated_at': _ms(m.updatedAt),
    'removed_at': _msOrNull(m.removedAt),
  };

  static Member _memberFrom(Map<String, Object?> r) => Member(
    id: r['id']! as String,
    name: r['name']! as String,
    // Unknown roles degrade to the least privileged.
    role: _enum(Role.values, r['role'], Role.viewer),
    colorIndex: r['color_index']! as int,
    isDeviceOwner: r['is_device_owner'] == 1,
    createdAt: _dt(r['created_at']),
    updatedAt: _dt(r['updated_at']),
    removedAt: _dtOrNull(r['removed_at']),
  );

  static Map<String, Object?> _itemTo(CareItem i) => {
    'id': i.id,
    'series_id': i.seriesId,
    'kind': i.kind.name,
    'title': i.title,
    'notes': i.notes,
    'location': i.location,
    'assignee_id': i.assigneeId,
    'due_date': i.dueDate?.toIso(),
    'due_minutes': i.dueMinutes,
    'recurrence': i.recurrence.name,
    'anchor_day': i.anchorDay,
    'important': i.important ? 1 : 0,
    'status': i.status.name,
    'completed_at': _msOrNull(i.completedAt),
    'completed_by_id': i.completedById,
    'created_by_id': i.createdById,
    'created_at': _ms(i.createdAt),
    'updated_at': _ms(i.updatedAt),
    'deleted_at': _msOrNull(i.deletedAt),
  };

  static CareItem _itemFrom(Map<String, Object?> r) {
    final due = r['due_date'] as String?;
    CivilDate? dueDate;
    if (due != null) {
      try {
        dueDate = CivilDate.parse(due);
      } on FormatException {
        dueDate = null; // Corrupt date: keep the item, drop the date.
      }
    }
    return CareItem(
      id: r['id']! as String,
      seriesId: r['series_id']! as String,
      kind: _enum(ItemKind.values, r['kind'], ItemKind.task),
      title: r['title']! as String,
      notes: r['notes'] as String? ?? '',
      location: r['location'] as String? ?? '',
      assigneeId: r['assignee_id'] as String?,
      dueDate: dueDate,
      dueMinutes: dueDate == null ? null : r['due_minutes'] as int?,
      recurrence: _enum(Recurrence.values, r['recurrence'], Recurrence.none),
      anchorDay: r['anchor_day'] as int?,
      important: r['important'] == 1,
      status: _enum(ItemStatus.values, r['status'], ItemStatus.open),
      completedAt: _dtOrNull(r['completed_at']),
      completedById: r['completed_by_id'] as String?,
      createdById: r['created_by_id']! as String,
      createdAt: _dt(r['created_at']),
      updatedAt: _dt(r['updated_at']),
      deletedAt: _dtOrNull(r['deleted_at']),
    );
  }

  static Map<String, Object?> _handoffTo(HandoffNote h) => {
    'id': h.id,
    'author_id': h.authorId,
    'body': h.body,
    'created_at': _ms(h.createdAt),
  };

  static HandoffNote _handoffFrom(Map<String, Object?> r) => HandoffNote(
    id: r['id']! as String,
    authorId: r['author_id']! as String,
    body: r['body']! as String,
    createdAt: _dt(r['created_at']),
  );

  static Map<String, Object?> _activityTo(ActivityEvent a) => {
    'id': a.id,
    'type': a.type.name,
    'actor_id': a.actorId,
    'summary': a.summary,
    'created_at': _ms(a.createdAt),
    'item_id': a.itemId,
    'member_id': a.memberId,
    'handoff_id': a.handoffId,
  };

  static ActivityEvent _activityFrom(Map<String, Object?> r) => ActivityEvent(
    id: r['id']! as String,
    type: _enum(ActivityType.values, r['type'], ActivityType.itemEdited),
    actorId: r['actor_id']! as String,
    summary: r['summary']! as String,
    createdAt: _dt(r['created_at']),
    itemId: r['item_id'] as String?,
    memberId: r['member_id'] as String?,
    handoffId: r['handoff_id'] as String?,
  );
}
