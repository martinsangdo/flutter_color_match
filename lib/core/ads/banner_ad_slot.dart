import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme/app_theme.dart';
import 'ad_service.dart';

/// Reserves a fixed banner region at the bottom of gameplay, sized for an
/// Anchored Adaptive Banner. Isolated on purpose: swapping in production ad
/// units never touches gameplay code.
///
/// - Web: renders nothing (ads disabled).
/// - Mobile: loads a test banner; until it loads (or if it fails) it shows a
///   clearly labelled placeholder so the slot is easy to find and wire up.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  String? _error;

  static const double _height = 56;

  @override
  void initState() {
    super.initState();
    if (AdService.adsSupported) _load();
  }

  void _load() {
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          // Surface *why* the ad didn't load — most often code 3 ("no fill"),
          // which is normal for a brand-new AdMob unit that hasn't started
          // serving yet (can take a few hours to ~48h after creation).
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (mounted) setState(() => _error = 'code ${error.code}: ${error.message}');
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    if (_loaded && _ad != null) {
      return SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      );
    }

    // No ad to show. In release builds, take up no space and show nothing —
    // the labelled placeholder is a development aid only. In debug builds we
    // keep the labelled region (and surface the load error, if any) so the
    // slot is easy to find and failures are diagnosable on-device.
    if (!kDebugMode) return const SizedBox.shrink();

    final label = _error != null
        ? 'Ad failed — $_error'
        : '[ Banner Ad Placeholder ]';
    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.locked, width: 1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
