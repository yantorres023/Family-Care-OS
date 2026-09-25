import 'package:family_care/domain/models.dart';
import 'package:family_care/domain/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  const policy = PermissionPolicy();
  final owner = member('o', 'Olivia', role: Role.owner, deviceOwner: true);
  final coord = member('c', 'Cam', role: Role.coordinator);
  final coord2 = member('c2', 'Cleo', role: Role.coordinator);
  final helper = member('h', 'Hal');
  final viewer = member('v', 'Vic', role: Role.viewer);
  final removed = member('r', 'Rae', removedAt: t0);

  group('baseline', () {
    test('null or removed actor can do nothing', () {
      for (final p in Permission.values) {
        expect(policy.can(null, p), isFalse, reason: '$p');
        expect(policy.can(removed, p), isFalse, reason: '$p');
      }
    });

    test('viewer is read-only', () {
      for (final p in Permission.values) {
        expect(policy.can(viewer, p, item: item()), isFalse, reason: '$p');
      }
    });

    test('owner can do everything', () {
      for (final p in Permission.values) {
        expect(policy.can(owner, p, item: item()), isTrue, reason: '$p');
      }
    });

    test('only the owner changes roles, settings, or deletes all data', () {
      for (final p in [
        Permission.changeRoles,
        Permission.transferOwnership,
        Permission.deleteAllData,
        Permission.editSettings,
      ]) {
        expect(policy.can(coord, p), isFalse, reason: '$p');
        expect(policy.can(helper, p), isFalse, reason: '$p');
      }
    });
  });

  group('helpers', () {
    test('can create items and handoffs but not manage people', () {
      expect(policy.can(helper, Permission.createItem), isTrue);
      expect(policy.can(helper, Permission.addHandoff), isTrue);
      expect(policy.can(helper, Permission.manageMembers), isFalse);
      expect(policy.can(helper, Permission.exportData), isFalse);
    });

    test('complete own or unclaimed items only', () {
      expect(
        policy.can(helper, Permission.completeItem, item: item(assignee: 'h')),
        isTrue,
      );
      expect(policy.can(helper, Permission.completeItem, item: item()), isTrue);
      expect(
        policy.can(helper, Permission.completeItem, item: item(assignee: 'o')),
        isFalse,
      );
    });

    test('edit only items they created or hold', () {
      final mine = item(assignee: 'h');
      final other = item(assignee: 'o');
      expect(policy.can(helper, Permission.editItem, item: mine), isTrue);
      expect(policy.can(helper, Permission.editItem, item: other), isFalse);
      expect(policy.can(helper, Permission.deleteItem, item: other), isFalse);
      expect(policy.can(helper, Permission.editItem), isFalse);
    });

    test('can claim unclaimed, release own, but not reassign others', () {
      expect(policy.canAssign(helper, item(), 'h'), isTrue);
      expect(policy.canAssign(helper, item(), 'o'), isFalse);
      expect(policy.canAssign(helper, item(assignee: 'h'), null), isTrue);
      expect(policy.canAssign(helper, item(assignee: 'h'), 'o'), isFalse);
      expect(policy.canAssign(helper, item(assignee: 'o'), 'h'), isFalse);
      expect(policy.canAssign(viewer, item(), 'v'), isFalse);
    });
  });

  group('coordinators', () {
    test('can assign anything to anyone', () {
      expect(policy.canAssign(coord, item(assignee: 'o'), 'h'), isTrue);
      expect(policy.canAssign(coord, item(assignee: 'h'), null), isTrue);
    });

    test('can remove helpers and viewers but not the owner or peers', () {
      expect(policy.canRemoveMember(coord, helper), isTrue);
      expect(policy.canRemoveMember(coord, viewer), isTrue);
      expect(policy.canRemoveMember(coord, owner), isFalse);
      expect(policy.canRemoveMember(coord, coord2), isFalse);
      expect(policy.canRemoveMember(coord, coord), isTrue);
      expect(policy.canRemoveMember(helper, viewer), isFalse);
    });
  });

  group('ownership', () {
    test('nobody can remove the owner (transfer first)', () {
      expect(policy.canRemoveMember(owner, owner), isFalse);
    });

    test(
      'owner cannot be demoted and nobody is promoted to owner directly',
      () {
        expect(policy.canChangeRole(owner, helper, Role.owner), isFalse);
        expect(policy.canChangeRole(owner, owner, Role.member), isFalse);
        expect(policy.canChangeRole(owner, helper, Role.coordinator), isTrue);
        expect(policy.canChangeRole(owner, removed, Role.viewer), isFalse);
      },
    );

    test('transfer ownership only to another active member', () {
      expect(policy.canTransferOwnership(owner, helper), isTrue);
      expect(policy.canTransferOwnership(owner, owner), isFalse);
      expect(policy.canTransferOwnership(owner, removed), isFalse);
      expect(policy.canTransferOwnership(coord, helper), isFalse);
    });

    test('already removed member cannot be removed again', () {
      expect(policy.canRemoveMember(owner, removed), isFalse);
    });
  });
}
