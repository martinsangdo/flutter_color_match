import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

/// Loads and shows a single rewarded ad used to unlock an in-game **Hint**.
///
/// Isolated on purpose so gameplay code only asks "did the user earn the
/// reward?" — the load/show/dispose lifecycle stays here. On web (or any
/// platform where ads are unsupported) [show] resolves to `true` immediately so
/// the hint still works during development.
class RewardedHintAd {
  RewardedAd? _ad;
  bool _loading = false;

  /// Whether a rewarded ad is loaded and ready to show right now.
  bool get isReady => _ad != null;

  /// Preloads a rewarded ad so the next [show] is instant. Safe to call
  /// repeatedly; no-ops while a load is in flight or an ad is already ready.
  void preload() {
    if (!AdService.adsSupported || _loading || _ad != null) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: AdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          _loading = false;
          debugPrint('Rewarded hint ad failed to load: $error');
        },
      ),
    );
  }

  /// Shows the rewarded ad and resolves to `true` if the user earned the
  /// reward, `false` otherwise. Preloads the next ad automatically.
  ///
  /// When ads are unsupported (web) this resolves `true` immediately so the
  /// hint flow remains usable.
  Future<bool> show() async {
    if (!AdService.adsSupported) return true;

    final ad = _ad;
    if (ad == null) {
      // Nothing preloaded — kick off a load for next time and let the caller
      // fall back (still grant the hint so the feature never dead-ends).
      preload();
      return true;
    }

    _ad = null; // A rewarded ad is single-use.
    var earned = false;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
        debugPrint('Rewarded hint ad failed to show: $error');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) => earned = true,
    );
    return completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
