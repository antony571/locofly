// lib/features/auth/screens/otp_screen.dart
//
// The "Verify Your Identity" screen from the Figma.
// Shows a shield icon, the masked phone number (+91 ••••••4821),
// 6 individual OTP boxes, a resend button, and a Verify CTA.
//
// pin_code_fields package gives us the 6 individual boxes automatically.
// We just pass the phone number via route parameter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone; // passed from the signup/login screen

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otpCode = '';
  bool _isLoading = false;
  int _resendCountdown = 30; // seconds before resend is allowed
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  // Count down from 30 before allowing resend
  void _startResendTimer() {
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    // Tick every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) _canResend = true;
      });
      return _resendCountdown > 0;
    });
  }

  Future<void> _handleVerify() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(authProvider.notifier).verifyOtp(
          phone: widget.phone,
          token: _otpCode,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid code. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    // On success, router redirects to home automatically
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    _startResendTimer();
  }

  // Mask phone: +91 9876543210 → +91 •••••• 3210
  String get _maskedPhone {
    if (widget.phone.length < 4) return widget.phone;
    final last4 = widget.phone.substring(widget.phone.length - 4);
    return '+91 •••••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),

              // ── Shield icon ────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                'Verify Your Identity',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We detected a secure sign-in attempt. Enter the 6-digit verification code sent to your registered mobile number.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Masked phone number pill ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_android, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(_maskedPhone, style: AppTextStyles.labelMedium),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── 6 OTP boxes ────────────────────────────────────────────────
              // PinCodeTextField from pin_code_fields package creates the
              // 6 individual input boxes that auto-advance as you type
              PinCodeTextField(
                appContext: context,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeFillColor: AppColors.surface,
                  selectedFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.inputBackground,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                ),
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() => _otpCode = value);
                },
                onCompleted: (value) {
                  setState(() => _otpCode = value);
                  // Auto-submit when all 6 digits are entered
                  _handleVerify();
                },
              ),

              const SizedBox(height: 16),

              // ── Resend code ────────────────────────────────────────────────
              GestureDetector(
                onTap: _canResend ? _handleResend : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16,
                      color: _canResend ? AppColors.primary : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _canResend
                          ? 'Resend Code'
                          : 'Resend Code in ${_resendCountdown}s',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: _canResend ? AppColors.primary : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Verify button ──────────────────────────────────────────────
              LCPrimaryButton(
                label: 'Verify',
                isLoading: _isLoading,
                onPressed: _handleVerify,
              ),
              const SizedBox(height: 12),
              LCOutlinedButton(
                label: 'Use Biometric',
                leading: const Icon(Icons.face, size: 20),
                onPressed: () {},
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
