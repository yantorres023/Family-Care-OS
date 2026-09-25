import 'models.dart';

/// What the acting member wants to do.
enum Permission {
  createItem,
  editItem,
  completeItem,
  deleteItem,
  assignItem,
  addHandoff,
  manageMembers,
  changeRoles,
  transferOwnership,
  exportData,
  deleteAllData,
  editSettings,
}

/// Least-privilege rules (docs/engineering/PRIVACY_MODEL.md §Roles).
///
/// In the single-device MVP these rules protect against mistakes on a shared
/// family device; they are not a security boundary (anyone holding the
/// unlocked device can switch who is acting). Server-side enforcement is
/// required before cloud sync ships.
class PermissionPolicy {
  const PermissionPolicy();

  bool can(Member? actor, Permission permission, {CareItem? item}) {
    if (actor == null || !actor.isActive) return false;
    final role = actor.role;
    switch (permission) {
      case Permission.createItem:
      case Permission.addHandoff:
        return role.index >= Role.member.index;
      case Permission.completeItem:
        if (role.index >= Role.coordinator.index) return true;
        if (role != Role.member) return false;
        // Helpers can complete their own or unclaimed items.
        return item == null ||
            item.assigneeId == null ||
            item.assigneeId == actor.id;
      case Permission.editItem:
      case Permission.deleteItem:
        if (role.index >= Role.coordinator.index) return true;
        if (role != Role.member) return false;
        return item != null &&
            (item.createdById == actor.id || item.assigneeId == actor.id);
      case Permission.assignItem:
        // Helpers may only claim unclaimed items or hand back their own;
        // see [canAssign] for the target check.
        return role.index >= Role.member.index;
      case Permission.manageMembers:
        return role.index >= Role.coordinator.index;
      case Permission.changeRoles:
      case Permission.transferOwnership:
      case Permission.deleteAllData:
      case Permission.editSettings:
        return role == Role.owner;
      case Permission.exportData:
        return role.index >= Role.coordinator.index;
    }
  }

  /// Whether [actor] may set [item]'s assignee to [assigneeId] (null =
  /// unassign).
  bool canAssign(Member? actor, CareItem item, String? assigneeId) {
    if (!can(actor, Permission.assignItem, item: item)) return false;
    if (actor!.role.index >= Role.coordinator.index) return true;
    // Helper: claim an unclaimed item for themselves…
    if (item.assigneeId == null) return assigneeId == actor.id;
    // …or release one they hold.
    return item.assigneeId == actor.id && assigneeId == null;
  }

  /// Whether [actor] may remove [target] from the circle.
  bool canRemoveMember(Member? actor, Member target) {
    if (!can(actor, Permission.manageMembers)) return false;
    if (!target.isActive) return false;
    // The owner must transfer ownership first; nobody removes the owner.
    if (target.role == Role.owner) return false;
    // Coordinators can't remove other coordinators.
    if (actor!.role == Role.coordinator && target.role == Role.coordinator) {
      return actor.id == target.id;
    }
    return true;
  }

  /// Whether [actor] may give [target] the role [newRole].
  bool canChangeRole(Member? actor, Member target, Role newRole) {
    if (!can(actor, Permission.changeRoles)) return false;
    if (!target.isActive) return false;
    // Ownership moves only via transferOwnership.
    if (newRole == Role.owner || target.role == Role.owner) return false;
    return true;
  }

  bool canTransferOwnership(Member? actor, Member target) {
    if (!can(actor, Permission.transferOwnership)) return false;
    return target.isActive && target.id != actor!.id;
  }
}
