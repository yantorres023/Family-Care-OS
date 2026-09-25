import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// Local (on-device) reminders. No push server, no remote content.
abstract class NotificationService {
  Future<void> init();

  /// Asks the OS for permission. Returns whether reminders can be shown.
  Future<bool> requestPermission();

  /// Null when the platform can't tell.
  Future<bool?> areEnabled();

  /// Cancels all scheduled reminders and schedules exactly [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);

  Future<void> cancelAll();

  /// Item id (or empty for the digest) when the user taps a reminder.
  Stream<String> get opened;
}

/// Converts a wall-clock reminder to an instant in [location]. Times that
/// don't exist (spring-forward gap) resolve forward by the gap length, as
/// defined by package:timezone.
tz.TZDateTime zonedTimeFor(PlannedReminder r, tz.Location location) =>
    tz.TZDateTime(
      location,
      r.date.year,
      r.date.month,
      r.date.day,
      r.minutes ~/ 60,
      r.minutes % 60,
    );

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Reminders for things you have taken on.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    // Content is hidden on a secure lock screen regardless of our own
    // privacy setting.
    visibility: NotificationVisibility.private,
    category: AndroidNotificationCategory.reminder,
  );

  static const _details = NotificationDetails(
    android: _channel,
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Unknown zone id: fall back to UTC rather than failing to start.
      debugPrint('Time zone lookup failed: $e');
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested in context (after the first assignment to
        // me), never on launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _opened.add(response.payload ?? ''),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final payload = launch!.notificationResponse?.payload ?? '';
      // Deliver after listeners attach.
      scheduleMicrotask(() => _opened.add(payload));
    }
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool?> areEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final options = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options?.isEnabled;
    }
    return null;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    for (final r in reminders) {
      try {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: zonedTimeFor(r, tz.local),
          notificationDetails: _details,
          // Inexact: no SCHEDULE_EXACT_ALARM permission needed (Play policy
          // restricts it to alarm/calendar apps). A few minutes' drift is
          // acceptable for care reminders.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
          payload: r.itemId ?? '',
        );
      } catch (e) {
        // One bad reminder must not block the rest.
        debugPrint('Failed to schedule reminder ${r.id}: $e');
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  @override
  Stream<String> get opened => _opened.stream;
}

/// Records calls (tests, demo, platforms without notifications).
class FakeNotificationService implements NotificationService {
  List<PlannedReminder> scheduled = const [];
  bool permissionGranted = true;
  bool? enabled = true;
  int permissionRequests = 0;
  final _opened = StreamController<String>.broadcast();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = permissionGranted;
    return permissionGranted;
  }

  @override
  Future<bool?> areEnabled() async => enabled;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    scheduled = List.of(reminders);
  }

  @override
  Future<void> cancelAll() async => scheduled = const [];

  @override
  Stream<String> get opened => _opened.stream;

  void simulateOpen(String payload) => _opened.add(payload);
}
