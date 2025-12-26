import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/app_design.dart';
import '../../../core/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(authProvider.notifier).signup(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.darkGradient,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Create account', style: AppTextStyles.headlineLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign up with email to start tracking your darts journey.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _LabeledField(
                        label: 'Username',
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. dart_master',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Choose a username';
                            if (v.length < 6) return 'Use at least 6 characters';
                            final re = RegExp(r'^[A-Za-z0-9_]+$');
                            if (!re.hasMatch(v)) {
                              return 'Letters, numbers, underscore only';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledField(
                        label: 'Email',
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Enter your email';
                            final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                            if (!emailOk) return 'Enter a valid email';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledField(
                        label: 'Password',
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: '8+ chars with letters & numbers',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.length < 8) return 'Use at least 8 characters';
                            final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
                            final hasNumber = RegExp(r'\d').hasMatch(v);
                            if (!hasLetter || !hasNumber) {
                              return 'Include letters and numbers';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LabeledField(
                        label: 'Confirm Password',
                        child: TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Repeat password',
                            prefixIcon: Icon(Icons.lock_reset),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_isSubmitting ? 'Creating...' : 'Sign up'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.bgLight)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              'Or sign up with',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.bgLight)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () {},
                              icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                              label: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () {},
                              icon: const FaIcon(FontAwesomeIcons.facebook, size: 18),
                              label: const Text('Facebook'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : () {},
                              icon: const FaIcon(FontAwesomeIcons.apple, size: 18),
                              label: const Text('Apple'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?', style: AppTextStyles.bodyMedium),
                          TextButton(
                            onPressed: () => context.go('/auth/login'),
                            child: const Text('Log in'),
                          ),
                        ],
                      ),
                    ],
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

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}
