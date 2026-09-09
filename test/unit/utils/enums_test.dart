import 'package:flutter_test/flutter_test.dart';
import 'package:silatik_mobile/core/constants/enums.dart';

void main() {
  group('identityTypeFromRaw', () {
    test('maps numeric and textual codes to enums with Indonesian labels', () {
      expect(identityTypeFromRaw(1), IdentityType.ktp);
      expect(identityTypeFromRaw('2'), IdentityType.passport);
      expect(identityTypeFromRaw('ktp'), IdentityType.ktp);
      expect(identityTypeFromRaw('Paspor'), IdentityType.passport);
      expect(IdentityType.ktp.label, 'KTP');
      expect(IdentityType.passport.label, 'Paspor');
    });

    test('returns null for absent or unknown values', () {
      expect(identityTypeFromRaw(null), isNull);
      expect(identityTypeFromRaw(''), isNull);
      expect(identityTypeFromRaw('sim'), isNull);
    });
  });

  group('genderFromRaw', () {
    test('maps numeric and textual codes to enums with Indonesian labels', () {
      expect(genderFromRaw(1), Gender.male);
      expect(genderFromRaw('2'), Gender.female);
      expect(genderFromRaw('L'), Gender.male);
      expect(genderFromRaw('female'), Gender.female);
      expect(Gender.male.label, 'Laki-laki');
      expect(Gender.female.label, 'Perempuan');
    });

    test('returns null for absent or unknown values', () {
      expect(genderFromRaw(null), isNull);
      expect(genderFromRaw(''), isNull);
      expect(genderFromRaw('other'), isNull);
    });
  });
}
