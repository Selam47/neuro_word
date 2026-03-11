import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      _focusNode.requestFocus();
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    await UserProfileService().setUsername(name);
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FuturisticBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Logo / animation
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 180,
                      maxHeight: 140,
                    ),
                    child: Lottie.asset(
                      'assets/animations/logo_animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'NEURO WORD',
                    style: GoogleFonts.orbitron(
                      color: AppColors.electricBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İngilizce öğrenmenin geleceği',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'KULLANICI ADIN NE?',
                      style: GoogleFonts.orbitron(
                        color: AppColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.electricBlue.withOpacity(0.5),
                        width: 1.5,
                      ),
                      color: AppColors.surfaceMedium,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textCapitalization: TextCapitalization.words,
                      maxLength: 20,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Örn: Alex, Kaşif, Mira...',
                        hintStyle: GoogleFonts.rajdhani(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                        counterText: '',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: AppColors.deepSpace,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.deepSpace,
                              ),
                            )
                          : Text(
                              'BAŞLA',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await UserProfileService().setUsername('Kaşif');
                            if (mounted) context.go('/dashboard');
                          },
                    child: Text(
                      'Şimdi değil, atla',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
