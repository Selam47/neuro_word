import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuro_word/core/constants/app_colors.dart';
import 'package:neuro_word/services/auth_service.dart';
import 'package:neuro_word/shared/widgets/futuristic_background.dart';
import 'package:neuro_word/shared/widgets/glass_card.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Şifreler eşleşmiyor'),
          backgroundColor: AppColors.warningRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      await _authService.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kayıt başarılı, lütfen giriş yapın'),
            backgroundColor: AppColors.electricBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Kayıt Başarısız';
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Şifre çok zayıf (en az 6 karakter).';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Geçersiz e-posta formatı.';
        } else {
          errorMessage = 'Hata: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.warningRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.electricBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: FuturisticBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text(
                  'YENİ KİMLİK',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.electricBlue,
                    shadows: [
                      Shadow(
                        color: AppColors.electricBlue.withOpacity(0.8),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                GlassCard(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         Text(
                          'PROFİL OLUŞTUR',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'E-POSTA',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.electricBlue),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen e-posta adresinizi girin';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'ŞİFRE',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.electricBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.electricBlue.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordObscured = !_isPasswordObscured;
                                });
                              },
                            ),
                          ),
                          obscureText: _isPasswordObscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen bir şifre belirleyin';
                            }
                            if (value.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _confirmPasswordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'ŞİFREYİ ONAYLA',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.electricBlue),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.electricBlue.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmObscured = !_isConfirmObscured;
                                });
                              },
                            ),
                          ),
                          obscureText: _isConfirmObscured,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen şifrenizi doğrulayın';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _signup,
                          style: ElevatedButton.styleFrom(
                             shadowColor: AppColors.cyberPurple.withOpacity(0.6),
                             backgroundColor: AppColors.cyberPurple, // Distinct color for signup
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('KAYIT OL'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

