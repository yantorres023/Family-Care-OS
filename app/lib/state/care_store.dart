import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/civil_date.dart';
import '../core/clock.dart';
import '../data/care_repository.dart';
import '../domain/models.dart';
import '../domain/permissions.dart';
import '../domain/recurrence.dart';
import '../domain/reminders.dart';
import '../domain/share_summary.dart';
import '../domain/today.dart';
import '../services/analytics.dart';
import '../services/notification_service.dart';
import '../services/share_service.dart';

/// A user-facing failure. [message] is safe to show in the UI.
class CareException implements Exception {
  const CareException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PermissionDenied extends CareException {
  const PermissionDenied([
    super.message = "You don't have permission to do that.",
  ]);
}

class ValidationFailed extends CareException {
  const ValidationFailed(super.message);
}

/// Input for creating or editing an item.
class ItemDraft {
  const ItemDraft({
    required this.title,
    this.kind = ItemKind.task,
    this.notes = '',
    this.location = '',
    this.assigneeId,
    this.dueDate,
    this.dueMinutes,
    this.recurrence = Recurrence.none,
    this.important = false,
  });

  factory ItemDraft.fromItem(CareItem i) => ItemDraft(
    title: i.title,
    kind: i.kind,
    notes: i.notes,
    location: i.location,
    assigneeId: i.assigneeId,
    dueDate: i.dueDate,
    dueMinutes: i.dueMinutes,
    recurrence: i.recurrence,
    important: i.important,
  );

  final ItemKind kind;
  final String title;
  final String notes;
  final String location;
  final String? assigneeId;
  final CivilDate? dueDate;
  final int? dueMinutes;
  final Recurrence recurrence;
  final bool important;
}

/// Suggested first tasks shown during onboarding (non-medical on purpose).
const starterTaskSuggestions = [
  'Weekly groceries',
  'Pick up prescription',
  'Pay utility bills',
  'Drive to appointment',
  'Check-in phone call',
  'Take out bins',
];

/// Settings keys.
abstract final class SettingKeys {
  static const actingMemberId = 'actingMemberId';
  static const shareFooter = 'share.footer';
  static const notificationsAsked = 'notifications.asked';
}

/// App state + all user commands. Writes go to the repository first; memory
/// is only updated after the write succeeds, so a failed write leaves the
/// UI consistent with storage.
class CareStore extends ChangeNotifier {
  CareStore({
    required CareRepository repository,
    required this._notifications,
    required this._analytics,
    required this._share,
    this._clock = const SystemClock(),
    this._policy = const PermissionPolicy(),
  }) : _repo = repository;

  final CareRepository _repo;
  final NotificationService _notifications;
  final Analytics _analytics;
  final ShareService _share;
  final Clock _clock;
  final PermissionPolicy _policy;
  static const _uuid = Uuid();

  bool _loaded = false;
  Object? _loadError;
  Circle? _circle;
  final _members = <String, Member>{};
  final _items = <String, CareItem>{};
  final _handoffs = <HandoffNote>[];
  final _activity = <ActivityEvent>[];
  final _settings = <String, String>{};

  // --- Read model ---------------------------------------------------------

  bool get isLoaded => _loaded;

  /// Item ids from tapped reminders ('' for the daily digest).
  Stream<String> get notificationOpens => _notifications.opened;
  Object? get loadError => _loadError;
  Circle? get circle => _circle;
  bool get isSetUp => _circle != null && me != null;
  PermissionPolicy get policy => _policy;
  Analytics get analytics => _analytics;

  DateTime get now => _clock.now();
  CivilDate get today => CivilDate.fromDateTime(now);

  /// The person who set up this device.
  Member? get me {
    for (final m in _members.values) {
      if (m.isDeviceOwner && m.isActive) return m;
    }
    return null;
  }

  /// Who is using the app right now (shared-device mode). Defaults to [me].
  Member? get actor {
    final id = _settings[SettingKeys.actingMemberId];
    final m = id == null ? null : _members[id];
    if (m != null && m.isActive) return m;
    return me;
  }

  bool can(Permission p, {CareItem? item}) => _policy.can(actor, p, item: item);

