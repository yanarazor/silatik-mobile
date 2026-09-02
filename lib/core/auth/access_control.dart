/// Mobile application access and permission checks.
///
/// Backend remains the security boundary. These checks prevent unsupported
/// roles from entering the mobile UI and keep navigation consistent.
class AccessControl {
  static const mobileRoles = {'Latik', 'Auditor'};

  static const dashboardView = 'Dashboard.Latik.View';
  static const latikProfile = 'Masters.Latik.Profile';
  static const latikView = 'Masters.Latik.View';
  static const latikCreate = 'Masters.Latik.Create';
  static const latikUpdate = 'Masters.Latik.Update';
  static const latikDelete = 'Masters.Latik.Delete';
  static const auditorForLatik = 'Masters.Auditor.Latik';

  static List<String> rolesFromUser(Map<String, dynamic>? user) {
    final value = user?['roles'];
    if (value is! List) return const [];

    return value
        .map((role) {
          if (role is Map) {
            return (role['name'] ?? role['role_name'] ?? '').toString();
          }
          return role.toString();
        })
        .map((role) => role.trim())
        .where((role) => role.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> permissionsFromUser(Map<String, dynamic>? user) {
    final value = user?['permissions'] ?? user?['permission'];
    if (value is! List) return const [];

    return value
        .map((permission) {
          if (permission is Map) {
            return (permission['code'] ?? '').toString();
          }
          return permission.toString();
        })
        .map((permission) => permission.trim())
        .where((permission) => permission.isNotEmpty)
        .toList(growable: false);
  }

  static bool canUseMobile(Map<String, dynamic>? user) {
    return rolesFromUser(user).any(mobileRoles.contains);
  }

  static bool hasPermission(Map<String, dynamic>? user, String permission) {
    final permissions = permissionsFromUser(user);
    return permissions.contains(permission) ||
        permissions.contains('manage.all') ||
        permissions.contains('manage.*') ||
        permissions.contains('Masters.All.Manage');
  }
}
