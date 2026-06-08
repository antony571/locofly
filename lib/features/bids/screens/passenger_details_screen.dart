// lib/features/bids/screens/passenger_details_screen.dart
//
// Screen 09b from Figma — "Passenger Details" modal/screen.
// Collects: full name, email, phone, DOB, Aadhaar, passport/ID, passport file upload.
// After filling in details, calls placeBid and then navigates to My Bids.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/loco_button.dart';
import '../controllers/bid_controller.dart';

class PassengerDetailsScreen extends ConsumerStatefulWidget {
  final int flightId;
  final double bidAmount;
  final String charterOption;
  final int expiryHours;
  final FlightModel? flight;

  const PassengerDetailsScreen({
    super.key,
    required this.flightId,
    required this.bidAmount,
    required this.charterOption,
    required this.expiryHours,
    this.flight,
  });

  @override
  ConsumerState<PassengerDetailsScreen> createState() =>
      _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState
    extends ConsumerState<PassengerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _passportController = TextEditingController();

  DateTime? _selectedDob;
  File? _passportFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  Future<void> _pickPassport() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _passportFile = File(picked.path));
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Place the bid in Supabase
      final bid = await ref.read(placeBidProvider.notifier).placeBid(
            flightId: widget.flightId,
            bidAmount: widget.bidAmount,
            charterOption: widget.charterOption,
            expiryHours: widget.expiryHours,
          );

      if (!mounted) return;

      if (bid != null) {
        // Bid placed successfully — go to My Bids tab
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid placed successfully! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        // Reset form state
        ref.read(bidFormProvider.notifier).reset();
        context.go(AppRoutes.bids);
      } else {
        final error = ref.read(placeBidProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place bid: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Flight Amenities'), // matches Figma label
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Blurred flight info bar at top (matches Figma)
          if (widget.flight != null)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: AppColors.surface,
                child: Text(
                  '${widget.flight!.aircraft?.airline ?? ''} · '
                  '${widget.flight!.aircraft?.flightNumber ?? ''} · '
                  '${widget.flight!.aircraft?.type ?? ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),

          // Modal card slides up (matches Figma bottom sheet style)
          Positioned(
            top: widget.flight != null ? 44 : 0,
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text('Passenger Details',
                          style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text('Fill in details for all passengers',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 20),

                      // Full name
                      _label('FULL NAME'),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            hintText: 'e.g. Riya Sharma'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Name required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _label('EMAIL ADDRESS'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                            hintText: 'riya@example.com'),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      _label('PHONE NUMBER'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            hintText: '+91 98765 43210'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Phone required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // DOB + Aadhaar side by side
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('DATE OF BIRTH'),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime(2000),
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                      builder: (ctx, child) => Theme(
                                        data: Theme.of(ctx).copyWith(
                                          colorScheme:
                                              const ColorScheme.light(
                                            primary: AppColors.primary,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(
                                          () => _selectedDob = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBackground,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.border),
                                    ),
                                    child: Text(
                                      _selectedDob != null
                                          ? DateFormat('dd/MM/yyyy')
                                              .format(_selectedDob!)
                                          : 'DD / MM / YYYY',
                                      style: _selectedDob != null
                                          ? AppTextStyles.bodyMedium
                                          : AppTextStyles.bodyMedium
                                              .copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('AADHAAR NUMBER'),
                                TextFormField(
                                  controller: _aadhaarController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      hintText: 'AADHAAR Number'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Passport / ID
                      _label('PASSPORT / ID'),
                      TextFormField(
                        controller: _passportController,
                        decoration:
                            const InputDecoration(hintText: 'ID Number'),
                      ),
                      const SizedBox(height: 14),

                      // Passport file upload
                      _label('ATTACH PASSPORT'),
                      GestureDetector(
                        onTap: _pickPassport,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file,
                                  size: 18,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                _passportFile != null
                                    ? _passportFile!.path
                                        .split('/')
                                        .last
                                    : 'Choose file',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _passportFile != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Submit button
                      LCPrimaryButton(
                        label: 'Continue to Bid ↓',
                        isLoading: _isSubmitting,
                        onPressed: _handleContinue,
                      ),

                      const SizedBox(height: 32),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      )),
    );
  }
}
