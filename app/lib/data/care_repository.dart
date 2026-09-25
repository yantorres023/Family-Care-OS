import '../domain/models.dart';

/// Everything stored for the (single) care circle on this device.
class CareSnapshot {
  const CareSnapshot({
    this.circle,
    this.members = const [],
    this.items = const [],
    this.handoffs = const [],
    this.activity = const [],
    this.settings = const {},
  });

  final Circle? circle;
  final List<Member> members;

  /// Includes soft-deleted items (tombstones).
  final List<CareItem> items;
  final List<HandoffNote> handoffs;
  final List<ActivityEvent> activity;
  final Map<String, String> settings;
}

/// A group of writes applied atomically.
class ChangeSet {
  ChangeSet();

  Circle? circle;
  final members = <Member>[];
  final items = <CareItem>[];
  final handoffs = <HandoffNote>[];
  final activity = <ActivityEvent>[];
  final settings = <String, String>{};

  bool get isEmpty =>
      circle == null &&
      members.isEmpty &&
      items.isEmpty &&
      handoffs.isEmpty &&
      activity.isEmpty &&
      settings.isEmpty;
}

/// Storage boundary. The MVP ships a local SQLite implementation; a future
/// cloud-sync implementation must satisfy the same contract
/// (test/data/repository_contract.dart).
abstract class CareRepository {
  Future<CareSnapshot> load();

  /// Upserts everything in [changes] in one transaction.
  Future<void> apply(ChangeSet changes);

  /// Deletes every row on this device.
  Future<void> wipe();

  Future<void> close();
}
