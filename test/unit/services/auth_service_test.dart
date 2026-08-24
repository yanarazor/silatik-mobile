import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:silatik_mobile/data/services/auth_service.dart';

import '../../helpers/mock_helpers.dart';

void main() {
  late MockDio mockDio;
  late AuthService authService;

  setUp(() {
    mockDio = MockDio();
    when(() => mockDio.options).thenReturn(BaseOptions(
      baseUrl: 'https://api.example.com/api/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    authService = AuthService(mockDio);
  });

  group('AuthService.register', () {
    test('sends correct data and returns response', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => makeResponse({'status': 'success', 'id': '123'}),
      );

      final result = await authService.register(
        nama: 'Budi',
        email: 'budi@test.com',
        password: 'password123',
        noHp: '08123456789',
      );

      expect(result['status'], 'success');
      expect(result['id'], '123');

      final captured = verify(() => mockDio.post(
            any(),
            data: captureAny(named: 'data'),
          )).captured;
      final data = captured.last as Map;
      expect(data['name'], 'Budi');
      expect(data['email'], 'budi@test.com');
      expect(data['password'], 'password123');
      expect(data['password_confirmation'], 'password123');
      expect(data['no_hp'], '08123456789');
    });

    test('throws on DioException', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'createuser'),
        response: Response(
          statusCode: 422,
          requestOptions: RequestOptions(path: 'createuser'),
          data: {'message': 'Email already exists'},
        ),
      ));

      expect(
        () => authService.register(
          nama: 'Budi',
          email: 'budi@test.com',
          password: 'pass',
          noHp: '081',
        ),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthService.forgotPassword', () {
    test('sends email to correct endpoint', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => makeResponse(null),
      );

      await authService.forgotPassword('budi@test.com');

      verify(() => mockDio.post(
            'auth/forgot-password',
            data: {'email': 'budi@test.com'},
          )).called(1);
    });
  });

  group('AuthService.changePassword', () {
    test('sends correct password data', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
          )).thenAnswer(
        (_) async => makeResponse(null),
      );

      await authService.changePassword(
        oldPassword: 'old123',
        newPassword: 'new456',
      );

      final captured = verify(() => mockDio.post(
            'auth/change-password',
            data: captureAny(named: 'data'),
          )).captured;
      final data = captured.last as Map;
      expect(data['old_password'], 'old123');
      expect(data['new_password'], 'new456');
      expect(data['new_password_confirmation'], 'new456');
    });
  });

  group('AuthService.getMe', () {
    test('returns real user data', () async {
      final fixture = loadFixture('user_me.json');
      when(() => mockDio.get(any())).thenAnswer((_) async =>
          makeResponse(fixture));

      final result = await authService.getMe();
      expect(result['data']['first_name'], 'Venniesa Dhevanty');
      expect(result['data']['email'], 'venniesadhevanty@gmail.com');
      expect(result['data']['latik_ref'], '3d1bf16c-3b5d-49ba-a2ba-39526a081862');
      verify(() => mockDio.get('user/me')).called(1);
    });

    test('returns user data', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => makeResponse({
          'id': 1,
          'name': 'Budi',
          'email': 'budi@test.com',
        }),
      );

      final result = await authService.getMe();
      expect(result['name'], 'Budi');
      verify(() => mockDio.get('user/me')).called(1);
    });

    test('throws on unauthorized', () async {
      when(() => mockDio.get(any())).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'user/me'),
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: 'user/me'),
        ),
      ));

      expect(() => authService.getMe(), throwsA(isA<DioException>()));
    });
  });
}
