import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Isolated AdMob wiring. In debug we use Google's official **test** unit IDs;
/// replace [_androidBanner] / [_iosBanner] with real IDs before publishing.
/// Ads are never initialised on web (the plugin has no web support).
class AdService {
  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static bool get adsSupported => !kIsWeb;

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) return _androidBanner;
    return _iosBanner;
  }

  static Future<void> initialize() async {
    if (!adsSupported) return;
    await MobileAds.instance.initialize();
  }
}
