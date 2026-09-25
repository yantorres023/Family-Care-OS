import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../state/care_store.dart';
import '../theme.dart';

/// Runs a store command and reports failures in a SnackBar.
/// Returns true on success.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await action();
    if (success != null) {
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } on CareException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    debugPrint('Action failed: $e');
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Nothing was changed.'),
      ),
    );
  }
  return false;
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 18});

  final Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = memberColor(member.colorIndex);
    return Semantics(
      label: member.name,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text(
          member.initials,
          style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w600),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.count, this.icon});

  final String title;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: style?.color),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                count == null ? title : '$title ($count)',
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// The coordination-not-medical boundary, shown in onboarding and About.
const medicalBoundaryText =
    'Baton helps families organise who does what. It is not a medical '
    'service and does not give medical advice. For health questions, '
    'contact a doctor or pharmacist. In an emergency, call your local '
    'emergency number.';
