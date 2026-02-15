import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import 'package:neuro_word/features/splash/presentation/splash_screen.dart';
import 'package:neuro_word/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:neuro_word/features/profile/presentation/profile_screen.dart';
import 'package:neuro_word/features/contact/presentation/contact_screen.dart';
import 'package:neuro_word/features/supporters/presentation/supporters_screen.dart';
import 'package:neuro_word/features/games/flashcard/presentation/flashcard_screen.dart';
import 'package:neuro_word/features/games/cyber_match/presentation/cyber_match_screen.dart';
import 'package:neuro_word/features/games/neon_pulse/presentation/neon_pulse_screen.dart';
import 'package:neuro_word/features/games/session_summary/presentation/session_summary_screen.dart';

/// Central GoRouter configuration.
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ContactScreen(),
        ),
      ),
      GoRoute(
        path: '/supporters',
        name: 'supporters',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SupportersScreen(),
        ),
      ),
      GoRoute(
        path: '/flashcards',
        name: 'flashcards',
        pageBuilder: (context, state) {
          final level = state.uri.queryParameters['level'];
          return _buildPageWithTransition(
            context,
            state,
            FlashcardScreen(level: level),
          );
        },
      ),
      GoRoute(
        path: '/cyber-match',
        name: 'cyber-match',
        pageBuilder: (context, state) {
          final level = state.uri.queryParameters['level'];
          return _buildPageWithTransition(
            context,
            state,
            CyberMatchScreen(level: level),
          );
        },
      ),
      GoRoute(
        path: '/neon-pulse',
        name: 'neon-pulse',
        pageBuilder: (context, state) {
          final level = state.uri.queryParameters['level'];
          return _buildPageWithTransition(
            context,
            state,
            NeonPulseScreen(level: level),
          );
        },
      ),
      GoRoute(
        path: '/session-summary',
        name: 'session-summary',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPageWithTransition(
            context,
            state,
            SessionSummaryScreen(
              learnedIds: List<int>.from(extra['learnedIds'] as List? ?? []),
              totalWords: extra['totalWords'] as int? ?? 0,
              mode: extra['mode'] as String? ?? 'Game Over',
            ),
          );
        },
      ),
    ],
  );

  static CustomTransitionPage _buildPageWithTransition(
      BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.scaled,
          fillColor: Colors.black, // Match app theme
          child: child,
        );
      },
    );
  }
}

