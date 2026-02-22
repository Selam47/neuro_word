import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neuro_word/core/router/app_router.dart';
import 'package:neuro_word/core/theme/app_theme.dart';
import 'package:neuro_word/core/constants/app_strings.dart';
import 'package:neuro_word/core/services/storage_service.dart';
import 'package:neuro_word/features/learning/providers/word_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuro_word/firebase_options.dart';

void main() {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final storage = StorageService();
      try {
        await storage.init();
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

      final container = ProviderContainer();

      container.read(wordProvider.notifier).reload();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const NeuroWordApp(),
        ),
      );
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
