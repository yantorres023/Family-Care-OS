import 'package:family_care/core/civil_date.dart';
import 'package:family_care/domain/models.dart';

final t0 = DateTime(2026, 9, 25, 9);

int _seq = 0;

CareItem item({
  String? id,
  String title = 'Task',
  ItemKind kind = ItemKind.task,
  CivilDate? due,
  int? minutes,
  String? assignee,
  Recurrence recurrence = Recurrence.none,
  int? anchorDay,
  bool important = false,
  ItemStatus status = ItemStatus.open,
  DateTime? completedAt,
  String? completedBy,
  DateTime? deletedAt,
  String location = '',
  String notes = '',
}) {
  final i = id ?? 'i${_seq++}';
  return CareItem(
    id: i,
    seriesId: i,
    kind: kind,
    title: title,
    notes: notes,
    location: location,
    assigneeId: assignee,
    dueDate: due,
    dueMinutes: minutes,
    recurrence: recurrence,
    anchorDay: anchorDay,
    important: important,
    status: status,
    completedAt: completedAt,
    completedById: completedBy,
    createdById: 'me',
    createdAt: t0,
    updatedAt: t0,
    deletedAt: deletedAt,
  );
}

Member member(
  String id,
  String name, {
  Role role = Role.member,
  bool deviceOwner = false,
  DateTime? removedAt,
}) => Member(
  id: id,
  name: name,
  role: role,
  colorIndex: 0,
  isDeviceOwner: deviceOwner,
  createdAt: t0,
  updatedAt: t0,
  removedAt: removedAt,
);

/// intl formats times with a narrow no-break space ("3:00 PM").
/// Normalise so expectations can use a plain space.
String plain(String s) => s.replaceAll(' ', ' ');
