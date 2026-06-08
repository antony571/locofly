// lib/features/profile/screens/profile_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/loco_button.dart';
import '../../auth/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  File? _newPhoto;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProfileProvider);
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _cityController.text = user.currentCity ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null) setState(() => _newPhoto = File(file.path));
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;

      String? photoUrl;

      // Upload new photo to Supabase Storage if selected
      if (_newPhoto != null) {
        final bytes = await _newPhoto!.readAsBytes();
        final path = '${authUser.id}/profile.jpg';
        await supabase.storage.from(AppConstants.bucketProfiles).uploadBinary(
            path, bytes,
            fileOptions: const FileOptions(upsert: true));
        photoUrl = supabase.storage
            .from(AppConstants.bucketProfiles)
            .getPublicUrl(path);
      }

      // Update user record
      await supabase.from(AppConstants.tableUsers).update({
        'full_name': _nameController.text.trim(),
        'current_city': _cityController.text.trim(),
        if (photoUrl != null) 'profile_photo_url': photoUrl,
      }).eq('auth_id', authUser.id);

      // Refresh the auth provider so updated name shows everywhere
      ref.invalidate(authProvider);

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Profile photo ────────────────────────────────────────────
            GestureDetector(
              onTap: _isEditing ? _pickPhoto : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _newPhoto != null
                        ? FileImage(_newPhoto!) as ImageProvider
                        : (user?.profilePhotoUrl != null
                            ? CachedNetworkImageProvider(user!.profilePhotoUrl!)
                            : null),
                    child: (_newPhoto == null && user?.profilePhotoUrl == null)
                        ? Text(
                            _initials(user?.fullName),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Name + email
            if (!_isEditing) ...[
              Text(
                user?.fullName ?? 'User',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: AppTextStyles.bodySmall),
              if (user?.currentCity != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(user!.currentCity!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 28),

            // ── Edit form ────────────────────────────────────────────────
            if (_isEditing) ...[
              _editField('Full Name', _nameController, Icons.person_outline),
              const SizedBox(height: 14),
              _editField(
                  'Current City', _cityController, Icons.location_on_outlined),
              const SizedBox(height: 24),
              LCPrimaryButton(
                label: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 28),
            ],

            // ── Menu items ───────────────────────────────────────────────
            _menuSection('Account', [
              _menuItem(Icons.confirmation_num_outlined, 'My Bookings',
                  onTap: () => context.go(AppRoutes.bookings)),
              _menuItem(Icons.gavel_outlined, 'My Bids',
                  onTap: () => context.go(AppRoutes.bids)),
              _menuItem(Icons.notifications_outlined, 'Notifications',
                  onTap: () => context.go('/notifications')),
            ]),

            const SizedBox(height: 16),

            _menuSection('Support', [
              _menuItem(Icons.help_outline, 'Help & FAQ', onTap: () {}),
              _menuItem(Icons.privacy_tip_outlined, 'Privacy Policy',
                  onTap: () {}),
              _menuItem(Icons.description_outlined, 'Terms & Conditions',
                  onTap: () {}),
            ]),

            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'LocoFly v1.0.0',
              style: AppTextStyles.caption,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _editField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _menuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title,
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'LF';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
