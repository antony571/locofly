// lib/data/repositories/booking_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class BookingRepository {
  final SupabaseClient _supabase;
  BookingRepository(this._supabase);

  // Get all bookings for the current user, newest first
  Future<List<BookingModel>> getUserBookings(String userId) async {
    final response = await _supabase
        .from(AppConstants.tableBookings)
        .select('*, flights(*, aircraft(*))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => BookingModel.fromJson(e)).toList();
  }

  // Get a single booking with full details
  Future<BookingModel?> getBookingById(int id) async {
    final response = await _supabase
        .from(AppConstants.tableBookings)
        .select('*, flights(*, aircraft(*))')
        .eq('id', id)
        .single();
    return BookingModel.fromJson(response);
  }

  // Trigger e-ticket PDF generation via Edge Function
  Future<String?> generateEticket(int bookingId) async {
    try {
      final response = await _supabase.functions.invoke(
        AppConstants.fnGenerateEticket,
        body: {'booking_id': bookingId},
      );
      return response.data['eticket_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}
