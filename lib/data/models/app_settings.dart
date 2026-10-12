enum AppLanguage {
  indonesian('id', 'Bahasa Indonesia'),
  english('en', 'English');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.code == code) return language;
    }
    return AppLanguage.indonesian;
  }
}

class AppSettings {
  final bool darkMode;
  final bool notificationsEnabled;
  final AppLanguage language;

  const AppSettings({
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.language = AppLanguage.indonesian,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? notificationsEnabled,
    AppLanguage? language,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}
