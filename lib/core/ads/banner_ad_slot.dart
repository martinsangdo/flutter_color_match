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
        onAdFailedToLoad: (ad, _) => ad.dispose(),
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

    // Reserved placeholder region.
    return Container(
      height: _height,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.locked, width: 1),
      ),
      alignment: Alignment.center,
      child: const Text(
        '[ Banner Ad Placeholder ]',
        style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 1),
      ),
    );
  }
}
