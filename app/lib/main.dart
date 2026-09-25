import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/sqlite_care_repository.dart';
import 'services/analytics.dart';
import 'services/notification_service.dart';
import 'services/share_service.dart';
import 'state/care_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initLocale();

  final dbPath = p.join(await getDatabasesPath(), 'baton.db');
  final repo = await SqliteCareRepository.open(databaseFactory, dbPath);
  final notifications = LocalNotificationService();
  try {
    await notifications.init();
  } catch (e) {
    // Reminders are optional; the app must still start.
    debugPrint('Notifications unavailable: $e');
  }

  final store = CareStore(
    repository: repo,
    notifications: notifications,
    analytics: LocalAnalytics(repo),
    share: const SystemShareService(),
  );
  runApp(BatonApp(store: store));
  unawaited(store.load());
}

/// Date/time formats follow the device locale (e.g. 24h clock in the UK).
Future<void> _initLocale() async {
  final device = WidgetsBinding.instance.platformDispatcher.locale;
  final tag = Intl.canonicalizedLocale(device.toLanguageTag());
  try {
    await initializeDateFormatting(tag);
    Intl.defaultLocale = tag;
  } catch (_) {
    await initializeDateFormatting('en_US');
    Intl.defaultLocale = 'en_US';
  }
}
