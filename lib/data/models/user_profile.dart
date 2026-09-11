import '../../core/constants/enums.dart';
import '../../core/utils/api_response_utils.dart';

/// A role granted to the user (from `/user/me` `roles[]`).
class UserRole {
  final String name;
  final String description;

  const UserRole({required this.name, required this.description});

  factory UserRole.fromJson(Map<String, dynamic> json) => UserRole(
        name: pickString(json, const ['name', 'role_name'], fallback: '')!,
        description: pickString(json, const ['description'], fallback: '')!,
      );

  /// Human label — the role name, falling back to its description.
  String get label => name.isNotEmpty ? name : description;
}

/// A permission granted to the user (from `/user/me` `permission[]`).
class UserPermission {
  final String code;
  final String description;

  const UserPermission({required this.code, required this.description});

  factory UserPermission.fromJson(Map<String, dynamic> json) => UserPermission(
        code: pickString(json, const ['code'], fallback: '')!,
        description: pickString(json, const ['description'], fallback: '')!,
      );
}

/// Typed model of the `/user/me` response. Owns all key-variant and null
/// handling so consumers read typed getters instead of scanning raw maps.
class UserProfile {
  final String ref;
  final String username;
  final String email;
  final String externalEmail;
  final String identityNumber;
  final String phone;
  final String identityTypeRaw;
  final String sexRaw;
  final String photoUrl;
  final String avatarUrlRaw;
  final String firstName;
  final String lastName;
  final bool active;
  final String latikRef;
  final List<UserRole> roles;
  final List<UserPermission> permissions;

  const UserProfile({
    this.ref = '',
    this.username = '',
    this.email = '',
    this.externalEmail = '',
    this.identityNumber = '',
    this.phone = '',
    this.identityTypeRaw = '',
    this.sexRaw = '',
    this.photoUrl = '',
    this.avatarUrlRaw = '',
    this.firstName = '',
    this.lastName = '',
    this.active = false,
    this.latikRef = '',
    this.roles = const [],
    this.permissions = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return UserProfile(
      ref: pickString(json, const ['ref'], fallback: '')!,
      username: pickString(json, const ['username'], fallback: '')!,
      email: pickString(json, const ['email'], fallback: '')!,
      externalEmail:
          pickString(json, const ['external_email'], fallback: '')!,
      identityNumber: pickString(
          json, const ['identity_number', 'nik', 'no_identitas'],
          fallback: '')!,
      phone: pickString(json, const ['phone', 'no_hp'], fallback: '')!,
      identityTypeRaw:
          pickString(json, const ['identity_type'], fallback: '')!,
      sexRaw: pickString(json, const ['sex'], fallback: '')!,
      photoUrl: pickString(json, const ['photo_url'], fallback: '')!,
      avatarUrlRaw: pickString(json, const ['avatar_url'], fallback: '')!,
      firstName:
          pickString(json, const ['first_name', 'name'], fallback: '')!,
      lastName: pickString(json, const ['last_name'], fallback: '')!,
      active: _truthy(json['active']),
      latikRef: pickString(json, const ['latik_ref'], fallback: '')!,
      roles: parseList(json['roles'], UserRole.fromJson),
      permissions: parseList(
          json['permission'] ?? json['permissions'], UserPermission.fromJson),
    );
  }

  /// Full display name: first + last, falling back to username.
  String get displayName {
    final full = [firstName, lastName].where((p) => p.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    return username.isNotEmpty ? username : '';
  }

  /// Preferred avatar image URL, preferring the intra photo over the SSO one.
  String? get avatarUrl {
    if (photoUrl.isNotEmpty) return photoUrl;
    return avatarUrlRaw.isNotEmpty ? avatarUrlRaw : null;
  }

  /// Email for display, preferring the primary email over the external one.
  String get displayEmail => email.isNotEmpty ? email : externalEmail;

  /// Localized identity-type label ('KTP'/'Paspor'), or '' when unknown.
  String get identityTypeLabel =>
      identityTypeFromRaw(identityTypeRaw)?.label ?? '';

  /// Localized gender label, or '' when unknown.
  String get genderLabel => genderFromRaw(sexRaw)?.label ?? '';

  List<String> get roleLabels =>
      roles.map((r) => r.label).where((l) => l.isNotEmpty).toList();

  int get permissionCount => permissions.length;

  /// Up-to-two-letter avatar initials derived from the display name.
  String get initials {
    final source = displayName.isNotEmpty ? displayName : username;
    final words =
        source.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'SL';
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length < 2 ? w.length : 2).toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

bool _truthy(dynamic value) =>
    value == 1 || value == true || value == '1' || value == 'true';
