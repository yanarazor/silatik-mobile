import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/auth/access_control.dart';

void main() {
  group('AccessControl', () {
    test('allows supported mobile roles', () {
      expect(
        AccessControl.canUseMobile({
          'roles': [
            {'name': 'Bendahara'},
            {'name': 'Latik'},
          ],
        }),
        isTrue,
      );
    });

    test('denies back-office roles and unknown users', () {
      expect(
        AccessControl.canUseMobile({
          'roles': [
            {'name': 'adminpusat'},
          ],
        }),
        isFalse,
      );
      expect(AccessControl.canUseMobile(null), isFalse);
    });

    test('matches permission object and string response shapes', () {
      final user = {
        'permissions': [
          {'code': 'Masters.Latik.Profile'},
          'Masters.Latik.Update',
        ],
      };

      expect(
        AccessControl.hasPermission(user, AccessControl.latikProfile),
        isTrue,
      );
      expect(
        AccessControl.hasPermission(user, AccessControl.latikUpdate),
        isTrue,
      );
      expect(
        AccessControl.hasPermission(user, AccessControl.latikDelete),
        isFalse,
      );
    });

    test('supports singular permission response key', () {
      expect(
        AccessControl.hasPermission(
          {
            'permission': [
              {'code': 'Dashboard.Latik.View'},
            ],
          },
          AccessControl.dashboardView,
        ),
        isTrue,
      );
    });
  });
}
