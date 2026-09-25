import 'package:flutter/material.dart';

import '../../domain/handoff_suggestion.dart';
import '../../domain/models.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';

/// "What should the next person know?" — a short note, optionally drafted
/// from today's activity.
class HandoffEditorScreen extends StatefulWidget {
  const HandoffEditorScreen({super.key});

  @override
  State<HandoffEditorScreen> createState() => _HandoffEditorScreenState();
}

class _HandoffEditorScreenState extends State<HandoffEditorScreen> {
  final _body = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  void _draft() {
    final store = StoreScope.read(context);
    final text = suggestHandoff(store.todayView, store.membersById);
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing happened today to summarise.')),
      );
      return;
    }
    setState(() {
      _body.text = _body.text.trim().isEmpty
          ? text
          : '${_body.text.trim()}\n$text';
      _body.selection = TextSelection.collapsed(offset: _body.text.length);
    });
  }

  Future<void> _save() async {
    final store = StoreScope.read(context);
    setState(() => _saving = true);
    final ok = await runAction(
      context,
      () => store.addHandoff(_body.text),
      success: 'Note saved.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final name = store.circle!.careRecipientName;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note for the next person'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'What should the next person know about $name?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'For example: "Mom already went to the appointment. '
              'Prescription pickup still pending. Groceries delivered."',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                label: const Text('Start from today\'s list'),
                tooltip: 'Fill in what was done and what is still pending',
                onPressed: _draft,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              autofocus: true,
              minLines: 5,
              maxLines: 12,
              maxLength: Limits.handoffMax,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Note from ${store.actor?.name ?? 'me'}',
                alignLabelWithHint: true,
                helperText:
                    'Keep it practical. Avoid medical details or diagnoses.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
