import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/civil_date.dart';
import '../../core/formatting.dart';
import '../../domain/models.dart';
import '../../state/store_scope.dart';
import '../widgets/common.dart';
import 'home_shell.dart';
import 'item_detail_screen.dart';

/// "What changed?" — everything that happened, newest first.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _notesOnly = false;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = store.today;
    final events = store.timeline
        .where((e) => !_notesOnly || e.type == ActivityType.handoffAdded)
        .toList();

    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Everything')),
            ButtonSegment(value: true, label: Text('Notes only')),
          ],
          selected: {_notesOnly},
          onSelectionChanged: (s) => setState(() => _notesOnly = s.first),
        ),
      ),
    ];

    CivilDate? lastDay;
    for (final e in events) {
      final day = CivilDate.fromDateTime(e.createdAt);
      if (day != lastDay) {
        lastDay = day;
        children.add(
          SectionHeader(
            day == today || day == today.addDays(-1)
                ? formatRelativeDate(day, today)
                : DateFormat.MMMMEEEEd().format(e.createdAt),
          ),
        );
      }
      children.add(_EventTile(event: e));
    }
    if (events.isEmpty) {
      children.add(
        EmptyState(
          icon: Icons.history,
          title: _notesOnly ? 'No notes yet' : 'Nothing yet',
          message: 'Tasks you add, finish, or hand over will show up here.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: const [ActorButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: children,
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final actor = store.memberById(event.actorId);
    final time = DateFormat.jm().format(event.createdAt);
    final note = event.type == ActivityType.handoffAdded
        ? store.handoffById(event.handoffId)
        : null;
    final item = event.itemId == null ? null : store.itemById(event.itemId!);

    return MergeSemantics(
      child: ListTile(
        leading: actor == null
            ? Icon(_icon(event.type))
            : MemberAvatar(member: actor),
        title: Row(
          children: [
            Icon(_icon(event.type), size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(event.summary)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6, bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  note.body,
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            Text(time),
          ],
        ),
        onTap: item == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ItemDetailScreen(itemId: item.id),
                ),
              ),
      ),
    );
  }

  static IconData _icon(ActivityType t) => switch (t) {
    ActivityType.circleCreated => Icons.flag_outlined,
    ActivityType.itemCreated => Icons.add_circle_outline,
    ActivityType.itemEdited => Icons.edit_outlined,
    ActivityType.itemAssigned => Icons.pan_tool_outlined,
    ActivityType.itemUnassigned => Icons.person_search_outlined,
    ActivityType.itemCompleted => Icons.check_circle_outline,
    ActivityType.itemReopened => Icons.undo,
    ActivityType.itemDeleted => Icons.delete_outline,
    ActivityType.handoffAdded => Icons.sticky_note_2_outlined,
    ActivityType.memberAdded => Icons.person_add_alt,
    ActivityType.memberUpdated => Icons.manage_accounts_outlined,
    ActivityType.memberRemoved => Icons.person_remove_outlined,
    ActivityType.ownershipTransferred => Icons.key_outlined,
  };
}
