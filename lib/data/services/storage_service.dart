import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _secureStorage = FlutterSecureStorage();

  Future<void> saveToken(String token) => _secureStorage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);
  Future<void> deleteToken() => _secureStorage.delete(key: _tokenKey);

  Future<void> setStringPref(String key, String value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(key, value);
  }
}
