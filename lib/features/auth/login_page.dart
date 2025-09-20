

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/user.dart';
import '../../common/widgets/organic_wave_painter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late final AnimationController _waveController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        if (next.user?.role == 'employer') {
          context.go('/employer/dashboard');
        } else {
          context.go('/jobs');
        }
      } else if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t(next.error!)),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: OrganicWavePainter(),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      _AnimatedLogo(
                        waveController: _waveController,
                        rotationController: _rotationController,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        t('welcome_back'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('login_to_continue'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 48),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: t('email')),
                        validator: (value) {
                          if (value == null || value.isEmpty || !value.contains('@')) {
                            return t('email_invalid');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: t('password'),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t('password_required');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: theme.colorScheme.primary,
                              ),
                              Text(t('remember_me')),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(t('forgot_password')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: authState.isLoading ? t('loading') : t('login'),
                        onPressed: authState.isLoading ? null : _handleLogin,
                        loading: authState.isLoading,
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              t('or_continue_with'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(icon: const Icon(Icons.g_mobiledata, size: 28)),
                          const SizedBox(width: 24),
                          _buildSocialButton(icon: const Icon(Icons.apple, size: 28)),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t('no_account'), style: theme.textTheme.bodyMedium),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text(t('register_now')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({required Widget icon}) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: icon,
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({
    required this.waveController,
    required this.rotationController,
  });

  final AnimationController waveController;
  final AnimationController rotationController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: rotationController,
            child: AnimatedBuilder(
              animation: waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(200, 200),
                  painter: _WavePainter(
                    animationValue: waveController.value,
                    color: theme.colorScheme.secondary, // Use darker green for waves
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                )
              ]
            ),
            padding: const EdgeInsets.all(20),
            child: Icon(
              Icons.business_center,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int waveCount = 4;

  _WavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (int i = 0; i < waveCount; i++) {
      final progress = (animationValue + (i / waveCount)) % 1.0;
      final radius = size.width / 1.5 * progress * (i % 2 == 0 ? 1 : 0.7);
      final alpha = (150 * (1.0 - progress)).clamp(0, 255).toInt();

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}