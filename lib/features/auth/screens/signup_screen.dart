// lib/features/auth/screens/signup_screen.dart
//
// The Figma shows TWO signup steps on separate "pages":
//   Step 1: Country picker + phone number → "Sign In" button → social options
//   Step 2: Full name + email + password + confirm password → "Login" button
//
// We implement this as a single screen with a PageView (swipeable pages).
// A PageController lets us animate between the two steps programmatically.

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Controls which "page" is shown (0 = phone step, 1 = details step)
  final _pageController = PageController();

  // Step 1 fields
  Country _selectedCountry = Country(
    phoneCode: '91',
    countryCode: 'IN',
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: 'India',
    example: '9876543210',
    displayName: 'India (IN) [+91]',
    displayNameNoCountryCode: 'India (IN)',
    e164Key: '91-IN-0',
  );
  final _phoneController = TextEditingController();

  // Step 2 fields
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey2 = GlobalKey<FormState>();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Move to step 2
  void _goToStep2() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Handle final sign up
  Future<void> _handleSignUp() async {
    if (!_formKey2.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
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
    }
    // On success the router redirects to /home automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Amber header background (top portion of screen) ───────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              color: AppColors.onboardingBackground,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.flight, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'LOCO',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── White card sliding up over the amber background ────────────────
          // This is the rounded card that sits on top of the yellow area
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: PageView(
                controller: _pageController,
                // Disable swiping — user must use the button to advance
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Phone number ─────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign Up', style: AppTextStyles.headingLarge),
          const SizedBox(height: 28),

          // Country / Region picker
          Text('Country/Region', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              // Opens the country picker bottom sheet
              showCountryPicker(
                context: context,
                onSelect: (country) {
                  setState(() => _selectedCountry = country);
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedCountry.flagEmoji} ${_selectedCountry.name} (+${_selectedCountry.phoneCode})',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textTertiary),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Phone number
          Text('Phone Number', style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '000 000 0000',
              // Show the country code as a prefix inside the field
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(
                  '+${_selectedCountry.phoneCode}',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),

          const SizedBox(height: 24),

          // Sign In (proceed to step 2) button
          LCPrimaryButton(label: 'Sign In', onPressed: _goToStep2),

          const SizedBox(height: 12),

          LCOutlinedButton(
            label: 'Use Biometric',
            leading: const Icon(Icons.face,
                size: 20, color: AppColors.textSecondary),
            onPressed: () {},
          ),

          const SizedBox(height: 24),

          Center(
            child: Text('or continue with', style: AppTextStyles.caption),
          ),
          const SizedBox(height: 16),

          // Social login buttons
          _socialButton(
            icon: Icons.mail_outline,
            label: 'Continue with Email',
            onTap: _goToStep2,
          ),
          const SizedBox(height: 10),
          _socialButton(
            icon: Icons.g_mobiledata,
            label: 'Continue with Google',
            onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
          ),
          const SizedBox(height: 10),
          _socialButton(
            icon: Icons.facebook,
            label: 'Continue with Facebook',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _socialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onTap: () => ref.read(authProvider.notifier).signInWithGoogle(),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Name / Email / Password ─────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button to return to step 1
            GestureDetector(
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Icon(Icons.arrow_back, size: 22),
            ),
            const SizedBox(height: 16),

            Text('Sign Up', style: AppTextStyles.headingLarge),
            const SizedBox(height: 28),

            // Full name
            _buildLabel('Full Name', required: true),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(hintText: 'Vishal Kumar'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Email
            _buildLabel('Email ID', required: true),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'vishal@gmail.com'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildLabel('Password', required: true),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _buildLabel('Confirm Password', required: true),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: () => setState(
                      () => _confirmPasswordVisible = !_confirmPasswordVisible),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 28),

            // Dark "Login" button (matches Figma — black button with yellow text)
            LCDarkButton(
              label: 'Login',
              isLoading: _isLoading,
              onPressed: _handleSignUp,
            ),

            const SizedBox(height: 16),

            // Google option
            LCOutlinedButton(
              label: 'Continue with Google',
              onPressed: () =>
                  ref.read(authProvider.notifier).signInWithGoogle(),
            ),

            const SizedBox(height: 24),

            // Already have account link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'If you already have an account? ',
                    style: AppTextStyles.bodySmall,
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text(
                      'Login now',
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
    );
  }

  // Helper: label text with red asterisk
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(text, style: AppTextStyles.labelMedium),
          if (required)
            const Text(' *',
                style: TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ),
    );
  }

  // Helper: social login button row
  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