  List<Member> get activeMembers {
    final list = _members.values.where((m) => m.isActive).toList()
      ..sort((a, b) {
        if (a.role != b.role) return b.role.index.compareTo(a.role.index);
        return a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  List<Member> get allMembers => _members.values.toList();
  Map<String, Member> get membersById => Map.unmodifiable(_members);
  Member? memberById(String? id) => id == null ? null : _members[id];

  Iterable<CareItem> get liveItems => _items.values.where((i) => !i.isDeleted);
  CareItem? itemById(String id) {
    final item = _items[id];
    return item == null || item.isDeleted ? null : item;
  }

  TodayView get todayView => TodayView.build(liveItems, today);

  List<CareItem> itemsAssignedTo(String memberId) =>
      liveItems.where((i) => i.isOpen && i.assigneeId == memberId).toList()
        ..sort(compareByDue);

  HandoffNote? get latestHandoff => _handoffs.isEmpty ? null : _handoffs.last;
  HandoffNote? handoffById(String? id) {
    if (id == null) return null;
    for (final h in _handoffs) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Newest first.
  List<ActivityEvent> get timeline => _activity.reversed.toList();

  ReminderSettings get reminderSettings => ReminderSettings.fromMap(_settings);
  bool get shareFooter => _settings[SettingKeys.shareFooter] != 'false';

  /// Open item with the same title (case/space-insensitive) and due date.
  CareItem? findDuplicate(ItemDraft draft, {String? ignoreId}) {
    final key = _normalizeTitle(draft.title);
    for (final i in liveItems) {
      if (i.id == ignoreId || !i.isOpen) continue;
      if (_normalizeTitle(i.title) == key && i.dueDate == draft.dueDate) {
        return i;
      }
    }
    return null;
  }

  static String _normalizeTitle(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // --- Lifecycle ----------------------------------------------------------

  StreamSubscription<String>? _openedSub;

  Future<void> load() async {
    try {
      final snap = await _repo.load();
      _replaceState(snap);
      _loadError = null;
    } catch (e) {
      _loadError = e;
    }
    _loaded = true;
    _openedSub ??= _notifications.opened.listen((_) {
      _analytics.track(AnalyticsEvent.notificationOpened);
    });
    notifyListeners();
    if (_loadError == null) unawaited(refreshReminders());
  }

  void _replaceState(CareSnapshot snap) {
    _circle = snap.circle;
    _members
      ..clear()
      ..addEntries(snap.members.map((m) => MapEntry(m.id, m)));
    _items
      ..clear()
      ..addEntries(snap.items.map((i) => MapEntry(i.id, i)));
    _handoffs
      ..clear()
      ..addAll(snap.handoffs);
    _activity
      ..clear()
      ..addAll(snap.activity);
    _settings
      ..clear()
      ..addAll(snap.settings);
  }

  @override
  void dispose() {
    unawaited(_openedSub?.cancel());
    super.dispose();
  }

  Future<void> _commit(ChangeSet changes) async {
    await _repo.apply(changes);
    if (changes.circle != null) _circle = changes.circle;
    for (final m in changes.members) {
      _members[m.id] = m;
    }
    for (final i in changes.items) {
      _items[i.id] = i;
    }
    _handoffs
      ..addAll(changes.handoffs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _activity
      ..addAll(changes.activity)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _settings.addAll(changes.settings);
    notifyListeners();
  }

  ActivityEvent _event(
    ActivityType type,
    String summary, {
    String? actorId,
    String? itemId,
    String? memberId,
    String? handoffId,
  }) => ActivityEvent(
    id: _uuid.v4(),
    type: type,
    actorId: actorId ?? actor!.id,
    summary: summary,
    createdAt: now,
    itemId: itemId,
    memberId: memberId,
    handoffId: handoffId,
  );

  Member _requireActor() {
    final a = actor;
    if (a == null) throw const CareException('Set up the app first.');
    return a;
  }

  void _require(Permission p, {CareItem? item}) {
    if (!_policy.can(actor, p, item: item)) throw const PermissionDenied();
  }

  // --- Setup --------------------------------------------------------------

  /// First run: creates the circle, "me" as owner, optional helpers and
  /// starter tasks.
  Future<void> setUp({
    required String careRecipientName,
    required String myName,
    List<String> helperNames = const [],
    List<String> starterTasks = const [],
  }) async {
    if (isSetUp) throw const CareException('Already set up.');
    final recipient = _validName(careRecipientName, 'their name');
    final mine = _validName(myName, 'your name');
    final t = now;
    final changes = ChangeSet();
    final circle = Circle(
      id: _uuid.v4(),
      careRecipientName: recipient,
      createdAt: t,
      updatedAt: t,
    );
    final meMember = Member(
      id: _uuid.v4(),
      name: mine,
      role: Role.owner,
      colorIndex: 0,
      isDeviceOwner: true,
      createdAt: t,
      updatedAt: t,
    );
    changes
      ..circle = circle
      ..members.add(meMember)
      ..activity.add(
        _event(
          ActivityType.circleCreated,
          '$mine started coordinating care for $recipient',
          actorId: meMember.id,
        ),
      );

    var color = 1;
    final seenNames = {mine.toLowerCase()};
    for (final raw in helperNames) {
      final name = raw.trim();
      if (name.isEmpty || !seenNames.add(name.toLowerCase())) continue;
      final helper = Member(
        id: _uuid.v4(),
        name: _validName(name, 'helper name'),
        role: Role.member,
        colorIndex: color++,
        createdAt: t,
        updatedAt: t,
      );
      changes
        ..members.add(helper)
        ..activity.add(
          _event(
            ActivityType.memberAdded,
            '$mine added ${helper.name}',
            actorId: meMember.id,
            memberId: helper.id,
          ),
        );
    }

    final seenTasks = <String>{};
    for (final raw in starterTasks) {
      final title = raw.trim();
      if (title.isEmpty || !seenTasks.add(_normalizeTitle(title))) continue;
      final item = _newItem(
        ItemDraft(title: _validTitle(title)),
        createdById: meMember.id,
        at: t,
      );
      changes
        ..items.add(item)
        ..activity.add(
          _event(
            ActivityType.itemCreated,
            '$mine added "${item.title}"',
            actorId: meMember.id,
            itemId: item.id,
          ),
        );
    }

    await _commit(changes);
    _analytics
      ..track(AnalyticsEvent.familyCreated)
      ..track(AnalyticsEvent.careProfileCreated)
      ..track(AnalyticsEvent.onboardingCompleted, {
        'helpers': changes.members.length - 1,
        'starter_tasks': changes.items.length,
      });
    for (var i = 1; i < changes.members.length; i++) {
      _analytics.track(AnalyticsEvent.memberInvited, {'method': 'local_name'});
    }
    for (var i = 0; i < changes.items.length; i++) {
      _analytics.track(AnalyticsEvent.taskCreated, {'source': 'onboarding'});
    }
  }

  Future<void> renameCareRecipient(String name) async {
    _require(Permission.manageMembers);
    final c = _circle!;
    await _commit(
      ChangeSet()
        ..circle = c.copyWith(
          careRecipientName: _validName(name, 'their name'),
          updatedAt: now,
        ),
    );
  }

  // --- Items --------------------------------------------------------------

  CareItem _newItem(
    ItemDraft d, {
    required String createdById,
    required DateTime at,
    String? seriesId,
  }) {
    final id = _uuid.v4();
    return CareItem(
      id: id,
      seriesId: seriesId ?? id,
      kind: d.kind,
      title: d.title.trim(),
      notes: d.notes.trim(),
      location: d.kind == ItemKind.appointment ? d.location.trim() : '',
      assigneeId: d.assigneeId,
      dueDate: d.dueDate,
      dueMinutes: d.dueDate == null ? null : d.dueMinutes,
      recurrence: d.recurrence,
      anchorDay: d.recurrence == Recurrence.monthly ? d.dueDate?.day : null,
      important: d.important,
      createdById: createdById,
      createdAt: at,
      updatedAt: at,
    );
  }

  void _validateDraft(ItemDraft d) {
    _validTitle(d.title);
    if (d.notes.trim().length > Limits.notesMax) {
      throw const ValidationFailed(
        'Notes are too long (max ${Limits.notesMax} characters).',
      );
    }
    if (d.location.trim().length > Limits.locationMax) {
      throw const ValidationFailed(
        'Place is too long (max ${Limits.locationMax} characters).',
      );
    }
    if (d.recurrence != Recurrence.none && d.dueDate == null) {
      throw const ValidationFailed('Pick a date for repeating tasks.');
    }
    final m = d.dueMinutes;
    if (m != null && (m < 0 || m >= 24 * 60)) {
      throw const ValidationFailed('Invalid time.');
    }
    if (d.assigneeId != null) {
      final a = _members[d.assigneeId];
      if (a == null || !a.isActive) {
        throw const ValidationFailed('That person is no longer in the circle.');
      }
    }
  }

  String _validTitle(String raw) {
    final t = raw.trim();
    if (t.isEmpty) throw const ValidationFailed('Add a title.');
    if (t.length > Limits.titleMax) {
      throw const ValidationFailed(
        'Title is too long (max ${Limits.titleMax} characters).',
      );
    }
    return t;
  }

  String _validName(String raw, String what) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) throw ValidationFailed('Add $what.');
    if (t.length > Limits.nameMax) {
      throw ValidationFailed(
        'That name is too long (max ${Limits.nameMax} characters).',
      );
    }
    return t;
  }

  Future<CareItem> createItem(ItemDraft draft) async {
    final a = _requireActor();
    _require(Permission.createItem);
    _validateDraft(draft);
    // Helpers may only assign new items to themselves or leave them open.
    if (draft.assigneeId != null &&
        draft.assigneeId != a.id &&
        a.role.index < Role.coordinator.index) {
      throw const PermissionDenied('Helpers can only take tasks themselves.');
    }
    final item = _newItem(draft, createdById: a.id, at: now);
    final changes = ChangeSet()
      ..items.add(item)
      ..activity.add(
        _event(
          ActivityType.itemCreated,
          '${a.name} added "${item.title}"',
          itemId: item.id,
        ),
      );
    final assignee = memberById(item.assigneeId);
    if (assignee != null) {
      changes.activity.add(
        _event(
          ActivityType.itemAssigned,
          assignee.id == a.id
              ? '${a.name} is taking "${item.title}"'
              : '${a.name} asked ${assignee.name} to do "${item.title}"',
          itemId: item.id,
          memberId: assignee.id,
        ),
      );
    }
    await _commit(changes);
    _analytics.track(
      item.kind == ItemKind.appointment
          ? AnalyticsEvent.eventCreated
          : AnalyticsEvent.taskCreated,
      {
        'recurring': item.isRecurring,
        'has_time': item.hasTime,
        'assigned': item.assigneeId != null,
      },
    );
    if (assignee != null) {
      _analytics.track(AnalyticsEvent.taskAssigned, {
        'self': assignee.id == a.id,
      });
    }
    await _afterItemsChanged(assignedToMe: item.assigneeId == me?.id);
    return item;
  }

  Future<void> updateItem(String id, ItemDraft draft) async {
    final a = _requireActor();
    final existing = _requireItem(id);
    _require(Permission.editItem, item: existing);
    _validateDraft(draft);
    if (draft.assigneeId != existing.assigneeId &&
        !_policy.canAssign(a, existing, draft.assigneeId)) {
      throw const PermissionDenied();
    }
    final updated = existing.copyWith(
      kind: draft.kind,
      title: draft.title.trim(),
      notes: draft.notes.trim(),
      location: draft.kind == ItemKind.appointment ? draft.location.trim() : '',
      assigneeId: draft.assigneeId,
      clearAssignee: draft.assigneeId == null,
      dueDate: draft.dueDate,
      clearDueDate: draft.dueDate == null,
      dueMinutes: draft.dueMinutes,
      clearDueMinutes: draft.dueMinutes == null,
      recurrence: draft.recurrence,
      anchorDay: draft.recurrence == Recurrence.monthly
          ? draft.dueDate?.day
          : null,
      clearAnchorDay: draft.recurrence != Recurrence.monthly,
      important: draft.important,
      updatedAt: now,
    );
    final changes = ChangeSet()
      ..items.add(updated)
      ..activity.add(
        _event(
          ActivityType.itemEdited,
          '${a.name} updated "${updated.title}"',
          itemId: id,
        ),
      );
    if (updated.assigneeId != existing.assigneeId) {
      changes.activity.add(_assignmentEvent(a, updated));
    }
    await _commit(changes);
    if (updated.assigneeId != existing.assigneeId &&
        updated.assigneeId != null) {
      _analytics.track(AnalyticsEvent.taskAssigned, {
        'self': updated.assigneeId == a.id,
      });
    }
    await _afterItemsChanged(
      assignedToMe:
          updated.assigneeId == me?.id && existing.assigneeId != me?.id,
    );
  }

  ActivityEvent _assignmentEvent(Member a, CareItem item) {
    final to = memberById(item.assigneeId);
    if (to == null) {
      return _event(
        ActivityType.itemUnassigned,
        '${a.name} marked "${item.title}" as needing someone',
        itemId: item.id,
      );
    }
    return _event(
      ActivityType.itemAssigned,
      to.id == a.id
          ? '${a.name} is taking "${item.title}"'
          : '${a.name} asked ${to.name} to do "${item.title}"',
      itemId: item.id,
      memberId: to.id,
    );
  }

  /// Set or clear who is doing [itemId].
  Future<void> assign(String itemId, String? memberId) async {
    final a = _requireActor();
    final item = _requireItem(itemId);
    if (item.assigneeId == memberId) return;
    if (!_policy.canAssign(a, item, memberId)) throw const PermissionDenied();
    if (memberId != null && !(_members[memberId]?.isActive ?? false)) {
      throw const ValidationFailed('That person is no longer in the circle.');
    }
    final updated = item.copyWith(
      assigneeId: memberId,
      clearAssignee: memberId == null,
      updatedAt: now,
    );
    await _commit(
      ChangeSet()
        ..items.add(updated)
        ..activity.add(_assignmentEvent(a, updated)),
    );
    if (memberId != null) {
      _analytics.track(AnalyticsEvent.taskAssigned, {'self': memberId == a.id});
    }
    await _afterItemsChanged(
      assignedToMe: memberId != null && memberId == me?.id,
    );
  }

  /// Marks done. For recurring items, creates and returns the next
  /// occurrence (same owner, same series).
  Future<CareItem?> complete(String itemId) async {
    final a = _requireActor();
    final item = _requireItem(itemId);
    if (item.isDone) return null;
    _require(Permission.completeItem, item: item);
    final t = now;
    final done = item.copyWith(
      status: ItemStatus.done,
      completedAt: t,
      completedById: a.id,
      updatedAt: t,
    );
    final changes = ChangeSet()
      ..items.add(done)
      ..activity.add(
        _event(
          ActivityType.itemCompleted,
          '${a.name} did "${item.title}"',
          itemId: item.id,
        ),
      );

    CareItem? next;
    final nextDate = nextDueDate(item, today);
    if (nextDate != null) {
      // Don't spawn a second copy if one is already open (e.g. item was
      // reopened and completed again).
      final alreadyOpen = liveItems.any(
        (i) => i.seriesId == item.seriesId && i.isOpen && i.id != item.id,
      );
      if (!alreadyOpen) {
        next = CareItem(
          id: _uuid.v4(),
          seriesId: item.seriesId,
          kind: item.kind,
          title: item.title,
          notes: item.notes,
          location: item.location,
          assigneeId: (memberById(item.assigneeId)?.isActive ?? false)
              ? item.assigneeId
              : null,
          dueDate: nextDate,
          dueMinutes: item.dueMinutes,
          recurrence: item.recurrence,
          anchorDay: item.anchorDay,
          important: item.important,
          createdById: item.createdById,
          createdAt: t,
          updatedAt: t,
        );
        changes.items.add(next);
      }
    }
    await _commit(changes);
    _analytics.track(AnalyticsEvent.taskCompleted, {
      'by_assignee': item.assigneeId == a.id,
      'was_assigned': item.assigneeId != null,
      'recurring': item.isRecurring,
      'overdue_days': item.dueDate == null
          ? 0
          : (item.dueDate!.daysUntil(today)).clamp(0, 365),
    });
    await _afterItemsChanged();
    return next;
  }

  /// Undo a completion. Removes an untouched next occurrence that the
  /// completion generated, so undo doesn't leave duplicates.
  Future<void> reopen(String itemId) async {
    final a = _requireActor();
    final item = _requireItem(itemId);
    if (item.isOpen) return;
    _require(Permission.completeItem, item: item);
    final t = now;
    final changes = ChangeSet()
      ..items.add(
        item.copyWith(
          status: ItemStatus.open,
          clearCompletion: true,
          updatedAt: t,
        ),
      )
      ..activity.add(
        _event(
          ActivityType.itemReopened,
          '${a.name} reopened "${item.title}"',
          itemId: item.id,
        ),
      );
    if (item.isRecurring) {
      for (final other in liveItems) {
        if (other.seriesId == item.seriesId &&
            other.id != item.id &&
            other.isOpen &&
            other.createdAt == other.updatedAt &&
            item.completedAt != null &&
            !other.createdAt.isBefore(item.completedAt!)) {
          changes.items.add(other.copyWith(deletedAt: t, updatedAt: t));
        }
      }
    }
    await _commit(changes);
    await _afterItemsChanged();
  }

  Future<void> deleteItem(String itemId) async {
    final a = _requireActor();
    final item = _requireItem(itemId);
    _require(Permission.deleteItem, item: item);
    final t = now;
    await _commit(
      ChangeSet()
        ..items.add(item.copyWith(deletedAt: t, updatedAt: t))
        ..activity.add(
          _event(
            ActivityType.itemDeleted,
            '${a.name} removed "${item.title}"',
            itemId: item.id,
          ),
        ),
    );
    await _afterItemsChanged();
  }

  CareItem _requireItem(String id) {
    final item = itemById(id);
    if (item == null) {
      throw const CareException('That task no longer exists.');
    }
    return item;
  }

  // --- Handoff ------------------------------------------------------------

  Future<HandoffNote> addHandoff(String body) async {
    final a = _requireActor();
    _require(Permission.addHandoff);
    final text = body.trim();
    if (text.isEmpty) throw const ValidationFailed('Write a short note first.');
    if (text.length > Limits.handoffMax) {
      throw const ValidationFailed(
        'Note is too long (max ${Limits.handoffMax} characters).',
      );
    }
    final note = HandoffNote(
      id: _uuid.v4(),
      authorId: a.id,
      body: text,
      createdAt: now,
    );
    await _commit(
      ChangeSet()
        ..handoffs.add(note)
        ..activity.add(
          _event(
            ActivityType.handoffAdded,
            '${a.name} left a note',
            handoffId: note.id,
          ),
        ),
    );
    _analytics.track(AnalyticsEvent.handoffAdded, {
      'length_bucket': text.length < 80
          ? 'short'
          : (text.length < 400 ? 'medium' : 'long'),
    });
    return note;
  }

  // --- Members ------------------------------------------------------------

  Future<Member> addMember(String name, {Role role = Role.member}) async {
    final a = _requireActor();
    _require(Permission.manageMembers);
    if (role == Role.owner) {
      throw const PermissionDenied('There can only be one owner.');
    }
    if (role == Role.coordinator && a.role != Role.owner) {
      throw const PermissionDenied('Only the owner can add coordinators.');
    }
    final clean = _validName(name, 'a name');
    if (activeMembers.any((m) => m.name.toLowerCase() == clean.toLowerCase())) {
      throw ValidationFailed('$clean is already in the circle.');
    }
    final t = now;
    final used = _members.values.map((m) => m.colorIndex).toSet();
    var color = 0;
    while (used.contains(color)) {
      color++;
    }
    final m = Member(
      id: _uuid.v4(),
      name: clean,
      role: role,
      colorIndex: color,
      createdAt: t,
      updatedAt: t,
    );
    await _commit(
      ChangeSet()
        ..members.add(m)
        ..activity.add(
          _event(
            ActivityType.memberAdded,
            '${a.name} added ${m.name}',
            memberId: m.id,
          ),
        ),
    );
    _analytics.track(AnalyticsEvent.memberInvited, {
      'method': 'local_name',
      'role': role.name,
    });
    return m;
  }

  Future<void> renameMember(String id, String name) async {
    final a = _requireActor();
    final target = _members[id];
    if (target == null || !target.isActive) {
      throw const CareException('That person is no longer in the circle.');
    }
    // Anyone may fix their own name; managing others needs permission.
    if (id != a.id) _require(Permission.manageMembers);
    final clean = _validName(name, 'a name');
    if (clean == target.name) return;
    await _commit(
      ChangeSet()
        ..members.add(target.copyWith(name: clean, updatedAt: now))
        ..activity.add(
          _event(
            ActivityType.memberUpdated,
            '${target.name} is now called $clean',
            memberId: id,
          ),
        ),
    );
  }

  Future<void> changeRole(String id, Role role) async {
    final a = _requireActor();
    final target = _members[id];
    if (target == null) throw const CareException('Person not found.');
    if (target.role == role) return;
    if (!_policy.canChangeRole(a, target, role)) throw const PermissionDenied();
    await _commit(
      ChangeSet()
        ..members.add(target.copyWith(role: role, updatedAt: now))
        ..activity.add(
          _event(
            ActivityType.memberUpdated,
            '${a.name} made ${target.name} a ${role.label.toLowerCase()}',
            memberId: id,
          ),
        ),
    );
  }

  /// Removes [id] from the circle. Their open items become unassigned so
  /// nothing silently falls through the cracks. History is kept.
  Future<int> removeMember(String id) async {
    final a = _requireActor();
    final target = _members[id];
    if (target == null) throw const CareException('Person not found.');
    if (!_policy.canRemoveMember(a, target)) {
      throw PermissionDenied(
        target.role == Role.owner
            ? 'Transfer ownership before removing the owner.'
            : "You can't remove ${target.name}.",
      );
    }
    final t = now;
    final changes = ChangeSet()
      ..members.add(target.copyWith(removedAt: t, updatedAt: t))
      ..activity.add(
        _event(
          ActivityType.memberRemoved,
          '${a.name} removed ${target.name} from the circle',
          memberId: id,
        ),
      );
    var released = 0;
    for (final item in liveItems) {
      if (item.isOpen && item.assigneeId == id) {
        changes.items.add(item.copyWith(clearAssignee: true, updatedAt: t));
        released++;
      }
    }
    if (released > 0) {
      changes.activity.add(
        _event(
          ActivityType.itemUnassigned,
          released == 1
              ? '1 task from ${target.name} now needs someone'
              : '$released tasks from ${target.name} now need someone',
          memberId: id,
        ),
      );
    }
    if (_settings[SettingKeys.actingMemberId] == id) {
      changes.settings[SettingKeys.actingMemberId] = me?.id ?? '';
    }
    await _commit(changes);
    await _afterItemsChanged();
    return released;
  }

  Future<void> transferOwnership(String toId) async {
    final a = _requireActor();
    final target = _members[toId];
    if (target == null || !_policy.canTransferOwnership(a, target)) {
      throw const PermissionDenied();
    }
    final t = now;
    await _commit(
      ChangeSet()
        ..members.addAll([
          a.copyWith(role: Role.coordinator, updatedAt: t),
          target.copyWith(role: Role.owner, updatedAt: t),
        ])
        ..activity.add(
          _event(
            ActivityType.ownershipTransferred,
            '${a.name} made ${target.name} the owner',
            memberId: toId,
          ),
        ),
    );
  }

  /// Shared-device mode: attribute actions to [memberId].
  Future<void> setActor(String memberId) async {
    final m = _members[memberId];
    if (m == null || !m.isActive) {
      throw const CareException('That person is no longer in the circle.');
    }
    await _commit(ChangeSet()..settings[SettingKeys.actingMemberId] = memberId);
  }

  // --- Settings & reminders ----------------------------------------------

  Future<void> updateReminderSettings(ReminderSettings s) async {
    _require(Permission.editSettings);
    await _commit(ChangeSet()..settings.addAll(s.toMap()));
    await refreshReminders();
  }

  Future<void> setShareFooter(bool value) async {
    _require(Permission.editSettings);
    await _commit(
      ChangeSet()..settings[SettingKeys.shareFooter] = value.toString(),
    );
  }

  /// Recomputes and reschedules all local reminders. Never throws.
  Future<void> refreshReminders() async {
    try {
      final plan = const ReminderPlanner().plan(
        items: liveItems,
        meId: me?.id,
        settings: reminderSettings,
        now: now,
        careRecipientName: _circle?.careRecipientName ?? '',
      );
      await _notifications.replaceAll(plan);
    } catch (e) {
      debugPrint('Reminder refresh failed: $e');
    }
  }

  Future<void> _afterItemsChanged({bool assignedToMe = false}) async {
    if (assignedToMe &&
        _settings[SettingKeys.notificationsAsked] != 'true' &&
        reminderSettings.enabled) {
      // Ask in context, once: the first time something is assigned to me.
      try {
        await _commit(
          ChangeSet()..settings[SettingKeys.notificationsAsked] = 'true',
        );
        await _notifications.requestPermission();
      } catch (e) {
        debugPrint('Permission request failed: $e');
      }
    }
    await refreshReminders();
  }

  Future<bool> requestNotificationPermission() async {
    try {
      return await _notifications.requestPermission();
    } catch (_) {
      return false;
    }
  }

  Future<bool?> notificationsEnabled() async {
    try {
      return await _notifications.areEnabled();
    } catch (_) {
      return null;
    }
  }

  // --- Sharing ------------------------------------------------------------

  ShareSummary get _summary => ShareSummary(includeFooter: shareFooter);

  String dailyUpdateText() => _summary.dailyUpdate(
    circle: _circle!,
    today: today,
    items: liveItems,
    membersById: _members,
    latestHandoff: _recentHandoff(),
  );

  /// The latest handoff, if written in the last 48 hours.
  HandoffNote? _recentHandoff() {
    final h = latestHandoff;
    if (h == null) return null;
    return now.difference(h.createdAt) <= const Duration(hours: 48) ? h : null;
  }

  Future<bool> shareDailyUpdate() async {
    final ok = await _share.shareText(
      dailyUpdateText(),
      subject: '${_circle!.careRecipientName} — update',
    );
    if (ok) _analytics.track(AnalyticsEvent.updateShared);
    return ok;
  }

  Future<bool> askForHelp(String itemId) async {
    final item = _requireItem(itemId);
    final ok = await _share.shareText(
      _summary.askForHelp(circle: _circle!, item: item, today: today),
    );
    if (ok) _analytics.track(AnalyticsEvent.helpRequested);
    return ok;
  }

  // --- Data rights --------------------------------------------------------

  /// Everything stored on this device, as JSON (data portability).
  String exportJson() {
    String? ts(DateTime? d) => d?.toUtc().toIso8601String();
    final data = {
      'format': 'baton-export',
      'version': 1,
      'exportedAt': ts(now),
      'circle': _circle == null
          ? null
          : {
              'id': _circle!.id,
              'careRecipientName': _circle!.careRecipientName,
              'createdAt': ts(_circle!.createdAt),
            },
      'members': [
        for (final m in _members.values)
          {
            'id': m.id,
            'name': m.name,
            'role': m.role.name,
            'isDeviceOwner': m.isDeviceOwner,
            'createdAt': ts(m.createdAt),
            'removedAt': ts(m.removedAt),
          },
      ],
      'items': [
        for (final i in _items.values)
          {
            'id': i.id,
            'seriesId': i.seriesId,
            'kind': i.kind.name,
            'title': i.title,
            'notes': i.notes,
            'location': i.location,
            'assigneeId': i.assigneeId,
            'dueDate': i.dueDate?.toIso(),
            'dueMinutes': i.dueMinutes,
            'recurrence': i.recurrence.name,
            'important': i.important,
            'status': i.status.name,
            'completedAt': ts(i.completedAt),
            'completedById': i.completedById,
            'createdById': i.createdById,
            'createdAt': ts(i.createdAt),
            'deletedAt': ts(i.deletedAt),
          },
      ],
      'handoffs': [
        for (final h in _handoffs)
          {
            'id': h.id,
            'authorId': h.authorId,
            'body': h.body,
            'createdAt': ts(h.createdAt),
          },
      ],
      'activity': [
        for (final e in _activity)
          {
            'type': e.type.name,
            'actorId': e.actorId,
            'summary': e.summary,
            'createdAt': ts(e.createdAt),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> exportData() async {
    _require(Permission.exportData);
    final stamp = today.toIso();
    return _share.shareFile(
      'baton-export-$stamp.json',
      exportJson(),
      'application/json',
    );
  }

  /// Irreversibly deletes everything on this device and cancels reminders.
  Future<void> deleteAllData() async {
    _require(Permission.deleteAllData);
    await _repo.wipe();
    await _notifications.cancelAll();
    _replaceState(const CareSnapshot());
    notifyListeners();
  }
}
