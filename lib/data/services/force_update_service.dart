import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

class ForceUpdateInfo {
  final bool updateAvailable;
  final bool forceUpdate;
  final String latestVersion;
  final String updateUrl;

  const ForceUpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.updateUrl,
  });
}

class ForceUpdateService {
  // TODO(force-update): read the store version from the API instead
  static const _dummyLatestVersion = '1.0.0';
  static const _dummyForceUpdate = false;

  /// TODO: replace it with actual url
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=id.go.brin.silatik';

  /// TODO: replace it with actual url
  static const _appStoreUrl = 'https://apps.apple.com/app/id0000000000';

  Future<ForceUpdateInfo> check() async {
    final installedVersion = (await PackageInfo.fromPlatform()).version;
    final updateAvailable = installedVersion != _dummyLatestVersion;
    debugPrint('[FORCE_UPDATE] installed $installedVersion, '
        'store $_dummyLatestVersion');

    return ForceUpdateInfo(
      updateAvailable: updateAvailable,
      forceUpdate: _dummyForceUpdate,
      latestVersion: _dummyLatestVersion,
      updateUrl: _storeUrl(),
    );
  }

  static String _storeUrl() {
    if (kIsWeb) return _playStoreUrl;
    return Platform.isIOS ? _appStoreUrl : _playStoreUrl;
  }
}
