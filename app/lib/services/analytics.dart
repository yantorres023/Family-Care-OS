import 'dart:async';
import 'dart:convert';

/// Product events (docs/product/ANALYTICS.md). All are hypotheses about what
/// signals value; none of them leave the device in the MVP.
enum AnalyticsEvent {
  familyCreated('family_created'),
  careProfileCreated('care_profile_created'),
  memberInvited('member_invited'),
  taskCreated('task_created'),
  taskAssigned('task_assigned'),
  taskCompleted('task_completed'),
  eventCreated('event_created'),
  handoffAdded('handoff_added'),
  timelineViewed('timeline_viewed'),
  notificationOpened('notification_opened'),
  updateShared('update_shared'),
  helpRequested('help_requested'),
  onboardingCompleted('onboarding_completed');

  const AnalyticsEvent(this.wireName);
  final String wireName;
}

/// Persistence for the on-device event log.
abstract class AnalyticsStore {
  Future<void> appendEvent(String name, String props, DateTime at);
  Future<Map<String, int>> eventCounts();
}

/// Rejects anything that could carry personal data: property values must
/// be booleans, small integers, or short snake_case tokens (enum names).
/// Free text (titles, names, notes) can therefore never be logged.
Map<String, Object> sanitizeProps(Map<String, Object> props) {
  final token = RegExp(r'^[a-z0-9_]{1,32}$');
  final clean = <String, Object>{};
  props.forEach((key, value) {
    if (!token.hasMatch(key)) return;
    if (value is bool) {
      clean[key] = value;
    } else if (value is int && value.abs() < 1000000) {
      clean[key] = value;
    } else if (value is String && token.hasMatch(value)) {
      clean[key] = value;
    }
  });
  return clean;
}

abstract class Analytics {
  void track(AnalyticsEvent event, [Map<String, Object> props = const {}]);
  Future<Map<String, int>> counts();
}

/// Stores events locally only. No network, no identifiers.
class LocalAnalytics implements Analytics {
  LocalAnalytics(this._store, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AnalyticsStore _store;
  final DateTime Function() _now;

  @override
  void track(AnalyticsEvent event, [Map<String, Object> props = const {}]) {
    final encoded = jsonEncode(sanitizeProps(props));
    // Fire-and-forget: analytics must never break or slow a user action.
    unawaited(
      _store
          .appendEvent(event.wireName, encoded, _now())
          .catchError((Object _) {}),
    );
  }

  @override
  Future<Map<String, int>> counts() => _store.eventCounts();
}

/// In-memory analytics for tests and demo mode.
class MemoryAnalytics implements Analytics {
  final events = <(AnalyticsEvent, Map<String, Object>)>[];

  @override
  void track(AnalyticsEvent event, [Map<String, Object> props = const {}]) {
    events.add((event, sanitizeProps(props)));
  }

  @override
  Future<Map<String, int>> counts() async {
    final result = <String, int>{};
    for (final (e, _) in events) {
      result.update(e.wireName, (n) => n + 1, ifAbsent: () => 1);
    }
    return result;
  }

  int count(AnalyticsEvent e) => events.where((x) => x.$1 == e).length;
}
