import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/core/services/firebase_service.dart';
import 'package:neuro_word/core/services/user_profile_service.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String _selectedLevel = 'A1';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1'];

  static const Map<String, String> _levelDescriptions = {
    'A1': 'Başlangıç',
    'A2': 'Temel',
    'B1': 'Orta',
    'B2': 'Üst Orta',
    'C1': 'İleri',
  };

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
    _nameController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _focusNode.requestFocus();
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    final profile = UserProfileService();
    await profile.setUsername(name);
    await profile.setProficiencyLevel(_selectedLevel);
    try {
      await FirebaseService().saveUserProfile(name, _selectedLevel);
    } catch (_) {}
    if (mounted) context.go('/dashboard');
  }

  Future<void> _skip() async {
    await UserProfileService().setUsername('Kaşif');
    await UserProfileService().setProficiencyLevel('A1');
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
                  const SizedBox(height: 16),

                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 160,
                      maxHeight: 120,
                    ),
                    child: Lottie.asset(
                      'assets/animations/logo_animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'NEURO WORD',
                    style: GoogleFonts.orbitron(
                      color: AppColors.electricBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'İngilizce öğrenmenin geleceği',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),

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
                      controller: _nameController,
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

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SEVİYENİ SEÇ',
                      style: GoogleFonts.orbitron(
                        color: AppColors.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: _levels.map((level) {
                      final isSelected = _selectedLevel == level;
                      final color = AppColors.forLevel(level);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedLevel = level);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 62,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withOpacity(0.18)
                                    : AppColors.surfaceMedium,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : AppColors.cardBorder,
                                  width: isSelected ? 1.8 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.25),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    level,
                                    style: GoogleFonts.orbitron(
                                      color: isSelected
                                          ? color
                                          : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _levelDescriptions[level]!,
                                    style: GoogleFonts.rajdhani(
                                      color: isSelected
                                          ? color.withOpacity(0.8)
                                          : AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentOrange.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.accentOrange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Warning: Level selection determines the word density in your neuro-network.',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.accentOrange.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

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
                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: _isLoading ? null : _skip,
                    child: Text(
                      'Şimdi değil, atla',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
