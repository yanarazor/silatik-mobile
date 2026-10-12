import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/app_settings.dart';
import '../data/services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._storage) : super(const AppSettings()) {
    _hydrate();
  }

  final StorageService _storage;

  Future<void> _hydrate() async {
    state = AppSettings(
      darkMode: await _storage.getDarkMode(),
      notificationsEnabled: await _storage.getNotificationsEnabled(),
      language: AppLanguage.fromCode(await _storage.getLanguageCode()),
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _storage.setDarkMode(value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _storage.setNotificationsEnabled(value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setLanguage(AppLanguage value) async {
    await _storage.setLanguageCode(value.code);
    Intl.defaultLocale = value.code == 'en' ? 'en_US' : 'id_ID';
    state = state.copyWith(language: value);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.watch(storageServiceProvider));
});
