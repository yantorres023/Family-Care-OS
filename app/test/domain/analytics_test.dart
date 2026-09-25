import 'package:family_care/services/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizeProps drops anything that could be free text', () {
    final clean = sanitizeProps({
      'recurring': true,
      'count': 3,
      'method': 'local_name',
      'title': 'Pick up Mom\'s pills',
      'name': 'Ana',
      'Bad Key': 'x',
      'huge': 99999999,
    });
    expect(clean, {'recurring': true, 'count': 3, 'method': 'local_name'});
  });

  test('event wire names match the analytics spec', () {
    expect(
      AnalyticsEvent.values.map((e) => e.wireName),
      containsAll([
        'family_created',
        'care_profile_created',
        'member_invited',
        'task_created',
        'task_assigned',
        'task_completed',
        'event_created',
        'handoff_added',
        'timeline_viewed',
        'notification_opened',
      ]),
    );
  });

  test('MemoryAnalytics counts', () async {
    final a = MemoryAnalytics()
      ..track(AnalyticsEvent.taskCreated)
      ..track(AnalyticsEvent.taskCreated);
    expect(await a.counts(), {'task_created': 2});
  });
}
