import 'package:family_care/core/clock.dart';
import 'package:family_care/data/in_memory_care_repository.dart';
import 'package:family_care/services/analytics.dart';
import 'package:family_care/services/notification_service.dart';
import 'package:family_care/services/share_service.dart';
import 'package:family_care/state/care_store.dart';

class Harness {
  Harness({DateTime? now, InMemoryCareRepository? repo})
    : clock = FixedClock(now ?? DateTime(2026, 9, 25, 9)),
      repo = repo ?? InMemoryCareRepository() {
    store = CareStore(
      repository: this.repo,
      notifications: notifications,
      analytics: analytics,
      share: share,
      clock: clock,
    );
  }

  final FixedClock clock;
  final InMemoryCareRepository repo;
  final notifications = FakeNotificationService();
  final analytics = MemoryAnalytics();
  final share = RecordingShareService();
  late final CareStore store;

  /// Loads and sets up "Mom" with me (Ana, owner) and helpers Luis, Sam.
  Future<CareStore> ready({
    List<String> helpers = const ['Luis', 'Sam'],
    List<String> tasks = const [],
  }) async {
    await store.load();
    await store.setUp(
      careRecipientName: 'Mom',
      myName: 'Ana',
      helperNames: helpers,
      starterTasks: tasks,
    );
    return store;
  }

  String idOf(String name) =>
      store.allMembers.firstWhere((m) => m.name == name).id;
}
