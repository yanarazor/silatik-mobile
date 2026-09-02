import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _rememberedUsernameKey = 'remembered_username';
  static const _secureStorage = FlutterSecureStorage();

  Future<void> saveToken(String token) =>
      _secureStorage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _secureStorage.read(key: _tokenKey);
  Future<void> deleteToken() => _secureStorage.delete(key: _tokenKey);

  Future<void> setRememberedUsername(String username) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_rememberedUsernameKey, username);
  }

  Future<String?> getRememberedUsername() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(_rememberedUsernameKey);
  }

  Future<void> clearRememberedUsername() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_rememberedUsernameKey);
  }

  Future<void> setStringPref(String key, String value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(key, value);
  }
}
