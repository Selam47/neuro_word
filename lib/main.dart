import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/router/app_router.dart';
import 'package:neuro_word/core/theme/app_theme.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0B0E14),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      try {
        await Supabase.initialize(
          url: 'https://zwqooayqbfwsopjhkdhz.supabase.co',
          anonKey: 'sb_publishable_FK-4WR8xm07stRzr9g7muQ_RIbEyPqA',
        ).timeout(const Duration(seconds: 8));
      } catch (e, stack) {
        debugPrint('Supabase init failed or timed out: $e\n$stack');
      }

      final profileService = UserProfileService();
      try {
        await profileService.init().timeout(const Duration(seconds: 5));
      } catch (e, stack) {
        debugPrint('UserProfileService init failed: $e\n$stack');
      }

      try {
        final storage = StorageService();
        await storage.init().timeout(const Duration(seconds: 5));

        if (profileService.isFirstLaunch) {
          final learnedIds = storage
              .getLearnedWords()
              .map((e) => e.toString())
              .toList();
          final favoriteIds = storage
              .getFavoriteWords()
              .map((e) => e.toString())
              .toList();
          final xp = storage.getXp();
          if (learnedIds.isNotEmpty || favoriteIds.isNotEmpty || xp > 0) {
            await profileService.migrateFromLegacy(
                learnedIds, favoriteIds, xp);
          }
        }
      } catch (e, stack) {
        debugPrint('StorageService init failed: $e\n$stack');
      }

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
