import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/user.dart'; // Add this import for AuthState

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
  bool _isRateLimited = false;
  DateTime? _rateLimitEndTime;

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
      duration: const Duration(seconds: 20),
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
    if (_isRateLimited) {
      _showRateLimitMessage();
      return;
    }
    
    if (!_formKey.currentState!.validate()) return;
    
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _showRateLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้งในภายหลัง'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        // Redirect based on user role
        if (next.user?.role == 'employer') {
          context.go('/employer/dashboard');
        } else {
          context.go('/jobs');
        }
      } else if (next.error != null && next.error!.isNotEmpty) {
        // Check if it's a rate limit error
        if (next.error!.contains('rate_limit_exceeded')) {
          setState(() {
            _isRateLimited = true;
            // Set rate limit end time to 1 minute from now
            _rateLimitEndTime = DateTime.now().add(const Duration(minutes: 1));
            
            // Reset rate limit after 1 minute
            Future.delayed(const Duration(minutes: 1), () {
              if (mounted) {
                setState(() {
                  _isRateLimited = false;
                  _rateLimitEndTime = null;
                });
              }
            });
          });
          
          _showRateLimitMessage();
        } else {
          // Show other error messages
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t(next.error!)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // App Logo with Animation
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _rotationController,
                            child: AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: const Size(200, 200),
                                  painter: _WavePainter(
                                    animationValue: _waveController.value,
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                      Colors.lightBlue.shade200,
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Icon(
                            Icons.business_center,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t('welcome_back'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('login_to_continue'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (authState.error != null && !authState.error!.contains('rate_limit_exceeded')) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t(authState.error!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (_isRateLimited) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้งในภายหลัง',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: t('password'),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(t('forgot_password')),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: authState.isLoading ? t('loading') : t('login'),
                      onPressed: authState.isLoading || _isRateLimited ? null : _handleLogin,
                      loading: authState.isLoading,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            t('or_continue_with'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(icon: 'assets/images/google_logo.png'), // Placeholder
                        const SizedBox(width: 24),
                        _buildSocialButton(icon: 'assets/images/apple_logo.png'), // Placeholder
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text(t('no_account'))),
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
      ),
    );
  }

  Widget _buildSocialButton({required String icon}) {
    return IconButton(
      onPressed: () {},
      icon: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // child: Image.asset(icon), // Uncomment when you have the assets
          child: Icon(Icons.login, size: 20), // Placeholder icon
        ),
      ),
      style: IconButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final List<Color> colors;
  final int waveCount = 3;

  _WavePainter({required this.animationValue, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    
    for (int i = 0; i < waveCount; i++) {
      final progress = (animationValue + (i / waveCount)) % 1.0;
      final radius = size.width / 2 * progress;
      final alpha = (255 * (1.0 - progress)).clamp(0, 255).toInt();
      
      final paint = Paint()
        ..color = colors[i % colors.length].withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}