import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Isolated AdMob wiring. In debug we use Google's official **test** unit IDs;
/// replace [_androidBanner] / [_iosBanner] and the rewarded IDs with real IDs
/// before publishing. Ads are never initialised on web (the plugin has no web
/// support).
class AdService {
  static const _androidBanner = 'ca-app-pub-8762959223087619/5606821527';
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  // Google's official **test** rewarded unit IDs. Swap these for real AdMob
  // rewarded units before publishing.
  static const _androidRewarded = 'ca-app-pub-8762959223087619/5004186294';
  static const _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static bool get adsSupported => !kIsWeb;

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static String get bannerAdUnitId => _isAndroid ? _androidBanner : _iosBanner;

  static String get rewardedAdUnitId =>
      _isAndroid ? _androidRewarded : _iosRewarded;

  static Future<void> initialize() async {
    if (!adsSupported) return;
    await MobileAds.instance.initialize();
  }
}
