// lib/data/repositories/flight_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class FlightRepository {
  final SupabaseClient _supabase;
  FlightRepository(this._supabase);

  // ── Get all available flights, optionally filtered by from/to/date ─────────
  Future<List<FlightModel>> getFlights({
    String? fromCity,
    String? toCity,
    DateTime? date,
  }) async {
    var query = _supabase
        .from(AppConstants.tableFlights)
        .select('*, aircraft(*)')       // join aircraft table in one query
        .eq('status', 'available');

    if (fromCity != null && fromCity.isNotEmpty) {
      query = query.ilike('from_city', '%$fromCity%'); // case-insensitive search
    }
    if (toCity != null && toCity.isNotEmpty) {
      query = query.ilike('to_city', '%$toCity%');
    }
    if (date != null) {
      // Filter flights departing on the selected date
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      query = query
          .gte('departure_time', start.toIso8601String())
          .lt('departure_time', end.toIso8601String());
    }

    final response = await query.order('departure_time', ascending: true);
    return (response as List).map((e) => FlightModel.fromJson(e)).toList();
  }

  // ── Get single flight with aircraft details ───────────────────────────────
  Future<FlightModel?> getFlightById(int id) async {
    final response = await _supabase
        .from(AppConstants.tableFlights)
        .select('*, aircraft(*)')
        .eq('id', id)
        .single();
    return FlightModel.fromJson(response);
  }

  // ── Get flights near user location via Edge Function ─────────────────────
  Future<List<FlightModel>> getNearbyFlights({
    required double lat,
    required double lng,
    double radiusKm = 500,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        AppConstants.fnFlightsNearby,
        body: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
      );
      final data = response.data as List? ?? [];
      return data.map((e) => FlightModel.fromJson(e)).toList();
    } catch (_) {
      // Edge function not deployed yet — fall back to all flights
      return getFlights();
    }
  }

  // ── Get active special offers ─────────────────────────────────────────────
  Future<List<SpecialOfferModel>> getSpecialOffers() async {
    final response = await _supabase
        .from(AppConstants.tableSpecialOffers)
        .select()
        .gte('valid_until', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    return (response as List).map((e) => SpecialOfferModel.fromJson(e)).toList();
  }

  // ── Get top bid amount for a flight (shown on flight cards) ──────────────
  Future<double?> getTopBid(int flightId) async {
    final response = await _supabase
        .from(AppConstants.tableBids)
        .select('bid_amount')
        .eq('flight_id', flightId)
        .eq('status', 'pending')
        .order('bid_amount', ascending: false)
        .limit(1);
    if ((response as List).isEmpty) return null;
    return (response.first['bid_amount'] as num).toDouble();
  }
}
