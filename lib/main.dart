import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/ads/ad_service.dart';
import 'data/repositories/progress_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Structured progress store (Hive) + ads (skipped on web / initialised lazily).
  await Hive.initFlutter();
  final progressRepository = await ProgressRepository.open();
  await AdService.initialize();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        progressRepositoryProvider.overrideWithValue(progressRepository),
      ],
      child: const ColorMatchApp(),
    ),
  );
}
