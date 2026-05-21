import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service;
  AuthRepository(this._service);

  Future<Map<String, dynamic>> login(String username, String password) =>
      _service.login(username, password);

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) =>
      _service.register(
        nama: payload['nama'] ?? '',
        email: payload['email'] ?? '',
        password: payload['password'] ?? '',
        noHp: payload['phone'] ?? '',
      );

  Future<void> forgotPassword(String email) => _service.forgotPassword(email);

  Future<void> changePassword(String oldPassword, String newPassword) =>
      _service.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  Future<Map<String, dynamic>> getMe() => _service.getMe();
}
