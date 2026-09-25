import 'package:flutter/material.dart';

import '../../core/formatting.dart';
import '../../domain/permissions.dart';
import '../../domain/reminders.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';

/// Reminders, sharing, data rights, and the product boundary.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _osEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final enabled = await StoreScope.read(context).notificationsEnabled();
    if (mounted) setState(() => _osEnabled = enabled);
  }

  Future<void> _update(ReminderSettings s) async {
    await runAction(
      context,
      () => StoreScope.read(context).updateReminderSettings(s),
    );
  }

  Future<int?> _pickTime(int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  static String _leadLabel(int m) => switch (m) {
    0 => 'At the time',
    15 => '15 minutes before',
    60 => '1 hour before',
    120 => '2 hours before',
    1440 => 'The day before',
    _ => '$m minutes before',
  };

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final s = store.reminderSettings;
    final canEdit = store.can(Permission.editSettings);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (!canEdit)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Only the owner can change settings.'),
            ),
          const SectionHeader('Reminders'),
          if (_osEnabled == false)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.notifications_off_outlined,
                  color: theme.colorScheme.onErrorContainer,
                ),
                title: Text(
                  'Notifications are turned off',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                subtitle: Text(
                  'Baton still works — you just won\'t get reminders. You can '
                  'allow them in your phone\'s settings.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await store.requestNotificationPermission();
                    await _checkPermission();
                  },
                  child: const Text('Try again'),
                ),
              ),
            ),
          SwitchListTile(
            title: const Text('Remind me about my tasks'),
            subtitle: const Text('Only for things assigned to you.'),
            value: s.enabled,
            onChanged: canEdit ? (v) => _update(s.copyWith(enabled: v)) : null,
          ),
          ListTile(
            enabled: canEdit && s.enabled,
            title: const Text('For tasks with a time'),
            subtitle: Text(_leadLabel(s.leadMinutes)),
            onTap: () async {
              final v = await showDialog<int>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Remind me'),
                  children: [
                    for (final m in ReminderSettings.leadOptions)
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(_leadLabel(m)),
                        ),
                      ),
                  ],
                ),
              );
              if (v != null) await _update(s.copyWith(leadMinutes: v));
            },
          ),
          ListTile(
            enabled: canEdit && s.enabled,
            title: const Text('For tasks without a time'),
            subtitle: Text('On the day at ${formatTimeOfDay(s.allDayMinutes)}'),
            onTap: () async {
              final v = await _pickTime(s.allDayMinutes);
              if (v != null) await _update(s.copyWith(allDayMinutes: v));
            },
          ),
          SwitchListTile(
            title: const Text('Morning summary'),
            subtitle: Text(
              s.dailyDigest
                  ? 'Daily at ${formatTimeOfDay(s.dailyDigestMinutes)}, only '
                        'on days with something planned'
                  : 'Off',
            ),
            value: s.dailyDigest,
            onChanged: canEdit && s.enabled
                ? (v) => _update(s.copyWith(dailyDigest: v))
                : null,
          ),
          if (s.dailyDigest)
            ListTile(
              enabled: canEdit && s.enabled,
              title: const Text('Summary time'),
              subtitle: Text(formatTimeOfDay(s.dailyDigestMinutes)),
              onTap: () async {
                final v = await _pickTime(s.dailyDigestMinutes);
                if (v != null) await _update(s.copyWith(dailyDigestMinutes: v));
              },
            ),
          SwitchListTile(
            title: const Text('Hide details on lock screen'),
            subtitle: const Text(
              'Reminders say "Care reminder" instead of the task name.',
            ),
            value: s.privateLockScreen,
            onChanged: canEdit
                ? (v) => _update(s.copyWith(privateLockScreen: v))
                : null,
          ),
          const SectionHeader('Sharing'),
          SwitchListTile(
            title: const Text('Add "Sent with Baton" to updates'),
            value: store.shareFooter,
            onChanged: canEdit
                ? (v) => runAction(context, () => store.setShareFooter(v))
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.preview_outlined),
            title: const Text('Preview today\'s update'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Update preview'),
                content: SingleChildScrollView(
                  child: SelectableText(store.dailyUpdateText()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Your data'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Everything is stored only on this device. Baton has no '
              'account and no server. Nothing is sent anywhere unless you '
              'share it.',
            ),
          ),
          ListTile(
            enabled: store.can(Permission.exportData),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export all data'),
            subtitle: const Text('A JSON file you can keep or move.'),
            onTap: () => runAction(context, store.exportData),
          ),
          ListTile(
            enabled: store.can(Permission.deleteAllData),
            leading: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Delete all data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Removes everything from this device.'),
            onTap: () => _confirmDeleteAll(context),
          ),
          const SectionHeader('About'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(medicalBoundaryText),
          ),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Usage counts (on this device only)'),
            subtitle: const Text(
              'What Baton counts to learn what helps. Never sent anywhere.',
            ),
            onTap: () => _showCounts(context),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Baton',
            applicationVersion: '0.1.0 (MVP)',
            applicationLegalese:
                'Organisation and coordination only. Not medical advice.',
          ),
        ],
      ),
    );
  }

  Future<void> _showCounts(BuildContext context) async {
    final counts = await StoreScope.read(context).analytics.counts();
    if (!context.mounted) return;
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usage counts'),
        content: entries.isEmpty
            ? const Text('Nothing recorded yet.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final e in entries)
                      Row(
                        children: [
                          Expanded(child: Text(e.key)),
                          Text('${e.value}'),
                        ],
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final store = StoreScope.read(context);
    final controller = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Delete everything?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently removes all tasks, notes, people and '
                'history from this device. It cannot be undone. Consider '
                'exporting first.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Type DELETE to confirm',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (go == true && context.mounted) {
      final navigator = Navigator.of(context);
      final ok = await runAction(context, store.deleteAllData);
      if (ok) navigator.popUntil((r) => r.isFirst);
    }
  }
}
