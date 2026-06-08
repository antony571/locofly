// lib/data/repositories/bid_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class BidRepository {
  final SupabaseClient _supabase;
  BidRepository(this._supabase);

  // Place a bid — inserts directly into bids table
  // Advance payment via Razorpay will be wired in later
  Future<BidModel> placeBid({
    required String userId,
    required int flightId,
    required double bidAmount,
    required String charterOption,
    required int expiryHours,
  }) async {
    final expiresAt = DateTime.now().add(Duration(hours: expiryHours));
    final response = await _supabase
        .from(AppConstants.tableBids)
        .insert({
          'user_id': userId,
          'flight_id': flightId,
          'bid_amount': bidAmount,
          'advance_paid': 0,
          'charter_option': charterOption,
          'status': 'pending',
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();
    return BidModel.fromJson(response);
  }

  // Get all bids placed by the current user, newest first
  Future<List<BidModel>> getUserBids(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableBids)
        .select('*, flights(*, aircraft(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BidModel.fromJson(e)).toList();
  }

  Future<BidModel?> getBidById(int bidId) async {
    final response = await _supabase
        .from(AppConstants.tableBids)
        .select('*, flights(*, aircraft(*))')
        .eq('id', bidId)
        .single();
    return BidModel.fromJson(response);
  }

  Future<void> cancelBid(int bidId, String reason) async {
    await _supabase
        .from(AppConstants.tableBids)
        .update({'status': 'cancelled', 'cancel_reason': reason})
        .eq('id', bidId);
  }

  // Add a passenger record linked to a booking
  Future<void> addPassenger({
    required int bookingId,
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? dob,
    String? aadhaar,
    String? passportNumber,
    String? passportUrl,
  }) async {
    await _supabase.from(AppConstants.tablePassengers).insert({
      'booking_id': bookingId,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      if (dob != null) 'dob': dob,
      if (aadhaar != null) 'aadhaar': aadhaar,
      if (passportNumber != null) 'passport_number': passportNumber,
      if (passportUrl != null) 'passport_url': passportUrl,
    });
  }

  // Last 7 days of bid amounts for a flight — used for the price history chart
  Future<List<double>> getPriceHistory(int flightId) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final response = await _supabase
        .from(AppConstants.tableBids)
        .select('bid_amount, created_at')
        .eq('flight_id', flightId)
        .gte('created_at', sevenDaysAgo.toIso8601String())
        .order('created_at', ascending: true);

    if ((response as List).isEmpty) return [];
    return response
        .map<double>((b) => (b['bid_amount'] as num).toDouble())
        .toList();
  }
}
