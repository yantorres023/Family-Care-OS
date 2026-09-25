import '../core/civil_date.dart';

/// Field limits. Enforced in the store and the UI.
abstract final class Limits {
  static const nameMax = 60;
  static const titleMax = 120;
  static const locationMax = 200;
  static const notesMax = 4000;
  static const handoffMax = 2000;
}

/// Roles, least to most privileged. See docs/engineering/PRIVACY_MODEL.md.
enum Role {
  viewer,
  member,
  coordinator,
  owner;

  String get label => switch (this) {
    Role.viewer => 'Viewer',
    Role.member => 'Helper',
    Role.coordinator => 'Coordinator',
    Role.owner => 'Owner',
  };

  String get description => switch (this) {
    Role.viewer => 'Can see tasks and notes, but not change anything.',
    Role.member =>
      'Can add tasks, take on and complete tasks, and write handoff notes.',
    Role.coordinator => 'Can do everything a helper can, plus manage people.',
    Role.owner =>
      'Set up this care circle. Can change roles and delete all data.',
  };
}

/// The family space around one cared-for person (or a couple).
class Circle {
  const Circle({
    required this.id,
    required this.careRecipientName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Name or nickname only (e.g. "Mom", "Dad & Mum"). No other personal data.
  final String careRecipientName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Circle copyWith({String? careRecipientName, DateTime? updatedAt}) => Circle(
    id: id,
    careRecipientName: careRecipientName ?? this.careRecipientName,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// A person who helps. Not an account: in the MVP members are names the
/// coordinator adds (see DECISIONS D-005).
class Member {
  const Member({
    required this.id,
    required this.name,
    required this.role,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
    this.isDeviceOwner = false,
    this.removedAt,
  });

  final String id;
  final String name;
  final Role role;
  final int colorIndex;

  /// The person who set up the app on this device ("me").
  final bool isDeviceOwner;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Removed members stay in history (for the timeline) but can't act.
  final DateTime? removedAt;

  bool get isActive => removedAt == null;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    // Use runes so a leading emoji or accented letter isn't split in half.
    final letters = parts
        .take(2)
        .map((p) => String.fromCharCode(p.runes.first))
        .join();
    return letters.toUpperCase();
  }

  Member copyWith({
    String? name,
    Role? role,
    int? colorIndex,
    bool? isDeviceOwner,
    DateTime? updatedAt,
    DateTime? removedAt,
    bool clearRemovedAt = false,
  }) => Member(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    colorIndex: colorIndex ?? this.colorIndex,
    isDeviceOwner: isDeviceOwner ?? this.isDeviceOwner,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    removedAt: clearRemovedAt ? null : (removedAt ?? this.removedAt),
  );
}

enum ItemKind {
  task,
  appointment;

  String get label => switch (this) {
    ItemKind.task => 'Task',
    ItemKind.appointment => 'Appointment',
  };
}

enum ItemStatus { open, done }

enum Recurrence {
  none,
  daily,
  weekly,
  biweekly,
  monthly;

  String get label => switch (this) {
    Recurrence.none => 'Does not repeat',
    Recurrence.daily => 'Every day',
    Recurrence.weekly => 'Every week',
    Recurrence.biweekly => 'Every 2 weeks',
    Recurrence.monthly => 'Every month',
  };

  String get shortLabel => switch (this) {
    Recurrence.none => '',
    Recurrence.daily => 'Daily',
    Recurrence.weekly => 'Weekly',
    Recurrence.biweekly => 'Every 2 weeks',
    Recurrence.monthly => 'Monthly',
  };
}

/// A task or appointment. Deliberately has no medical fields.
class CareItem {
  const CareItem({
    required this.id,
    required this.seriesId,
    required this.kind,
    required this.title,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.location = '',
    this.assigneeId,
    this.dueDate,
    this.dueMinutes,
    this.recurrence = Recurrence.none,
    this.anchorDay,
    this.important = false,
    this.status = ItemStatus.open,
    this.completedAt,
    this.completedById,
    this.deletedAt,
  });

  final String id;

  /// Shared by every occurrence of a recurring item.
  final String seriesId;
  final ItemKind kind;
  final String title;
  final String notes;
  final String location;

  /// Null = nobody has taken this on yet.
  final String? assigneeId;
  final CivilDate? dueDate;

  /// Minutes after local midnight; null = any time that day.
  final int? dueMinutes;
  final Recurrence recurrence;

  /// For monthly recurrence: the intended day-of-month (e.g. 31), so that
  /// Jan 31 → Feb 28 → Mar 31 rather than drifting to the 28th.
  final int? anchorDay;
  final bool important;
  final ItemStatus status;
  final DateTime? completedAt;
  final String? completedById;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft delete (tombstone), kept for future sync.
  final DateTime? deletedAt;

  bool get isOpen => status == ItemStatus.open;
  bool get isDone => status == ItemStatus.done;
  bool get isDeleted => deletedAt != null;
  bool get isRecurring => recurrence != Recurrence.none;
  bool get hasTime => dueMinutes != null;

  CareItem copyWith({
    ItemKind? kind,
    String? title,
    String? notes,
    String? location,
    String? assigneeId,
    bool clearAssignee = false,
    CivilDate? dueDate,
    bool clearDueDate = false,
    int? dueMinutes,
    bool clearDueMinutes = false,
    Recurrence? recurrence,
    int? anchorDay,
    bool clearAnchorDay = false,
    bool? important,
    ItemStatus? status,
    DateTime? completedAt,
    String? completedById,
    bool clearCompletion = false,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) => CareItem(
    id: id,
    seriesId: seriesId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    location: location ?? this.location,
    assigneeId: clearAssignee ? null : (assigneeId ?? this.assigneeId),
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    dueMinutes: clearDueMinutes || clearDueDate
        ? null
        : (dueMinutes ?? this.dueMinutes),
    recurrence: recurrence ?? this.recurrence,
    anchorDay: clearAnchorDay ? null : (anchorDay ?? this.anchorDay),
    important: important ?? this.important,
    status: status ?? this.status,
    completedAt: clearCompletion ? null : (completedAt ?? this.completedAt),
    completedById: clearCompletion
        ? null
        : (completedById ?? this.completedById),
    createdById: createdById,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );
}

/// "What should the next person know?"
class HandoffNote {
  const HandoffNote({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime createdAt;
}

enum ActivityType {
  circleCreated,
  itemCreated,
  itemEdited,
  itemAssigned,
  itemUnassigned,
  itemCompleted,
  itemReopened,
  itemDeleted,
  handoffAdded,
  memberAdded,
  memberUpdated,
  memberRemoved,
  ownershipTransferred,
}

/// Append-only log that powers the timeline.
///
/// [summary] is a human-readable snapshot written at the time of the event,
/// so history stays readable after items are edited or deleted.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.actorId,
    required this.summary,
    required this.createdAt,
    this.itemId,
    this.memberId,
    this.handoffId,
  });

  final String id;
  final ActivityType type;
  final String actorId;
  final String summary;
  final DateTime createdAt;
  final String? itemId;
  final String? memberId;
  final String? handoffId;
}
