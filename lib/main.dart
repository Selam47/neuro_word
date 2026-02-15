import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/router/app_router.dart';
import 'package:neuro_word/core/theme/app_theme.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';

void main() {
  // Wrap everything in a guarded zone to catch ALL uncaught async errors.
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── Global error handlers ──────────────────────────────────
      // 1. Widget-level rendering / build errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details); // default red-screen in debug
        debugPrint('┌── FlutterError ──────────────────────────────');
        debugPrint('│ ${details.exceptionAsString()}');
        debugPrint('│ ${details.stack}');
        debugPrint('└──────────────────────────────────────────────');
      };

      // 2. Uncaught platform / isolate errors
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('┌── PlatformDispatcher Error ──────────────────');
        debugPrint('│ $error');
        debugPrint('│ $stack');
        debugPrint('└──────────────────────────────────────────────');
        return true; // prevents the app from terminating
      };

      // ── Initialize storage safely ──────────────────────────────
      try {
        final storage = StorageService();
        await storage.init();
      } catch (e, stack) {
        debugPrint('⚠️ StorageService init failed: $e\n$stack');
        // App continues — StorageService._getPrefs() will retry lazily.
      }

      // ── Force dark system chrome ───────────────────────────────
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0B0E14),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // ── Create provider container ──────────────────────────────
      final container = ProviderContainer();

      // Trigger word loading (async, non-blocking)
      container.read(wordProvider.notifier).reload();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const NeuroWordApp(),
        ),
      );
    },
    // 3. Catch any remaining uncaught async errors in this zone.
    (error, stack) {
      debugPrint('┌── runZonedGuarded Error ─────────────────────');
      debugPrint('│ $error');
      debugPrint('│ $stack');
      debugPrint('└──────────────────────────────────────────────');
    },
  );
}

/// Root application widget.
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

