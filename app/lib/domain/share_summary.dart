import 'package:intl/intl.dart';

import '../core/civil_date.dart';
import '../core/formatting.dart';
import 'models.dart';
import 'today.dart';

/// Plain-text updates for pasting into the family group chat.
///
/// Privacy: item notes are never included; only titles, times, places for
/// appointments, and who is on it. The user sees the text in the system share
/// sheet before it goes anywhere.
class ShareSummary {
  const ShareSummary({this.includeFooter = true});

  final bool includeFooter;

  static const footer = 'Sent with Baton';
  static const maxItemsPerSection = 10;

  String dailyUpdate({
    required Circle circle,
    required CivilDate today,
    required Iterable<CareItem> items,
    required Map<String, Member> membersById,
    HandoffNote? latestHandoff,
  }) {
    final view = TodayView.build(items, today);
    final buf = StringBuffer();
    final dateLabel = DateFormat.MMMEd().format(today.toLocalDateTime());
    buf.writeln('${circle.careRecipientName} — update for $dateLabel');

    void section(String heading, List<CareItem> list, {bool showDate = false}) {
      if (list.isEmpty) return;
      buf
        ..writeln()
        ..writeln(heading);
      for (final item in list.take(maxItemsPerSection)) {
        buf.writeln('• ${_line(item, today, membersById, showDate: showDate)}');
      }
      final hidden = list.length - maxItemsPerSection;
      if (hidden > 0) buf.writeln('  …and $hidden more');
    }

    section('OVERDUE', view.overdue, showDate: true);
    section('TODAY', view.today);
    section('COMING UP', view.upcoming, showDate: true);

    if (view.doneToday.isNotEmpty) {
      buf
        ..writeln()
        ..writeln('DONE TODAY');
      for (final item in view.doneToday.take(maxItemsPerSection)) {
        final who = membersById[item.completedById]?.name;
        buf.writeln('✓ ${item.title}${who == null ? '' : ' — $who'}');
      }
    }

    if (view.isEmpty) {
      buf
        ..writeln()
        ..writeln('Nothing scheduled for the next week.');
    }

    if (latestHandoff != null) {
      final author = membersById[latestHandoff.authorId]?.name ?? 'Someone';
      final when = formatTimestamp(latestHandoff.createdAt, today);
      buf
        ..writeln()
        ..writeln('NOTE FROM $author ($when)')
        ..writeln(latestHandoff.body.trim());
    }

    if (view.needsSomeone.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(
          view.needsSomeone.length == 1
              ? '1 thing still needs someone — can you take it?'
              : '${view.needsSomeone.length} things still need someone — can you take one?',
        );
    }

    if (includeFooter) {
      buf
        ..writeln()
        ..write('— $footer');
    }
    return buf.toString().trimRight();
  }

  /// A request for help with one unassigned item.
  String askForHelp({
    required Circle circle,
    required CareItem item,
    required CivilDate today,
  }) {
    final buf = StringBuffer()
      ..writeln('Can someone help with this for ${circle.careRecipientName}?')
      ..writeln()
      ..writeln('• ${item.title}');
    if (item.dueDate != null) {
      buf.writeln('  ${formatDue(item.dueDate, item.dueMinutes, today)}');
    }
    if (item.kind == ItemKind.appointment && item.location.trim().isNotEmpty) {
      buf.writeln('  ${item.location.trim()}');
    }
    buf
      ..writeln()
      ..write('Reply here if you can take it.');
    if (includeFooter) {
      buf
        ..writeln()
        ..writeln()
        ..write('— $footer');
    }
    return buf.toString();
  }

  String _line(
    CareItem item,
    CivilDate today,
    Map<String, Member> membersById, {
    required bool showDate,
  }) {
    final parts = <String>[];
    if (showDate && item.dueDate != null) {
      parts.add(formatDue(item.dueDate, item.dueMinutes, today));
    } else if (item.dueMinutes != null) {
      parts.add(formatTimeOfDay(item.dueMinutes!));
    }
    var text = parts.isEmpty ? item.title : '${parts.join(' ')}: ${item.title}';
    if (item.kind == ItemKind.appointment && item.location.trim().isNotEmpty) {
      text += ' (${item.location.trim()})';
    }
    final owner = membersById[item.assigneeId];
    text += owner == null ? ' — needs someone' : ' — ${owner.name}';
    if (item.important) text = '❗ $text';
    return text;
  }
}
