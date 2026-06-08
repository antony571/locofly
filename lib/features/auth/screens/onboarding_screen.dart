// lib/features/auth/screens/onboarding_screen.dart
//
// The first screen users see. Yellow background, airplane, tagline, "Next" button.
// When they tap Next, we save a flag locally so they never see this again,
// then navigate to the login/signup screen.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Save flag so we skip onboarding on next launch
  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingSeen, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The whole screen is amber/yellow
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Top logo ───────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.flight, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'LOCO',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              // ── Airplane illustration area ─────────────────────────────────
              // In a real project you'd use an SVG or PNG asset here.
              // For now we use a styled Icon — replace with Image.asset() later.
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // White diagonal swoosh behind the plane
                      Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 280,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      // Plane icon — replace with your actual asset later
                      const Icon(
                        Icons.airplanemode_active,
                        size: 120,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),

              // ── "Private Aviation" badge ───────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Private Aviation',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Main headline ──────────────────────────────────────────────
              // The Figma shows "Fly" on one line, "in Luxury, Enjoy" italic,
              // "premium amenities" on third line
              RichText(
                text: TextSpan(
                  style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
                  children: const [
                    TextSpan(text: 'Fly\n'),
                    TextSpan(
                      text: 'in Luxury, Enjoy\n',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TextSpan(text: 'premium amenities'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Subtitle ───────────────────────────────────────────────────
              Text(
                'Empty return-leg flights, exclusively opened to you. '
                'Bid on a whole aircraft for the price of a seat.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),

              const SizedBox(height: 40),

              // ── Next button ────────────────────────────────────────────────
              // White outlined button to match the Figma
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () async {
                    await _markOnboardingSeen();
                    if (context.mounted) {
                      // Go to login screen
                      context.go(AppRoutes.login);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
