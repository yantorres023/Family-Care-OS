import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../state/care_store.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';

/// Four short steps: welcome → who → helpers → first tasks.
/// Target: under two minutes to a useful Today screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _recipient = TextEditingController();
  final _me = TextEditingController();
  final _helper = TextEditingController();
  final _customTask = TextEditingController();
  final _helpers = <String>[];
  final _tasks = <String>{};
  final _customTasks = <String>[];
  bool _saving = false;

  @override
  void dispose() {
    _recipient.dispose();
    _me.dispose();
    _helper.dispose();
    _customTask.dispose();
    super.dispose();
  }

  String get _name =>
      _recipient.text.trim().isEmpty ? 'them' : _recipient.text.trim();

  void _addHelper() {
    final name = _helper.text.trim();
    if (name.isEmpty) return;
    final exists = _helpers.any((h) => h.toLowerCase() == name.toLowerCase());
    setState(() {
      if (!exists && name.length <= Limits.nameMax) _helpers.add(name);
      _helper.clear();
    });
  }

  void _addCustomTask() {
    final title = _customTask.text.trim();
    if (title.isEmpty || title.length > Limits.titleMax) return;
    setState(() {
      _customTasks.add(title);
      _tasks.add(title);
      _customTask.clear();
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final store = StoreScope.read(context);
    final ok = await runAction(
      context,
      () => store.setUp(
        careRecipientName: _recipient.text,
        myName: _me.text,
        helperNames: _helpers,
        starterTasks: _tasks.toList(),
      ),
    );
    if (!ok && mounted) setState(() => _saving = false);
  }

  bool get _canContinue => switch (_step) {
    1 => _recipient.text.trim().isNotEmpty && _me.text.trim().isNotEmpty,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final steps = [_welcome, _who, _helpersStep, _tasksStep];
    return Scaffold(
      appBar: _step == 0
          ? null
          : AppBar(
              leading: BackButton(onPressed: () => setState(() => _step--)),
              title: Text('Step $_step of 3'),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [steps[_step](context)],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: FilledButton(
            onPressed: !_canContinue || _saving
                ? null
                : () {
                    if (_step < 3) {
                      if (_step == 2) _addHelper();
                      setState(() => _step++);
                    } else {
                      _finish();
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(switch (_step) {
              0 => 'Get started',
              2 => _helpers.isEmpty ? 'Skip for now' : 'Continue',
              3 => _saving ? 'Setting up…' : 'Finish',
              _ => 'Continue',
            }),
          ),
        ),
      ),
    );
  }

  Widget _welcome(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.handshake_outlined,
          size: 56,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text('Baton', style: theme.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          'Know what needs doing for your parent today, who is on it, and '
          'what already happened.',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        const _Bullet(
          icon: Icons.checklist,
          text:
              'One shared list of tasks and appointments, each with an owner.',
        ),
        const _Bullet(
          icon: Icons.forum_outlined,
          text:
              'Send a clean update to your family group chat. Nobody else has '
              'to install anything.',
        ),
        const _Bullet(
          icon: Icons.sticky_note_2_outlined,
          text: 'Leave a quick note for whoever is next.',
        ),
        const _Bullet(
          icon: Icons.lock_outline,
          text: 'Everything stays on this phone. No account needed.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(medicalBoundaryText, style: theme.textTheme.bodySmall),
          ),
        ),
      ],
    );
  }

  Widget _who(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who are you caring for?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'A name or nickname is enough. You can include both parents, '
          'like "Mum & Dad".',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _recipient,
          autofocus: true,
          maxLength: Limits.nameMax,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Their name',
            hintText: 'e.g. Mom, Dad, Grandma Rosa',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text('And your name?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _me,
          maxLength: Limits.nameMax,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'Shown to others on shared updates',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _helpersStep(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who else helps $_name?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Siblings, a partner, a neighbour. Add their names so you can '
          'assign tasks. They don\'t need to install anything — you can share '
          'updates to your family chat.',
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _helper,
                maxLength: Limits.nameMax,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Name'),
                onSubmitted: (_) => _addHelper(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filledTonal(
                tooltip: 'Add helper',
                onPressed: _addHelper,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in _helpers)
              InputChip(
                label: Text(h),
                onDeleted: () => setState(() => _helpers.remove(h)),
                deleteButtonTooltipMessage: 'Remove $h',
              ),
          ],
        ),
      ],
    );
  }

  Widget _tasksStep(BuildContext context) {
    final theme = Theme.of(context);
    final options = [...starterTaskSuggestions, ..._customTasks];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What needs doing for $_name?',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a few to start. You can add dates, owners and repeats later.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in options)
              FilterChip(
                label: Text(t),
                selected: _tasks.contains(t),
                onSelected: (on) => setState(() {
                  on ? _tasks.add(t) : _tasks.remove(t);
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _customTask,
                maxLength: Limits.titleMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Something else'),
                onSubmitted: (_) => _addCustomTask(),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filledTonal(
                tooltip: 'Add task',
                onPressed: _addCustomTask,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
