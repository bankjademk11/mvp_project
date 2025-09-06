import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/primary_button.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'seeker';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          role: _role,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);
    final t =
        (key) => AppLocalizations.translate(key, languageState.languageCode);

    // Listen to auth state changes
    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('applied_success')),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/jobs');
      }
    });

    // เพิ่มการแปลข้อความข้อผิดพลาด
    String getErrorMessage(String errorKey) {
      switch (errorKey) {
        case 'email_already_registered':
          return t('email_already_registered');
        case 'invalid_registration_data':
          return t('invalid_registration_data');
        case 'password_requirements_not_met':
          return t('password_requirements_not_met');
        case 'email_invalid':
          return t('email_invalid');
        case 'registration_failed':
          return t('registration_failed');
        default:
          return errorKey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('register')),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  t('register'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t('register_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error message
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getErrorMessage(authState.error!),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: t('full_name'),
                    hintText: t('full_name'),
                    prefixIcon: const Icon(Icons.person_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('name_required');
                    }
                    if (value.trim().length < 2) {
                      return t('name_min_length');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: t('email'),
                    hintText: t('email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return t('email_required');
                    }
                    if (!value.trim().contains('@')) {
                      return t('email_invalid');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password requirements info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ໂຕອັກສອນ ລວມທັງຕົວພິມໃຫຍ່ ຕົວພິມນ້ອຍ ເລກ ແລະ ອັກສອນພິເສດ (!@#\$%^&*())',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: t('password'),
                    hintText: 'ຢ່າງໜ້ອຍ 8 ໂຕອັກສອນ',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('password_required');
                    }
                    if (value.length < 8) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 8 ໂຕອັກສອນ';
                    }
                    if (!value.contains(RegExp(r'[A-Z]'))) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີຕົວພິມໃຫຍ່ຢ່າງໜ້ອຍ 1 ໂຕ';
                    }
                    if (!value.contains(RegExp(r'[a-z]'))) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີຕົວພິມນ້ອຍຢ່າງໜ້ອຍ 1 ໂຕ';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີເລກຢ່າງໜ້ອຍ 1 ໂຕ';
                    }
                    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
                      return 'ລະຫັດຜ່ານຕ້ອງມີອັກສອນພິເສດຢ່າງໜ້ອຍ 1 ໂຕ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: t('confirm_password'),
                    hintText: t('confirm_password'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t('confirm_password_required');
                    }
                    if (value != _passwordController.text) {
                      return t('passwords_do_not_match');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role selection
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: InputDecoration(
                    labelText: t('role'),
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'seeker',
                      child: Text(t('job_seeker')),
                    ),
                    DropdownMenuItem(
                      value: 'employer',
                      child: Text(t('employer')),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _role = value ?? 'seeker';
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Register button
                PrimaryButton(
                  text: authState.isLoading ? t('loading') : t('register'),
                  onPressed: authState.isLoading ? null : _handleRegister,
                  loading: authState.isLoading,
                ),
                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t('have_account'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        t('login_now'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
