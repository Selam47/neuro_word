import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/router/app_router.dart';
import 'package:neuro_word/core/theme/app_theme.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuro_word/firebase_options.dart';

void main() {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final profileService = UserProfileService();
      await profileService.init();

      final storage = StorageService();
      try {
        await storage.init();

        if (profileService.isFirstLaunch) {
          final learnedIds = storage.getLearnedWords();
          final favoriteIds = storage.getFavoriteWords();
          final xp = storage.getXp();
          if (learnedIds.isNotEmpty || favoriteIds.isNotEmpty || xp > 0) {
            await profileService.migrateFromLegacy(learnedIds, favoriteIds, xp);
          }
        }
      } catch (e, stack) {
        debugPrint('StorageService init failed: $e\n$stack');
      }

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0B0E14),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      runApp(const ProviderScope(child: NeuroWordApp()));
    },
    (error, stack) {
      debugPrint('runZonedGuarded Error: $error');
      debugPrint('$stack');
    },
  );
}

class NeuroWordApp extends ConsumerWidget {
  const NeuroWordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
