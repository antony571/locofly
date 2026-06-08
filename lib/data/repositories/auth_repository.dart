// lib/data/repositories/auth_repository.dart
//
// A "repository" is a class that wraps all the data calls for one feature.
// Instead of writing Supabase calls directly inside UI widgets (messy),
// we put them all here. The UI just calls methods like signUp() or login()
// and doesn't need to know HOW they work internally.
//
// This file handles every auth operation:
//   - Email/password sign up
//   - Email/password login
//   - OTP send + verify
//   - Google OAuth
//   - Apple OAuth
//   - Logout
//   - Fetching the current user's profile from our users table

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  // The Supabase client — our connection to the database and auth system
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // ─── Sign Up with email + password ────────────────────────────────────────
  // Called after the user fills in name, email, password on the signup screen.
  // Supabase creates an auth user AND our trigger creates a row in public.users.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      // data here becomes raw_user_meta_data in Supabase Auth
      // Our trigger reads full_name from here and copies it to public.users
      data: {'full_name': fullName},
    );
  }

  // ─── Login with email + password ──────────────────────────────────────────
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ─── Send OTP to phone number ──────────────────────────────────────────────
  // Supabase sends a 6-digit SMS to the phone number.
  // `phone` should include country code e.g. "+919876543210"
  Future<void> sendOtp(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  // ─── Verify OTP ────────────────────────────────────────────────────────────
  // User enters the 6-digit code from SMS. Supabase checks it and returns
  // a session if correct, throws an error if wrong or expired.
  Future<AuthResponse> verifyOtp({
    required String phone,
    required String token,
  }) async {
    return await _supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // ─── Google OAuth ──────────────────────────────────────────────────────────
  // Opens a browser window for Google sign-in.
  // After the user logs in with Google, they're redirected back to the app.
  Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // redirectTo is where Google sends the user back after login
      // This must match what you set in Supabase Auth settings
      redirectTo: 'io.locofly.app://login-callback',
    );
  }

  // ─── Apple OAuth ───────────────────────────────────────────────────────────
  Future<bool> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.locofly.app://login-callback',
    );
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  // Clears the local session. The router's redirect() will detect no session
  // and send the user back to the login screen automatically.
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ─── Get current user's profile from our users table ──────────────────────
  // Supabase Auth gives us basic info (email, id) but our public.users table
  // has extra fields (full_name, current_city, profile_photo_url).
  // This fetches that extra profile data.
  Future<UserModel?> getCurrentUserProfile() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final response = await _supabase
        .from(AppConstants.tableUsers)
        .select()
        .eq('auth_id', authUser.id)   // match by Supabase Auth user id
        .single();                     // expect exactly one row

    return UserModel.fromJson(response);
  }

  // ─── Update user's city (used on home screen for nearby flights) ───────────
  Future<void> updateCurrentCity(String city) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    await _supabase
        .from(AppConstants.tableUsers)
        .update({'current_city': city})
        .eq('auth_id', authUser.id);
  }

  // ─── Check if user is currently logged in ─────────────────────────────────
  bool get isLoggedIn => _supabase.auth.currentSession != null;

  // ─── Stream of auth state changes ─────────────────────────────────────────
  // This stream fires whenever the user logs in or out.
  // The router listens to this to redirect accordingly.
  Stream<AuthState> get authStateStream =>
      _supabase.auth.onAuthStateChange;
}
