import 'package:flutter/material.dart';

import '../../core/civil_date.dart';
import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../domain/permissions.dart';
import '../../state/care_store.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';

/// Create or edit a task/appointment.
class ItemEditorScreen extends StatefulWidget {
  const ItemEditorScreen({super.key, this.itemId});

  /// Null to create.
  final String? itemId;

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _location = TextEditingController();
  ItemKind _kind = ItemKind.task;
  CivilDate? _date;
  int? _minutes;
  Recurrence _recurrence = Recurrence.none;
  String? _assignee;
  bool _important = false;
  bool _initialised = false;
  bool _saving = false;

  bool get _isEdit => widget.itemId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final store = StoreScope.read(context);
    final existing = _isEdit ? store.itemById(widget.itemId!) : null;
    if (existing != null) {
      _title.text = existing.title;
      _notes.text = existing.notes;
      _location.text = existing.location;
      _kind = existing.kind;
      _date = existing.dueDate;
      _minutes = existing.dueMinutes;
      _recurrence = existing.recurrence;
      _assignee = existing.assigneeId;
      _important = existing.important;
    } else {
      _date = store.today;
      // Helpers default to taking what they add; coordinators leave it open.
      final actor = store.actor;
      if (actor != null && actor.role == Role.member) _assignee = actor.id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _location.dispose();
    super.dispose();
  }

  ItemDraft get _draft => ItemDraft(
    title: _title.text,
    kind: _kind,
    notes: _notes.text,
    location: _location.text,
    assigneeId: _assignee,
    dueDate: _date,
    dueMinutes: _date == null ? null : _minutes,
    recurrence: _date == null ? Recurrence.none : _recurrence,
    important: _important,
  );

  Future<void> _save() async {
    final store = StoreScope.read(context);
    final draft = _draft;
    if (draft.title.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add a title.')));
      return;
    }
    final dup = store.findDuplicate(draft, ignoreId: widget.itemId);
    if (dup != null) {
      final go = await confirm(
        context,
        title: 'Already on the list?',
        message:
            '"${dup.title}" is already planned for '
            '${formatDue(dup.dueDate, dup.dueMinutes, store.today)}. '
            'Add it anyway?',
        confirmLabel: 'Add anyway',
      );
      if (!go || !mounted) return;
    }
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => _isEdit
          ? store.updateItem(widget.itemId!, draft)
          : store.createItem(draft),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final store = StoreScope.read(context);
    final initial = (_date ?? store.today).toLocalDateTime();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(store.now.year - 1),
      lastDate: DateTime(store.now.year + 5),
    );
    if (picked != null) setState(() => _date = CivilDate.fromDateTime(picked));
  }

  Future<void> _pickTime() async {
    final m = _minutes ?? 9 * 60;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = store.today;
    final actor = store.actor;
    final existing = _isEdit ? store.itemById(widget.itemId!) : null;
    final isCoordinator =
        actor != null && actor.role.index >= Role.coordinator.index;
    // Helpers can pick themselves or "needs someone" (plus keep whoever
    // already holds an item they're editing).
    final assignable = store.activeMembers
        .where(
          (m) =>
              isCoordinator ||
              m.id == actor?.id ||
              m.id == existing?.assigneeId,
        )
        .toList();
    final canSave = _isEdit
        ? existing != null && store.can(Permission.editItem, item: existing)
        : store.can(Permission.createItem);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit' : 'New ${_kind.label.toLowerCase()}'),
        actions: [
          TextButton(
            onPressed: _saving || !canSave ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ItemKind>(
              segments: const [
                ButtonSegment(
                  value: ItemKind.task,
                  label: Text('Task'),
                  icon: Icon(Icons.check_box_outlined),
                ),
                ButtonSegment(
                  value: ItemKind.appointment,
                  label: Text('Appointment'),
                  icon: Icon(Icons.event_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              autofocus: !_isEdit,
              maxLength: Limits.titleMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: _kind == ItemKind.appointment
                    ? 'What is the appointment?'
                    : 'What needs doing?',
                hintText: _kind == ItemKind.appointment
                    ? 'e.g. Eye check-up, hair salon'
                    : 'e.g. Pick up groceries',
              ),
            ),
            const SizedBox(height: 8),
            _SectionLabel('When'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: _date == today,
                  onSelected: (_) => setState(() => _date = today),
                ),
                ChoiceChip(
                  label: const Text('Tomorrow'),
                  selected: _date == today.addDays(1),
                  onSelected: (_) => setState(() => _date = today.addDays(1)),
                ),
                ChoiceChip(
                  label: const Text('No date'),
                  selected: _date == null,
                  onSelected: (_) => setState(() => _date = null),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _date == null || _date == today || _date == today.addDays(1)
                        ? 'Pick date'
                        : formatRelativeDate(_date!, today),
                  ),
                  onPressed: _pickDate,
                ),
              ],
            ),
            if (_date != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        _minutes == null
                            ? 'Add a time (optional)'
                            : formatTimeOfDay(_minutes!),
                      ),
                    ),
                  ),
                  if (_minutes != null)
                    IconButton(
                      tooltip: 'Remove time',
                      onPressed: () => setState(() => _minutes = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Recurrence>(
                initialValue: _recurrence,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: [
                  for (final r in Recurrence.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (r) =>
                    setState(() => _recurrence = r ?? Recurrence.none),
              ),
            ],
            _SectionLabel("Who's doing it"),
            DropdownButtonFormField<String?>(
              initialValue: assignable.any((m) => m.id == _assignee)
                  ? _assignee
                  : null,
              decoration: const InputDecoration(labelText: 'Person'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Needs someone'),
                ),
                for (final m in assignable)
                  DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text(m.id == actor?.id ? '${m.name} (me)' : m.name),
                  ),
              ],
              onChanged: (v) => setState(() => _assignee = v),
            ),
            if (_kind == ItemKind.appointment) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _location,
                maxLength: Limits.locationMax,
                decoration: const InputDecoration(
                  labelText: 'Where (optional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLength: Limits.notesMax,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
                helperText:
                    'Practical details only — e.g. "use the side door". '
                    'Avoid medical details.',
                helperMaxLines: 2,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Important'),
              subtitle: const Text('Shown first and marked with ❗'),
              value: _important,
              onChanged: (v) => setState(() => _important = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
