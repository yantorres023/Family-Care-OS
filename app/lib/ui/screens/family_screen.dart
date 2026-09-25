import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../domain/permissions.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import 'home_shell.dart';
import 'settings_screen.dart';

/// The circle: who helps, what each person holds, and settings.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final circle = store.circle!;
    final canManage = store.can(Permission.manageMembers);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          const ActorButton(),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: Text('Caring for ${circle.careRecipientName}'),
              subtitle: Text(
                '${store.activeMembers.length} '
                '${store.activeMembers.length == 1 ? 'person' : 'people'} '
                'helping',
              ),
              trailing: canManage
                  ? IconButton(
                      tooltip: 'Rename',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final name = await _askName(
                          context,
                          title: 'Who are you caring for?',
                          initial: circle.careRecipientName,
                        );
                        if (name != null && context.mounted) {
                          await runAction(
                            context,
                            () => store.renameCareRecipient(name),
                          );
                        }
                      },
                    )
                  : null,
            ),
          ),
          const SectionHeader('People'),
          for (final m in store.activeMembers)
            ListTile(
              leading: MemberAvatar(member: m),
              title: Text(m.isDeviceOwner ? '${m.name} (me)' : m.name),
              subtitle: Text(
                '${m.role.label} · ${_count(store.itemsAssignedTo(m.id).length)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MemberScreen(memberId: m.id),
                ),
              ),
            ),
          if (canManage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final name = await _askName(context, title: 'Add a helper');
                  if (name != null && context.mounted) {
                    await runAction(
                      context,
                      () => store.addMember(name),
                      success: 'Added $name.',
                    );
                  }
                },
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Add a helper'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How the family stays in the loop',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Helpers don\'t need the app. Use "Send update" on '
                    'Today to post the plan in your family chat.\n'
                    '• On a shared phone or tablet (for example at your '
                    'parent\'s home), tap the avatar at the top to switch '
                    'who is using Baton.\n'
                    '• Baton does not sync between phones yet. Everything '
                    'stays on this device.',
                  ),
                ],
              ),
            ),
          ),
          if (store.activeMembers.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextButton.icon(
                onPressed: () => showActorSwitcher(context),
                icon: const Icon(Icons.switch_account_outlined),
                label: Text('Using Baton as ${store.actor?.name}. Switch'),
              ),
            ),
        ],
      ),
    );
  }

  static String _count(int n) => n == 0
      ? 'nothing assigned'
      : n == 1
      ? '1 open task'
      : '$n open tasks';
}

Future<String?> _askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: Limits.nameMax,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

/// One person: their open tasks and (if permitted) management actions.
class MemberScreen extends StatelessWidget {
  const MemberScreen({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final m = store.memberById(memberId);
    if (m == null || !m.isActive) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'No longer in the circle',
          message: 'Their past activity is still on the timeline.',
        ),
      );
    }
    final actor = store.actor;
    final items = store.itemsAssignedTo(m.id);
    final canRename = actor?.id == m.id || store.can(Permission.manageMembers);
    final canRemove = store.policy.canRemoveMember(actor, m);
    final canTransfer = store.policy.canTransferOwnership(actor, m);
    final roleOptions = [
      Role.viewer,
      Role.member,
      Role.coordinator,
    ].where((r) => store.policy.canChangeRole(actor, m, r)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(m.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: MemberAvatar(member: m, radius: 24),
            title: Text(m.name, style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text('${m.role.label}. ${m.role.description}'),
          ),
          SectionHeader('Doing', count: items.length),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Nothing assigned right now.'),
            ),
          for (final i in items) ItemTile(item: i),
          if (canRename || roleOptions.isNotEmpty || canRemove || canTransfer)
            const SectionHeader('Manage'),
          if (canRename)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Change name'),
              onTap: () async {
                final name = await _askName(
                  context,
                  title: 'Change name',
                  initial: m.name,
                );
                if (name != null && context.mounted) {
                  await runAction(
                    context,
                    () => store.renameMember(m.id, name),
                  );
                }
              },
            ),
          if (roleOptions.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Role'),
              subtitle: Text(m.role.label),
              onTap: () => _pickRole(context, m, roleOptions),
            ),
          if (canTransfer)
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('Make owner'),
              subtitle: const Text('You will become a coordinator.'),
              onTap: () async {
                final go = await confirm(
                  context,
                  title: 'Make ${m.name} the owner?',
                  message:
                      'The owner can change roles and delete all data. '
                      'You will become a coordinator.',
                  confirmLabel: 'Make owner',
                );
                if (go && context.mounted) {
                  await runAction(context, () => store.transferOwnership(m.id));
                }
              },
            ),
          if (canRemove)
            ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Remove from circle',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                final go = await confirm(
                  context,
                  title: 'Remove ${m.name}?',
                  message: items.isEmpty
                      ? 'Their past activity stays on the timeline.'
                      : '${items.length} open '
                            '${items.length == 1 ? 'task' : 'tasks'} will be '
                            'marked "Needs someone". Their past activity '
                            'stays on the timeline.',
                  confirmLabel: 'Remove',
                  destructive: true,
                );
                if (!go || !context.mounted) return;
                final ok = await runAction(
                  context,
                  () => store.removeMember(m.id),
                  success: '${m.name} was removed.',
                );
                if (ok && context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickRole(
    BuildContext context,
    Member m,
    List<Role> options,
  ) async {
    final store = StoreScope.read(context);
    final role = await showDialog<Role>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Role for ${m.name}'),
        children: [
          RadioGroup<Role>(
            groupValue: m.role,
            onChanged: (r) => Navigator.pop(context, r),
            child: Column(
              children: [
                for (final r in options)
                  RadioListTile<Role>(
                    value: r,
                    title: Text(r.label),
                    subtitle: Text(r.description),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (role != null && role != m.role && context.mounted) {
      await runAction(context, () => store.changeRole(m.id, role));
    }
  }
}
