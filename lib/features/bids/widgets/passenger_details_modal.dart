// lib/features/bids/widgets/passenger_details_modal.dart
//
// Bottom sheet modal shown before submitting a bid.
// Collects: full name, email, phone, DOB, Aadhaar, passport number, passport file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/loco_button.dart';
import '../../auth/controllers/auth_controller.dart';

class PassengerDetailsModal extends ConsumerStatefulWidget {
  final VoidCallback onContinue;

  const PassengerDetailsModal({super.key, required this.onContinue});

  @override
  ConsumerState<PassengerDetailsModal> createState() =>
      _PassengerDetailsModalState();
}

class _PassengerDetailsModalState
    extends ConsumerState<PassengerDetailsModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _passportController = TextEditingController();

  DateTime? _selectedDob;
  String? _passportFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the logged-in user's details
    final user = ref.read(currentUserProfileProvider);
    if (user != null) {
      _fullNameController.text = user.fullName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  Future<void> _pickPassport() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _passportFileName = file.name);
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);
    // Passport upload to Supabase Storage will be wired in Phase 5
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isUploading = false);
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Passenger Details',
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.primary)),
                    Text('Fill in details for all passengers',
                        style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('FULL NAME'),
                    TextFormField(
                      controller: _fullNameController,
                      decoration:
                          const InputDecoration(hintText: 'e.g. Riya Sharma'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _label('EMAIL ADDRESS'),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(hintText: 'riya@example.com'),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter valid email'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _label('PHONE NUMBER'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: '+91 98765 43210'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

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
                                    initialDate: DateTime(1995),
                                    firstDate: DateTime(1940),
                                    lastDate: DateTime.now().subtract(
                                        const Duration(days: 365 * 18)),
                                    builder: (ctx, child) => Theme(
                                      data: Theme.of(ctx).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppColors.primary,
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDob = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    _selectedDob != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_selectedDob!)
                                        : 'DD / MM / YYYY',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _selectedDob != null
                                          ? AppColors.textPrimary
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('AADHAAR NUMBER'),
                              TextFormField(
                                controller: _aadhaarController,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                decoration: const InputDecoration(
                                  hintText: 'AADHAAR Number',
                                  counterText: '',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _label('PASSPORT / ID'),
                    TextFormField(
                      controller: _passportController,
                      decoration:
                          const InputDecoration(hintText: 'ID Number'),
                    ),
                    const SizedBox(height: 14),

                    _label('ATTACH PASSPORT'),
                    GestureDetector(
                      onTap: _pickPassport,
                      child: Container(
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
                            Expanded(
                              child: Text(
                                _passportFileName ?? 'Choose file',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _passportFileName != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _passportFileName == null
                                  ? 'No file chosen'
                                  : '✓',
                              style: AppTextStyles.caption.copyWith(
                                color: _passportFileName != null
                                    ? AppColors.success
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    LCPrimaryButton(
                      label: 'Continue to Bid ↓',
                      isLoading: _isUploading,
                      onPressed: _handleContinue,
                    ),

                    const SizedBox(height: 20),
                  ],
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
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8),
      ),
    );
  }
}
