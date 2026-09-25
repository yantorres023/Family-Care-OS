import '../domain/models.dart';
import 'care_repository.dart';

/// Non-persistent repository for tests, previews and demo mode.
class InMemoryCareRepository implements CareRepository {
  InMemoryCareRepository([CareSnapshot? seed]) {
    if (seed != null) {
      _circle = seed.circle;
      for (final m in seed.members) {
        _members[m.id] = m;
      }
      for (final i in seed.items) {
        _items[i.id] = i;
      }
      for (final h in seed.handoffs) {
        _handoffs[h.id] = h;
      }
      for (final a in seed.activity) {
        _activity[a.id] = a;
      }
      _settings.addAll(seed.settings);
    }
  }

  Circle? _circle;
  final _members = <String, Member>{};
  final _items = <String, CareItem>{};
  final _handoffs = <String, HandoffNote>{};
  final _activity = <String, ActivityEvent>{};
  final _settings = <String, String>{};

  /// Set to make the next [apply] throw (for error-path tests).
  Object? failNextApply;

  @override
  Future<CareSnapshot> load() async => CareSnapshot(
    circle: _circle,
    members: _members.values.toList(),
    items: _items.values.toList(),
    handoffs: _handoffs.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    activity: _activity.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    settings: Map.of(_settings),
  );

  @override
  Future<void> apply(ChangeSet changes) async {
    final failure = failNextApply;
    if (failure != null) {
      failNextApply = null;
      throw failure;
    }
    if (changes.circle != null) _circle = changes.circle;
    for (final m in changes.members) {
      _members[m.id] = m;
    }
    for (final i in changes.items) {
      _items[i.id] = i;
    }
    for (final h in changes.handoffs) {
      _handoffs[h.id] = h;
    }
    for (final a in changes.activity) {
      _activity[a.id] = a;
    }
    _settings.addAll(changes.settings);
  }

  @override
  Future<void> wipe() async {
    _circle = null;
    _members.clear();
    _items.clear();
    _handoffs.clear();
    _activity.clear();
    _settings.clear();
  }

  @override
  Future<void> close() async {}
}
