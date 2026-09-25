import 'package:intl/intl.dart';

import 'civil_date.dart';

/// User-facing date/time strings. Locale-aware via intl's default locale.
String formatTimeOfDay(int minutesOfDay) {
  final dt = DateTime(2000, 1, 1, minutesOfDay ~/ 60, minutesOfDay % 60);
  return DateFormat.jm().format(dt);
}

/// "Today", "Tomorrow", "Yesterday", weekday within a week, else "Mon 3 Nov".
String formatRelativeDate(CivilDate date, CivilDate today) {
  final diff = today.daysUntil(date);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  final dt = date.toLocalDateTime();
  if (diff > 1 && diff < 7) return DateFormat.EEEE().format(dt);
  if (date.year == today.year) return DateFormat.MMMEd().format(dt);
  return DateFormat.yMMMEd().format(dt);
}

String formatDue(CivilDate? date, int? minutes, CivilDate today) {
  if (date == null) return 'No date';
  final d = formatRelativeDate(date, today);
  return minutes == null ? d : '$d, ${formatTimeOfDay(minutes)}';
}

String formatTimestamp(DateTime at, CivilDate today) {
  final d = formatRelativeDate(CivilDate.fromDateTime(at), today);
  return '$d, ${DateFormat.jm().format(at)}';
}
