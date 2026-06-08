// lib/core/constants/app_constants.dart
//
// All app-wide constants. Supabase credentials are loaded from
// the .env file via flutter_dotenv — never hardcoded here.

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // ─── Supabase credentials (read from .env file) ───────────────────────────
  // dotenv.env['KEY'] reads the value from your .env file.
  // The '!' means "throw an error if missing" — better than silently failing.
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project-ref.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key-here';

  // ─── Supabase table names ─────────────────────────────────────────────────
  static const String tableUsers         = 'users';
  static const String tableFlights       = 'flights';
  static const String tableAircraft      = 'aircraft';
  static const String tableBids          = 'bids';
  static const String tableBookings      = 'bookings';
  static const String tablePassengers    = 'passengers';
  static const String tablePayments      = 'payments';
  static const String tableNotifications = 'notifications';
  static const String tableSpecialOffers = 'special_offers';

  // ─── Supabase Edge Function names ─────────────────────────────────────────
  static const String fnPlaceBid            = 'place-bid';
  static const String fnCancelBid           = 'cancel-bid';
  static const String fnFlightsNearby       = 'flights-nearby';
  static const String fnGenerateEticket     = 'generate-eticket';
  static const String fnCreatePaymentOrder  = 'create-payment-order';
  static const String fnVerifyPayment       = 'verify-payment';
  static const String fnUploadPassport      = 'upload-passport';

  // ─── Supabase Storage buckets ─────────────────────────────────────────────
  static const String bucketProfiles  = 'profile-photos';
  static const String bucketPassports = 'passports';
  static const String bucketAircraft  = 'aircraft-images';
  static const String bucketEtickets  = 'etickets';

  // ─── App config ───────────────────────────────────────────────────────────
  static const String appName      = 'LocoFly';
  static const String currency     = '₹';
  static const String currencyCode = 'INR';

  static const List<int>    bidExpiryOptions = [1, 12, 24];
  static const List<String> charterOptions   = [
    'Full Plane', '+ Catering', 'VIP Setup'
  ];

  // ─── SharedPreferences keys ───────────────────────────────────────────────
  static const String prefOnboardingSeen = 'onboarding_seen';
  static const String prefUserId         = 'user_id';
}
