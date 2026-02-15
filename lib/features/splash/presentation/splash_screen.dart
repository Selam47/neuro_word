import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';

/// Premium Splash Screen 2.0
/// Features:
/// - Staggered animations (Robot -> Text -> Progress)
/// - Large scale "Hero" robot
/// - Neon typography with glow effects
/// - Futuristic particles background
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _robotScaleAnimation;
  late Animation<double> _robotFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 1. Robot enters (0.0 -> 1.0s)
    _robotScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _robotFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 2. Text reveals (0.5s -> 1.0s)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();

    // Navigate to dashboard after delay
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FuturisticBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Hero Robot ──────────────────────────────────────────
                // Large, central, dominant
                ScaleTransition(
                  scale: _robotScaleAnimation,
                  child: FadeTransition(
                    opacity: _robotFadeAnimation,
                    child: Container(
                      width: size.width * 0.7, // Massively increased size
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          // Deep blue glow behind the robot
                          BoxShadow(
                            color: AppColors.electricBlue.withOpacity(0.15),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                          // Subtle purple core glow
                          BoxShadow(
                            color: AppColors.cyberPurple.withOpacity(0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        'assets/animations/splash_animation.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Typography ──────────────────────────────────────────
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textFadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Column(
                          children: [
                            // Main Title: NEURO WORD
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Colors.white,
                                  AppColors.electricBlue,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(bounds),
                              child: Text(
                                'NEURO WORD',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.orbitron(
                                  fontSize: 42, // Much larger
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.electricBlue
                                          .withOpacity(0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Subtitle: Hoş Geldiniz
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.electricBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      AppColors.electricBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "HOŞ GELDİNİZ",
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 4.0, // Futuristic spacing
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 3),

                // ── Loading Indicator ───────────────────────────────────
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            backgroundColor:
                                AppColors.surfaceMedium.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.electricBlue.withOpacity(0.8),
                            ),
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SYSTEM INITIALIZING...',
                          style: GoogleFonts.shareTechMono(
                            color: AppColors.textSecondary.withOpacity(0.5),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

