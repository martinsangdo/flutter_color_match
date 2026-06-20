import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Replace these with your real AdMob unit IDs before publishing.
/// The IDs below are Google's official test IDs — safe to use during development.
class AdService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
    }
    return 'ca-app-pub-3940256099942544/2934735716'; // iOS test banner
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
