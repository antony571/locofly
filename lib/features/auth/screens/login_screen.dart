// lib/features/auth/screens/login_screen.dart
//
// The "Welcome Back" login screen from the Figma.
// Has: email field, password field, forgot password, sign in button,
// biometric button, Google + Apple buttons, and a "Sign Up" link.
//
// ConsumerStatefulWidget = StatefulWidget + Riverpod access.
// We need StatefulWidget because we have TextEditingControllers (form fields)
// and a password visibility toggle — these are local UI state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Form key — used to trigger validation on all fields at once
  final _formKey = GlobalKey<FormState>();

  // Controllers hold the text the user types
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Local UI state
  bool _passwordVisible = false;
  bool _isLoading = false;

  // LocalAuth — handles biometric authentication
  final _localAuth = LocalAuthentication();

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Handle email login ────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    // Validate all form fields first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Call the auth controller
    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (authState.value != null) {
      context.go(AppRoutes.home);
    }
  }

  // ─── Handle biometric login ────────────────────────────────────────────────
  Future<void> _handleBiometric() async {
    try {
      // Check if the device supports biometrics
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Biometrics not available on this device')),
          );
        }
        return;
      }

      // Prompt the user for fingerprint / face ID
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access LocoFly',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated && mounted) {
        // Biometric success — in a real app you'd have saved credentials
        // For now navigate to home directly
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Off-white background from Figma
      backgroundColor: const Color(0xFFFAF8F3),
      body: SafeArea(
        child: SingleChildScrollView(
          // SingleChildScrollView prevents overflow when keyboard appears
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo ────────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'LF',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LocoFly',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Heading ─────────────────────────────────────────────────
                Text('Welcome Back', style: AppTextStyles.displayMedium),
                const SizedBox(height: 32),

                // ── Email field ─────────────────────────────────────────────
                Text('Email Address', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(hintText: 'hello@example.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Password field ──────────────────────────────────────────
                Text('Password', style: AppTextStyles.labelMedium),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    // Eye icon to toggle password visibility
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                // ── Forgot password ─────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: implement forgot password in Phase 5
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Sign In button ──────────────────────────────────────────
                LCPrimaryButton(
                  label: 'Sign In',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                ),

                const SizedBox(height: 12),

                // ── Biometric button ────────────────────────────────────────
                LCOutlinedButton(
                  label: 'Use Biometric',
                  leading: const Icon(Icons.face,
                      size: 20, color: AppColors.textSecondary),
                  onPressed: _handleBiometric,
                ),

                const SizedBox(height: 24),

                // ── Divider with "or continue with" ─────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Google + Apple side by side ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
                        child: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
                        child: const Text('Apple'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Sign up link ─────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodySmall,
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.signup),
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
