import '../operations/operation_engine.dart';

class PermissionEngine {
  /// Evaluates permission conditions to determine if a widget or action should be allowed.
  static bool hasPermission(Map<String, dynamic> definition, Map<String, dynamic> state) {
    // 1. Resolve User Roles (Handle both single string and list)
    final userRolesRaw = state['userRoles'] ?? state['userRole'];
    final List<String> userRoles = userRolesRaw is List 
      ? userRolesRaw.map((e) => e.toString()).toList() 
      : (userRolesRaw != null ? [userRolesRaw.toString()] : []);

    // 2. Resolve User Permissions (Capabilities)
    final userPermissionsRaw = state['userPermissions'] ?? state['permissions'];
    final List<String> userPermissions = userPermissionsRaw is List 
      ? userPermissionsRaw.map((e) => e.toString()).toList() 
      : (userPermissionsRaw != null ? [userPermissionsRaw.toString()] : []);

    // 3. Legacy Support: visibleFor / hiddenFor
    if (definition.containsKey('visibleFor')) {
      final allowed = _toList(definition['visibleFor']);
      if (!allowed.any((role) => userRoles.contains(role))) return false;
    }
    if (definition.containsKey('hiddenFor')) {
      final hidden = _toList(definition['hiddenFor']);
      if (hidden.any((role) => userRoles.contains(role))) return false;
    }

    // 4. New: requiredRoles (Must have at least one)
    if (definition.containsKey('requiredRoles')) {
      final required = _toList(definition['requiredRoles']);
      if (!required.any((role) => userRoles.contains(role))) return false;
    }

    // 5. New: requiredPermissions (Must have at least one capability)
    if (definition.containsKey('requiredPermissions')) {
      final required = _toList(definition['requiredPermissions']);
      if (!required.any((perm) => userPermissions.contains(perm))) return false;
    }

    // 6. New: permissionCondition (Dynamic Expression)
    if (definition.containsKey('permissionCondition')) {
      final condition = definition['permissionCondition'].toString();
      final result = OperationEngine.evaluate(condition, state);
      if (result != true) return false;
    }

    return true;
  }

  static List<String> _toList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value != null) return [value.toString()];
    return [];
  }
}
