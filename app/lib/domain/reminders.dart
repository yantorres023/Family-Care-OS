import '../core/civil_date.dart';
import '../core/formatting.dart';
import 'models.dart';

/// User-controlled notification preferences. Quiet, private defaults.
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.leadMinutes = 60,
    this.allDayMinutes = 9 * 60,
    this.privateLockScreen = true,
    this.dailyDigest = false,
    this.dailyDigestMinutes = 8 * 60,
  });

  /// Master switch for reminders on this device.
  final bool enabled;

  /// How long before a timed item to remind (0 = at the time).
  final int leadMinutes;

  /// When to remind about items with a date but no time.
  final int allDayMinutes;

  /// Hide task titles and names in notification text (default on).
  final bool privateLockScreen;

  /// A morning summary of today's items.
  final bool dailyDigest;
  final int dailyDigestMinutes;

  static const leadOptions = [0, 15, 60, 120, 24 * 60];

  ReminderSettings copyWith({
    bool? enabled,
    int? leadMinutes,
    int? allDayMinutes,
    bool? privateLockScreen,
    bool? dailyDigest,
    int? dailyDigestMinutes,
  }) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    leadMinutes: leadMinutes ?? this.leadMinutes,
    allDayMinutes: allDayMinutes ?? this.allDayMinutes,
    privateLockScreen: privateLockScreen ?? this.privateLockScreen,
    dailyDigest: dailyDigest ?? this.dailyDigest,
    dailyDigestMinutes: dailyDigestMinutes ?? this.dailyDigestMinutes,
  );

  Map<String, String> toMap() => {
    'reminders.enabled': '$enabled',
    'reminders.leadMinutes': '$leadMinutes',
    'reminders.allDayMinutes': '$allDayMinutes',
    'reminders.private': '$privateLockScreen',
    'reminders.digest': '$dailyDigest',
    'reminders.digestMinutes': '$dailyDigestMinutes',
  };

  factory ReminderSettings.fromMap(Map<String, String> map) {
    const d = ReminderSettings();
    bool b(String k, bool fallback) =>
        map[k] == null ? fallback : map[k] == 'true';
    int i(String k, int fallback, {int min = 0, int max = 24 * 60}) {
      final v = int.tryParse(map[k] ?? '');
      if (v == null || v < min || v > max) return fallback;
      return v;
    }

    return ReminderSettings(
      enabled: b('reminders.enabled', d.enabled),
      leadMinutes: i('reminders.leadMinutes', d.leadMinutes),
      allDayMinutes: i(
        'reminders.allDayMinutes',
        d.allDayMinutes,
        max: 24 * 60 - 1,
      ),
      privateLockScreen: b('reminders.private', d.privateLockScreen),
      dailyDigest: b('reminders.digest', d.dailyDigest),
      dailyDigestMinutes: i(
        'reminders.digestMinutes',
        d.dailyDigestMinutes,
        max: 24 * 60 - 1,
      ),
    );
  }
}

/// A notification to schedule at a local wall-clock time.
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.date,
    required this.minutes,
    required this.title,
    required this.body,
    this.itemId,
  });

  final int id;
  final CivilDate date;
  final int minutes;
  final String title;
  final String body;

  /// Null for the daily digest.
  final String? itemId;

  DateTime get localDateTime => date.toLocalDateTime(minutes);

  @override
  String toString() =>
      'PlannedReminder($id, ${date.toIso()} ${formatMinutes24(minutes)}, $title)';
}

/// Decides which local notifications should exist. Pure; the notification
/// service cancels everything and schedules exactly this list.
class ReminderPlanner {
  const ReminderPlanner();

  /// iOS allows 64 pending local notifications per app; stay well below.
  static const maxReminders = 48;
  static const horizonDays = 30;
  static const digestDays = 7;

  List<PlannedReminder> plan({
    required Iterable<CareItem> items,
    required String? meId,
    required ReminderSettings settings,
    required DateTime now,
    required String careRecipientName,
  }) {
    if (!settings.enabled) return const [];
    final today = CivilDate.fromDateTime(now);
    final horizon = today.addDays(horizonDays);
    final candidates = <({CivilDate date, int minutes, CareItem item})>[];

    for (final item in items) {
      if (item.isDeleted || !item.isOpen) continue;
      if (meId == null || item.assigneeId != meId) continue;
      final due = item.dueDate;
      if (due == null) continue;

      var date = due;
      int minutes;
      if (item.dueMinutes != null) {
        minutes = item.dueMinutes! - settings.leadMinutes;
        while (minutes < 0) {
          minutes += 24 * 60;
          date = date.addDays(-1);
        }
      } else {
        minutes = settings.allDayMinutes;
      }
      if (!date.toLocalDateTime(minutes).isAfter(now)) continue;
      if (date.isAfter(horizon)) continue;
      candidates.add((date: date, minutes: minutes, item: item));
    }

    candidates.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.minutes.compareTo(b.minutes);
    });

    final digestSlots = settings.dailyDigest ? digestDays : 0;
    final result = <PlannedReminder>[];
    var nextId = 1;
    for (final c in candidates.take(maxReminders - digestSlots)) {
      result.add(
        PlannedReminder(
          id: nextId++,
          date: c.date,
          minutes: c.minutes,
          title: settings.privateLockScreen ? 'Care reminder' : c.item.title,
          // Relative wording ("Today", "Tomorrow") is computed against the
          // day the notification fires, not the day it was planned.
          body: _itemBody(c.item, settings, careRecipientName, c.date),
          itemId: c.item.id,
        ),
      );
    }

    if (settings.dailyDigest) {
      final open = items.where((i) => !i.isDeleted && i.isOpen).toList();
      for (var d = 0; d < digestDays; d++) {
        final date = today.addDays(d);
        final minutes = settings.dailyDigestMinutes;
        if (!date.toLocalDateTime(minutes).isAfter(now)) continue;
        final dueThatDay = open.where((i) => i.dueDate == date).toList();
        if (dueThatDay.isEmpty) continue;
        final unassigned = dueThatDay.where((i) => i.assigneeId == null).length;
        final count = dueThatDay.length;
        final things = count == 1 ? '1 thing' : '$count things';
        final String body;
        if (settings.privateLockScreen) {
          body = '$things planned today.';
        } else {
          body =
              '$things planned for $careRecipientName today'
              '${unassigned > 0 ? ' — $unassigned need${unassigned == 1 ? 's' : ''} someone' : ''}.';
        }
        result.add(
          PlannedReminder(
            id: nextId++,
            date: date,
            minutes: minutes,
            title: 'Today',
            body: body,
          ),
        );
      }
    }
    return result;
  }

  String _itemBody(
    CareItem item,
    ReminderSettings settings,
    String careRecipientName,
    CivilDate fireDate,
  ) {
    final when = formatDue(item.dueDate, item.dueMinutes, fireDate);
    if (settings.privateLockScreen) {
      return item.kind == ItemKind.appointment
          ? 'You have an appointment: $when. Open Baton for details.'
          : 'You have something due: $when. Open Baton for details.';
    }
    return '$when · for $careRecipientName';
  }
}
