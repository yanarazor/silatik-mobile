import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/data/models/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    // Trimmed from the real /user/me sample.
    final sample = {
      'ref': 'ac88c45b-6741-45c0-a6fb-e8957302ebbe',
      'username': 'venniesadhevanty@gmail.com',
      'external_email': null,
      'email': 'venniesadhevanty@gmail.com',
      'identity_number': '12345678987654',
      'phone': '08123456789',
      'identity_type': '1',
      'sex': '2',
      'photo_url': 'https://intra.brin.go.id/api/user/foto',
      'first_name': 'Venniesa Dhevanty',
      'last_name': null,
      'active': 1,
      'avatar_url': 'https://testapi.brin.go.id/sso/user/avatar/x',
      'latik_ref': '3d1bf16c-3b5d-49ba-a2ba-39526a081862',
      'roles': [
        {'name': 'Latik', 'description': 'Role untuk admin Latik'},
      ],
      'permission': [
        {'code': 'Masters.Latik.Profile', 'description': 'a'},
        {'code': 'Masters.Auditor.View', 'description': 'b'},
      ],
    };

    test('parses core fields from the real sample', () {
      final u = UserProfile.fromJson(sample);
      expect(u.ref, 'ac88c45b-6741-45c0-a6fb-e8957302ebbe');
      expect(u.username, 'venniesadhevanty@gmail.com');
      expect(u.email, 'venniesadhevanty@gmail.com');
      expect(u.identityNumber, '12345678987654');
      expect(u.phone, '08123456789');
      expect(u.firstName, 'Venniesa Dhevanty');
      expect(u.lastName, '');
      expect(u.latikRef, '3d1bf16c-3b5d-49ba-a2ba-39526a081862');
    });

    test('derives display name, avatar, active, labels', () {
      final u = UserProfile.fromJson(sample);
      expect(u.displayName, 'Venniesa Dhevanty');
      expect(u.avatarUrl, 'https://intra.brin.go.id/api/user/foto');
      expect(u.active, isTrue);
      expect(u.identityTypeLabel, 'KTP'); // '1' -> KTP
    });

    test('parses roles and permission (singular key)', () {
      final u = UserProfile.fromJson(sample);
      expect(u.roleLabels, ['Latik']);
      expect(u.permissionCount, 2);
      expect(u.permissions.first.code, 'Masters.Latik.Profile');
    });

    test('falls back to username for display name when no first/last', () {
      final u = UserProfile.fromJson({'username': 'user@x.com'});
      expect(u.displayName, 'user@x.com');
    });

    test('avatar prefers photo_url then avatar_url then null', () {
      expect(
        UserProfile.fromJson({'avatar_url': 'a'}).avatarUrl,
        'a',
      );
      expect(UserProfile.fromJson({}).avatarUrl, isNull);
    });

    test('active accepts int/bool/string forms', () {
      expect(UserProfile.fromJson({'active': 1}).active, isTrue);
      expect(UserProfile.fromJson({'active': true}).active, isTrue);
      expect(UserProfile.fromJson({'active': '1'}).active, isTrue);
      expect(UserProfile.fromJson({'active': 0}).active, isFalse);
      expect(UserProfile.fromJson({}).active, isFalse);
    });

    test('defaults safely on empty json', () {
      final u = UserProfile.fromJson(const {});
      expect(u.displayName, '');
      expect(u.roleLabels, isEmpty);
      expect(u.permissionCount, 0);
      expect(u.identityTypeLabel, '');
    });
  });
}
