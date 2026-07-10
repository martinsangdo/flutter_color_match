# Colour Match — Claude Code onboarding

A cross-platform Flutter puzzle game (Android / iOS, also runs on Web). This
file orients a fresh Claude Code session; read it before making changes.

## Game concept & core mechanic

Drag multi-cell **pieces** from the tray onto a 10×10 **board**. Every cell of a
piece carries its own colour. When **3 or more same-coloured cells become
orthogonally connected** on the board, they clear. Clears that cause further
clears **cascade** for combo bonuses.

- **Campaign (Play):** 90 discrete levels. Each level gives a fixed, ordered
  queue of pieces and an objective — *clear N blocks* (plus, from mid-game, a
  *per-colour quota*) within a limited number of piece placements (the move
  limit). **Win** = objective met before running out of moves. **Lose** = out of
  moves / stuck before the objective is met. Extra clears beyond the goal earn
  2nd and 3rd stars.
- **Endless:** the classic score-chase — infinite random pieces of rising
  variety; ends when no tray piece can be placed.

Difficulty curve: levels 1–3 are trivial tutorials (3 colours, tiny targets);
4–~20 add a 4th colour and obstacles; later levels use 5–6 colours, more
obstacles, tighter targets, and colour quotas.

## Tech stack

- Flutter (Dart 3), Material 3, portrait-locked.
- **State management: Riverpod** (`flutter_riverpod`). Providers live in
  `lib/app/providers.dart`.
- **Persistence:**
  - `shared_preferences` — sound/music flags, "how to play seen"
    (`lib/data/repositories/settings_repository.dart`).
  - **Hive** — structured per-level progress (completed / stars / best cleared)
    (`lib/data/repositories/progress_repository.dart`).
- `google_mobile_ads` — banner slot (test IDs; disabled on web).
- `audioplayers` — SFX + music (see Placeholders).

## Folder structure (feature-first)

```
lib/
  app/            app.dart (MaterialApp), providers.dart (Riverpod)
  core/
    theme/        AppColors + AppTheme
    audio/        AudioService (audioplayers wrapper, tolerant of missing files)
    ads/          AdService (test IDs, web-guarded) + BannerAdSlot
    widgets/      AppLogo (vector brand mark)
  data/
    models/       board.dart, piece.dart, level.dart, progress.dart
    levels/       level_generator.dart, level_solver.dart, placement_strategy.dart
    repositories/ settings_/progress_/level_repository.dart
  features/
    splash/ how_to_play/ home/ level_select/ settings/
    gameplay/     game_engine.dart (pure rules), game_session_controller.dart,
                  gameplay_screen.dart, widgets/ (board, tray, piece, objective,
                  result_dialog)
```

Key logic:
- **Rules engine:** `lib/features/gameplay/game_engine.dart` — UI-agnostic. Placement,
  cascading clears, scoring, win/lose. Reused by gameplay, endless, the generator
  and the solver.
- **Level data:** levels are **generated deterministically from their index** —
  see below. `LevelRepository` caches them lazily so all 90 are never in memory
  at once. Only the level *index* + progress is persisted.

## How levels are defined & the solvability guarantee

Levels are **not** hand-authored JSON; they are produced by
`LevelGenerator.generate(index)` deterministically (seed derived from the index):

1. A greedy **"designer"** plays the *real engine* over a randomly-drawn piece
   pool, recording that exact pool (batches of 3, same tray rules the player
   gets).
2. The objective target is set **at or below** what the designer actually
   cleared. Because the designer's own moves are a valid solution the player can
   reproduce (identical pool, identical rules), **every level is solvable by
   construction.**
3. `LevelSolver.verify(level)` independently re-derives a solution with a greedy
   solver (it does *not* trust the generator). If that reaches the objective, the
   level has a witnessed solution. This runs in the test suite over all 90 levels
   (`test/level_solver_test.dart`) and can be enabled at load time in debug.

Shared move heuristic: `lib/data/levels/placement_strategy.dart` (`bestPlacement`)
— used by the generator, the solver, and the in-game **Hint** highlight.

## Known placeholders (wire these up for production)

- **Banner ad** (`lib/core/ads/`): uses Google **test** unit IDs and shows a
  labelled `[ Banner Ad Placeholder ]` region until an ad loads. Replace
  `_androidBanner` / `_iosBanner` in `ad_service.dart` with real AdMob IDs. Ads
  are never loaded on Web. AdMob app IDs still need adding to
  `AndroidManifest.xml` / `Info.plist` before real ads serve.
- **Hint button** (top-right of gameplay): opens a stub "rewarded ad coming
  soon" dialog; "Show me" calls the real solver to highlight a good move. Swap
  the dialog for a real rewarded-ad flow — gameplay logic is untouched by this.
- **Audio:** `assets/audio/` is empty. Drop `tap/place/clear/combo/win/lose.mp3`
  and `music.mp3`; `AudioService` already references them and no-ops until they
  exist.
- **App icon / feature graphic** (store assets) are NOT generated. Add a 512×512
  source PNG and run `flutter_launcher_icons`; create the 1024×500 feature
  graphic separately. The in-app logo is the vector `AppLogo` widget.

## Identifiers

- Application ID / bundle identifier: **`com.xufagroup.color_match`** — unified across
  Android `applicationId`, Android code `namespace` (Kotlin package
  `com.xufagroup.color_match`), and the iOS `PRODUCT_BUNDLE_IDENTIFIER`
  (tests use `com.xufagroup.color_match.RunnerTests`).

## Commands

```bash
flutter pub get
flutter run                 # device/emulator
flutter run -d chrome       # web (ads disabled)
flutter test                # unit + widget tests (incl. all-levels solvability)
flutter analyze
flutter build apk           # Android
flutter build ios           # iOS (needs macOS/Xcode)
flutter build web
```

## Persisted settings summary

sound on/off, music on/off, "how to play seen" (shared_preferences); per-level
completed/stars/best-cleared (Hive). Level unlock = previous level completed.
