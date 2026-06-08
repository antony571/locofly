// lib/data/supabase/supabase_client.dart
//
// This file sets up the Supabase connection and exposes a Riverpod provider
// for the Supabase client that any part of the app can use.
//
// Supabase is like a backend-as-a-service. Instead of writing a server,
// you talk directly to Supabase from the app. It handles:
//   - Database queries (via REST API auto-generated from your tables)
//   - Authentication (login, signup, sessions)
//   - Storage (file uploads like passport photos)
//   - Edge Functions (custom server logic like placing a bid)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

// ─── Initialize Supabase ──────────────────────────────────────────────────────
// Call this once in main() before the app starts.
// It sets up the HTTP client, auth session listener, and local storage.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    // authOptions controls where the auth session token is stored locally
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // More secure auth flow
    ),
  );
}

// ─── Supabase client provider ─────────────────────────────────────────────────
// `Supabase.instance.client` is the global Supabase client.
// We wrap it in a Riverpod provider so we can easily mock it in tests.
//
// Usage in any widget or provider:
//   final supabase = ref.read(supabaseClientProvider);
//   final data = await supabase.from('flights').select();
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ─── Auth state provider ──────────────────────────────────────────────────────
// This streams the current auth state — logged in, logged out, loading.
// Widgets can listen to this to react when the user logs in or out.
//
// AuthState has two fields:
//   .event  → AuthChangeEvent (signedIn, signedOut, tokenRefreshed etc.)
//   .session → The current session (or null if logged out)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseClientProvider).auth.onAuthStateChange;
});

// ─── Current user provider ────────────────────────────────────────────────────
// A convenient shortcut to get the currently logged-in user.
// Returns null if no one is logged in.
//
// Usage:
//   final user = ref.watch(currentUserProvider);
//   if (user == null) { /* not logged in */ }
final currentUserProvider = Provider<User?>((ref) {
  return ref.read(supabaseClientProvider).auth.currentUser;
});
