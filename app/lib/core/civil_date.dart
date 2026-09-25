/// A calendar date with no time or time zone ("wall calendar" date).
///
/// Care tasks are wall-clock commitments ("Tuesday 10:30 at the clinic"),
/// so they are stored as civil dates plus optional minutes-of-day. This keeps
/// them stable across DST changes and device time-zone changes.
class CivilDate implements Comparable<CivilDate> {
  CivilDate(int year, int month, int day)
    : this._normalized(DateTime.utc(year, month, day));

  CivilDate._normalized(DateTime utc)
    : year = utc.year,
      month = utc.month,
      day = utc.day;

  factory CivilDate.fromDateTime(DateTime dt) =>
      CivilDate(dt.year, dt.month, dt.day);

  /// Parses `YYYY-MM-DD`. Throws [FormatException] on bad input.
  factory CivilDate.parse(String iso) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    if (match == null) throw FormatException('Invalid date', iso);
    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    final date = CivilDate(y, m, d);
    if (date.month != m || date.day != d) {
      throw FormatException('Invalid date', iso);
    }
    return date;
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// Weekday, 1 = Monday … 7 = Sunday.
  int get weekday => _utc.weekday;

  CivilDate addDays(int days) =>
      CivilDate._normalized(_utc.add(Duration(days: days)));

  /// Adds calendar months, clamping [anchorDay] (defaults to [day]) to the
  /// last day of the target month. Jan 31 + 1 month = Feb 28/29.
  CivilDate addMonths(int months, {int? anchorDay}) {
    final totalMonths = year * 12 + (month - 1) + months;
    final y = totalMonths ~/ 12;
    final m = totalMonths % 12 + 1;
    final last = daysInMonth(y, m);
    final wanted = anchorDay ?? day;
    return CivilDate(y, m, wanted > last ? last : wanted);
  }

  int daysUntil(CivilDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(CivilDate other) => compareTo(other) < 0;
  bool isAfter(CivilDate other) => compareTo(other) > 0;

  /// Local wall-clock DateTime at [minutesOfDay] (defaults to midnight).
  DateTime toLocalDateTime([int minutesOfDay = 0]) =>
      DateTime(year, month, day, minutesOfDay ~/ 60, minutesOfDay % 60);

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  @override
  int compareTo(CivilDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// Formats minutes-of-day as `HH:mm` (24h, for storage and tests).
String formatMinutes24(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
