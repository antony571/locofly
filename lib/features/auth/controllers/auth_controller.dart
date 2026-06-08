// lib/features/auth/controllers/auth_controller.dart
//
// The controller sits between the UI and the repository.
// UI calls controller methods → controller calls repository → repository talks to Supabase.
//
// We use Riverpod's AsyncNotifier which handles loading/error/success states
// automatically. Instead of manually writing:
//   bool isLoading = false;
//   String? error;
// We get all that for free with AsyncValue<T>.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../../data/models/models.dart';

// ─── Repository provider ──────────────────────────────────────────────────────
// Makes AuthRepository available throughout the app via ref.read/watch
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(supabaseClientProvider));
});

// ─── Auth state notifier ──────────────────────────────────────────────────────
// Manages the current UserModel (or null if logged out).
// AsyncNotifier<UserModel?> means the state can be:
//   - AsyncLoading  → while checking auth on startup
//   - AsyncData(user) → logged in with user profile
//   - AsyncData(null) → logged out
//   - AsyncError    → something went wrong
class AuthNotifier extends AsyncNotifier<UserModel?> {
  // Called once when the provider is first used
  @override
  Future<UserModel?> build() async {
    // Try to load the current user's profile from Supabase
    // If no one is logged in, this returns null
    return await ref.read(authRepositoryProvider).getCurrentUserProfile();
  }

  // ─── Sign Up ───────────────────────────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // Set state to loading — UI will show a spinner
    state = const AsyncLoading();

    // guard() wraps the call in try/catch and sets AsyncError on failure
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );
      // After sign up, fetch the newly created profile
      return await ref.read(authRepositoryProvider).getCurrentUserProfile();
    });
  }

  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).loginWithEmail(
        email: email,
        password: password,
      );
      return await ref.read(authRepositoryProvider).getCurrentUserProfile();
    });
  }

  // ─── Send OTP ──────────────────────────────────────────────────────────────
  Future<void> sendOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      return state.value; // keep existing user value, just trigger loading state
    });
  }

  // ─── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> verifyOtp({
    required String phone,
    required String token,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).verifyOtp(
        phone: phone,
        token: token,
      );
      return await ref.read(authRepositoryProvider).getCurrentUserProfile();
    });
  }

  // ─── Google Sign In ────────────────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      return await ref.read(authRepositoryProvider).getCurrentUserProfile();
    });
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    // Set state to null — router detects this and redirects to login
    state = const AsyncData(null);
  }
}

// ─── The provider — how the rest of the app accesses auth state ───────────────
// Usage in any widget:
//   final authState = ref.watch(authProvider);
//   authState.when(
//     loading: () => CircularProgressIndicator(),
//     error: (e, _) => Text('Error: $e'),
//     data: (user) => user != null ? HomeScreen() : LoginScreen(),
//   )
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

// ─── Convenience provider — just the current user (nullable) ─────────────────
// Use this when you just need the user object without loading/error handling
final currentUserProfileProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value;
});
