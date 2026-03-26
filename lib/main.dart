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

      await _initializeServices();

      runApp(const ProviderScope(child: NeuroWordApp()));
    },
    (error, stack) {
      debugPrint('runZonedGuarded Error: $error\n$stack');
    },
  );
}

Future<void> _initializeServices() async {
  final profileService = UserProfileService();

  final results = await Future.wait<bool>([
    _initSupabase(),
    _initProfileService(profileService),
  ]);

  final isSupabaseReady = results[0];
  final isProfileReady = results[1];

  if (!isProfileReady) return;

  await _migrateLegacyDataIfNeeded(profileService, isSupabaseReady);
}

Future<bool> _initSupabase() async {
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://zwqooayqbfwsopjhkdhz.supabase.co',
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_FK-4WR8xm07stRzr9g7muQ_RIbEyPqA',
      ),
    ).timeout(const Duration(seconds: 8));
    return true;
  } catch (e, stack) {
    debugPrint('Supabase init failed: $e\n$stack');
    return false;
  }
}

Future<bool> _initProfileService(UserProfileService service) async {
  try {
    await service.init().timeout(const Duration(seconds: 5));
    return true;
  } catch (e, stack) {
    debugPrint('UserProfileService init failed: $e\n$stack');
    return false;
  }
}

Future<void> _migrateLegacyDataIfNeeded(
  UserProfileService profileService,
  bool isSupabaseReady,
) async {
  if (!profileService.isFirstLaunch) return;

  try {
    final storage = StorageService();
    await storage.init().timeout(const Duration(seconds: 5));

    final learnedIds = storage
        .getLearnedWords()
        .map((e) => e.toString())
        .toList();
    final favoriteIds = storage
        .getFavoriteWords()
        .map((e) => e.toString())
        .toList();
    final xp = storage.getXp();

    final hasLegacyData =
        learnedIds.isNotEmpty || favoriteIds.isNotEmpty || xp > 0;

    if (hasLegacyData) {
      await profileService.migrateFromLegacy(learnedIds, favoriteIds, xp);
    }
  } catch (e, stack) {
    debugPrint('Legacy migration failed: $e\n$stack');
  }
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
