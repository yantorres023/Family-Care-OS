import 'package:flutter/widgets.dart';

import 'care_store.dart';

/// Makes the [CareStore] available to the widget tree and rebuilds
/// dependents when it changes.
class StoreScope extends InheritedNotifier<CareStore> {
  const StoreScope({super.key, required CareStore store, required super.child})
    : super(notifier: store);

  /// Subscribes [context] to store changes.
  static CareStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Reads without subscribing (use in callbacks).
  static CareStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
