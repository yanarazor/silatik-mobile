import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:silatik_mobile/data/services/registrasi_service.dart';
import 'package:silatik_mobile/data/models/registrasi_model.dart';
import 'package:silatik_mobile/data/models/lembaga_model.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late RegistrasiService registrasiService;

  setUp(() {
    mockDio = MockDio();
    registrasiService = RegistrasiService(mockDio);
  });

  const testLembaga = LembagaModel(
    nama: 'PT Test',
    nib: '1234567890123',
    badanHukum: 'PT',
    alamat: 'Jl. Test',
    provinsi: 'Jatim',
    kota: 'Surabaya',
    kodePos: '60112',
    telepon: '031',
    email: 'test@test.com',
  );

  group('RegistrasiService.submit', () {
    test('throws StateError when lembaga is null', () async {
      const model = RegistrasiModel();

      expect(
        () => registrasiService.submit(model),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Data lembaga belum lengkap'),
        )),
      );
    });

    test('submits lembaga data and returns reference number', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({
          'result': {
            'data': {
              'nomor_referensi': 'REG-2024-001',
              'ref': 'LATIK-001',
            },
          },
        }),
      );

      const model = RegistrasiModel(
        lembaga: testLembaga,
        nomorKan: 'KAN-001',
        ruangLingkup: ['Audit TI'],
      );

      final result = await registrasiService.submit(model);
      expect(result, 'REG-2024-001');
    });

    test('calls requestVerifikasi when ref is returned', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({
          'result': {
            'data': {
              'ref': 'LATIK-001',
              'nomor_referensi': 'REG-001',
            },
          },
        }),
      );

      const model = RegistrasiModel(lembaga: testLembaga);
      await registrasiService.submit(model);

      verify(() => mockDio.post('latik/requestverifikasi',
          data: {'ref_latik': 'LATIK-001'})).called(1);
    });

    test('falls back to latik_ref key', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({
          'latik_ref': 'LATIK-002',
        }),
      );

      const model = RegistrasiModel(lembaga: testLembaga);
      final result = await registrasiService.submit(model);
      expect(result, 'LATIK-002');
    });

    test('falls back to ref_latik key', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({
          'ref_latik': 'LATIK-003',
        }),
      );

      const model = RegistrasiModel(lembaga: testLembaga);
      final result = await registrasiService.submit(model);
      expect(result, 'LATIK-003');
    });

    test('generates REG- timestamp when no ref found', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({}),
      );

      const model = RegistrasiModel(lembaga: testLembaga);
      final result = await registrasiService.submit(model);
      expect(result, startsWith('REG-'));
    });

    test('includes kan data in submission', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => makeResponse({'ref': 'L1'}),
      );

      final model = RegistrasiModel(
        lembaga: testLembaga,
        nomorKan: 'KAN-001',
        terbitKan: DateTime(2024, 1, 1),
        berakhirKan: DateTime(2027, 1, 1),
        ruangLingkup: ['Audit TI', 'Forensik'],
      );

      await registrasiService.submit(model);

      final captured = verify(() => mockDio.post(
            'latik/save',
            data: captureAny(named: 'data'),
          )).captured;
      final data = captured.last as Map;
      expect(data['nomor_kan'], 'KAN-001');
      expect(data['ruang_lingkup'], ['Audit TI', 'Forensik']);
      expect(data['nama'], 'PT Test');
    });
  });
}
