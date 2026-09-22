import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/repositories/auditor_repository.dart';
import 'package:silatik_mobile/data/services/auditor_payload.dart';
import 'package:silatik_mobile/data/services/auditor_service.dart';

class MockAuditorService extends Mock implements AuditorService {}

AuditorProfilPayload _payload() => const AuditorProfilPayload(
      nama: 'Budi',
      nik: '3201010101010001',
      email: 'budi@test.com',
      tempatLahir: 'Bandung',
      tanggalLahir: null,
      phone: '',
      provinsi: '',
      kabupaten: '',
      kodePos: '',
      agama: '',
      status: '1',
      keterangan: '',
      foto: null,
      dokumen: <String, FileItem?>{},
    );

void main() {
  late MockAuditorService service;
  late AuditorRepository repo;

  setUp(() {
    service = MockAuditorService();
    repo = AuditorRepository(service);
  });

  group('AuditorRepository.save extracts ref', () {
    test('from a flat response', () async {
      when(() => service.saveAuditor(any()))
          .thenAnswer((_) async => {'ref': 'AUD-flat'});

      expect(await repo.save(_payload()), 'AUD-flat');
    });

    test('from an envelope-wrapped response (result.data.ref)', () async {
      when(() => service.saveAuditor(any())).thenAnswer((_) async => {
            'result': {
              'data': {'ref': 'AUD-wrapped'}
            }
          });

      expect(await repo.save(_payload()), 'AUD-wrapped');
    });

    test('returns empty string when no ref present', () async {
      when(() => service.saveAuditor(any()))
          .thenAnswer((_) async => {'status': 'ok'});

      expect(await repo.save(_payload()), '');
    });
  });
}
